import 'dart:async';

import 'package:redux/redux.dart';
import 'package:rxdart/transformers.dart';

import 'epic.dart';
import 'epic_store.dart';

/// A [Redux](https://pub.dartlang.org/packages/redux) middleware that passes
/// a stream of dispatched actions to the given [Epic].
///
/// It is recommended that you put your `EpicMiddleware` first when constructing
/// the list of middleware for your store so any actions dispatched from
/// your [Epic] will be intercepted by the remaining Middleware.
///
/// Example:
///
///     var epicMiddleware = new EpicMiddleware(new ExampleEpic());
///     var store = new Store<List<Action>, Action>(reducer,
///       initialState: [], middleware: [epicMiddleware]);
class EpicMiddleware<State> extends MiddlewareClass<State> {
  final StreamController<dynamic> _actions =
      StreamController<dynamic>.broadcast();
  final StreamController<Epic<State>> _epics =
      StreamController.broadcast(sync: true);

  final bool supportAsyncGenerators;
  Epic<State> _epic;
  bool _isSubscribed = false;

  EpicMiddleware(Epic<State> epic, {this.supportAsyncGenerators = true})
      : _epic = epic;

  @override
  void call(Store<State> store, dynamic action, NextDispatcher next) {
    if (!_isSubscribed) {
      _epics.stream
          .switchMap<dynamic>((epic) => epic(_actions.stream, EpicStore(store)))
          .listen(store.dispatch);

      _epics.add(_epic);

      _isSubscribed = true;
    }

    next(action);

    if (supportAsyncGenerators) {
      // Future.delayed is an ugly hack to support async* functions.
      //
      // See: https://github.com/dart-lang/sdk/issues/33818
      Future.delayed(Duration.zero, () {
        _actions.add(action);
      });
    } else {
      _actions.add(action);
    }
  }

  /// Gets or replaces the epic currently used by the middleware.
  ///
  /// Replacing epics is considered an advanced API. You might need this if your
  /// app grows large and want to instantiate Epics on the fly, rather than
  /// as a whole up front.
  Epic<State> get epic => _epic;

  set epic(Epic<State> newEpic) {
    _epic = newEpic;

    _epics.add(newEpic);
  }
}
