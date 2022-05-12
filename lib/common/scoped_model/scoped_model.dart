library scoped_model;

import 'dart:async';

import 'package:flutter/material.dart';

/// A base class that holds some data and allows other classes to listen to
/// changes to that data.
///
/// In order to notify listeners that the data has changed, you must explicitly
/// call the [notifyListeners] method.
///
/// Generally used in conjunction with a [ScopedModel] Widget, but if you do not
/// need to pass the Widget down the tree, you can use a simple
/// [AnimatedBuilder] to listen for changes and rebuild when the model notifies
/// the listeners.
///
/// ### Example
///
/// ```
/// class CounterModel extends Model {
///   int _counter = 0;
///
///   int get counter => _counter;
///
///   void increment() {
///     // First, increment the counter
///     _counter++;
///
///     // Then notify all the listeners.
///     notifyListeners();
///   }
/// }
/// ```
abstract class Model extends Listenable {
  final Set<VoidCallback> _listeners = Set<VoidCallback>();
  int _version = 0;
  int _microtaskVersion = 0;

  /// [listener] will be invoked when the model changes.
  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// [listener] will no longer be invoked when the model changes.
  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Returns the number of listeners listening to this model.
  int get listenerCount => _listeners.length;

  /// Should be called only by [Model] when the model has changed.
  @protected
  void notifyListeners() {
    // We schedule a microtask to debounce multiple changes that can occur
    // all at once.
    if (_microtaskVersion == _version) {
      _microtaskVersion++;
      scheduleMicrotask(() {
        _version++;
        _microtaskVersion = _version;

        // Convert the Set to a List before executing each listener. This
        // prevents errors that can arise if a listener removes itself during
        // invocation!
        _listeners.toList().forEach((VoidCallback listener) => listener());
      });
    }
  }
}

/// Finds a [Model]. Deprecated: Use [ScopedModel.of] instead.
@deprecated
class ModelFinder<T extends Model> {
  /// Returns the [Model] of type [T] of the closest ancestor [ScopedModel].
  ///
  /// [Widget]s who call [of] with a [rebuildOnChange] of true will be rebuilt
  /// whenever there's a change to the returned model.
  T? of(BuildContext context, {bool rebuildOnChange = false}) {
    return ScopedModel.of<T>(context, rebuildOnChange: rebuildOnChange);
  }
}

/// Provides a [Model] to all descendants of this Widget.
///
/// Descendant Widgets can access the model by using the
/// [ScopedModelDescendant] Widget, which rebuilds each time the model changes,
/// or directly via the [ScopedModel.of] static method.
///
/// To provide a Model to all screens, place the [ScopedModel] Widget above the
/// [WidgetsApp] or [MaterialApp] in the Widget tree.
///
/// ### Example
///
/// ```
/// ScopedModel<CounterModel>(
///   model: CounterModel(),
///   child: ScopedModelDescendant<CounterModel>(
///     builder: (context, child, model) => Text(model.counter.toString()),
///   ),
/// );
/// ```
class ScopedModel<T extends Model> extends StatelessWidget {
  /// The [Model] to provide to [child] and its descendants.
  final T? model;

  /// The [Widget] the [model] will be available to.
  final Widget? child;

  ScopedModel({@required this.model, @required this.child})
      : assert(model != null),
        assert(child != null);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: model!,
      builder: (context, _) => _InheritedModel<T>(model: model!, child: child!),
    );
  }

  /// Finds a [Model] provided by a [ScopedModel] Widget.
  ///
  /// Generally, you'll use a [ScopedModelDescendant] to access a model in the
  /// Widget tree and rebuild when the model changes. However, if you would to
  /// access the model directly, you can use this function instead!
  ///
  /// ### Example
  ///
  /// ```
  /// final model = ScopedModel.of<CounterModel>();
  /// ```
  ///
  /// If you find yourself accessing your Model multiple times in this way, you
  /// could also consider adding a convenience method to your own Models.
  ///
  /// ### Model Example
  ///
  /// ```
  /// class CounterModel extends Model {
  ///   static CounterModel of(BuildContext context) =>
  ///       ScopedModel.of<CounterModel>(context);
  /// }
  ///
  /// // Usage
  /// final model = CounterModel.of(context);
  /// ```
  ///
  /// ## Listening to multiple Models
  ///
  /// If you want a single Widget to rely on multiple models, you can use the
  /// `of` method! No need to manage subscriptions, Flutter takes care of all
  ///  of that through the magic of InheritedWidgets.
  ///
  /// ```
  /// class CombinedWidget extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final username =
  ///       ScopedModel.of<UserModel>(context, rebuildOnChange: true).username;
  ///     final counter =
  ///       ScopedModel.of<CounterModel>(context, rebuildOnChange: true).counter;
  ///
  ///     return Text('$username tapped the button $counter times');
  ///   }
  /// }
  /// ```
  static T? of<T extends Model>(
    BuildContext context, {
    bool rebuildOnChange = false,
  }) {
    InheritedWidget? widget = rebuildOnChange
        ? context.dependOnInheritedWidgetOfExactType<_InheritedModel<T>>()
        : context.getElementForInheritedWidgetOfExactType<_InheritedModel<T>>()
            ?.widget as InheritedWidget;

    if (widget == null) {
      throw ScopedModelError();
    } else {
      return (widget as _InheritedModel<T>).model;
    }
  }
}

/// Provides [model] to its [child] [Widget] tree via [InheritedWidget].  When
/// [version] changes, all descendants who request (via
/// [BuildContext.dependOnInheritedWidgetOfExactType]) to be rebuilt when the model
/// changes will do so.
class _InheritedModel<T extends Model> extends InheritedWidget {
  final T? model;
  final int? version;

  _InheritedModel({Key? super.key, Widget? child, T? model})
      : this.model = model,
        this.version = model?._version,
        super(child: child!);

  @override
  bool updateShouldNotify(_InheritedModel<T> oldWidget) =>
      (oldWidget.version != version);
}

/// Builds a child for a [ScopedModelDescendant].
typedef Widget ScopedModelDescendantBuilder<T extends Model>(
  BuildContext context,
  Widget? child,
  T? model,
);

/// Finds a specific [Model] provided by a [ScopedModel] Widget and rebuilds
/// whenever the [Model] changes.
///
/// Provides an option to disable rebuilding when the [Model] changes.
///
/// Provide a constant [child] Widget if some portion inside the builder does
/// not rely on the [Model] and should not be rebuilt.
///
/// ### Example
///
/// ```
/// ScopedModel<CounterModel>(
///   model: CounterModel(),
///   child: ScopedModelDescendant<CounterModel>(
///     child: Text('Button has been pressed:'),
///     builder: (context, child, model) {
///       return Column(
///         children: [
///           child,
///           Text('${model.counter}'),
///         ],
///       );
///     }
///   ),
/// );
/// ```
class ScopedModelDescendant<T extends Model> extends StatelessWidget {
  /// Builds a Widget when the Widget is first created and whenever
  /// the [Model] changes if [rebuildOnChange] is set to `true`.
  final ScopedModelDescendantBuilder<T>? builder;

  /// An optional constant child that does not depend on the model.  This will
  /// be passed as the child of [builder].
  final Widget? child;

  /// An optional value that determines whether the Widget will rebuild when
  /// the model changes.
  final bool rebuildOnChange;

  /// Creates the ScopedModelDescendant
  ScopedModelDescendant({
    @required this.builder,
    this.child,
    this.rebuildOnChange = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget? widget = Container();
    if (builder != null) {
       widget = builder?.call(
        context,
        child,
        ScopedModel.of<T>(context, rebuildOnChange: rebuildOnChange),
      );
    }
    return widget!;
  }
}

/// The error that will be thrown if the ScopedModel cannot be found in the
/// Widget tree.
class ScopedModelError extends Error {
  ScopedModelError();

  String toString() {
    return '''Error: Could not find the correct ScopedModel.
    
To fix, please:
          
  * Provide types to ScopedModel<MyModel>
  * Provide types to ScopedModelDescendant<MyModel> 
  * Provide types to ScopedModel.of<MyModel>() 
  * Always use package imports. Ex: `import 'package:my_app/my_model.dart';
  
If none of these solutions work, please file a bug at:
https://github.com/brianegan/scoped_model/issues/new
      ''';
  }
}
