import 'dart:async';

import 'epic_store.dart';

/// A function that transforms one stream of actions into another
/// stream of actions.
///
/// Actions in, actions out.
///
/// The best part: Epics are based on Dart Streams. This makes routine tasks
/// easy, and complex tasks such as asynchronous error handling, cancellation,
/// and debouncing a breeze. Once you're inside your Epic, use any stream
/// patterns you desire as long as anything output from the final, returned
/// stream, is an action. The actions you emit will be immediately dispatched
/// through the rest of the middleware chain.
///
/// Epics run alongside the normal Redux dispatch channel, meaning you cannot
/// accidentally "swallow" an incoming action. Actions always run through the
/// rest of your middleware chain to your reducers before your Epics even
/// receive the next action.
///
/// Note: Since the Actions you emit from your Epics are dispatched to your
/// store, writing an Epic that simply returns the original actions Stream will
/// result in an infinite loop. Do not do this!
///
/// ## Example
///
/// Let's say your app has a search box. When a user submits a search term,
/// you dispatch a `PerformSearchAction` which contains the term. In order to
/// actually listen for the `PerformSearchAction` and make a network request
/// for the results, we can create an Epic!
///
/// In this instance, our Epic will need to filter all incoming actions it
/// receives to only the `Action` it is interested in: the `PerformSearchAction`.
/// Then, we need to make a network request using the provided search term.
/// Finally, we need to transform those results into an action that contains
/// the search results. If an error has occurred, we'll want to return an
/// error action so our app can respond accordingly.
///
/// ### Code
///
///     Stream<dynamic> exampleEpic(
///       Stream<dynamic> actions,
///       EpicStore<State> store,
///     ) {
///       return actions
///         .where((action) => action is PerformSearchAction)
///         .asyncMap((action) =>
///           // Pseudo api that returns a Future of SearchResults
///           api.search((action as PerformSearch).searchTerm)
///             .then((results) => new SearchResultsAction(results))
///             .catchError((error) => new SearchErrorAction(error)));
///     }
typedef Epic<State> = Stream<dynamic> Function(
  Stream<dynamic> actions,
  EpicStore<State> store,
);

/// A class that acts as an [Epic], transforming one stream of actions into
/// another stream of actions. Generally, [Epic] functions are simpler, but
/// you may have advanced use cases that require a type-safe class.
///
/// ### Example
///
///     class ExampleEpic extends EpicClass<State> {
///       @override
///       Stream<dynamic> call(Stream<dynamic> actions, EpicStore<State> store) {
///         return actions
///           .where((action) => action is PerformSearchAction)
///           .asyncMap((action) =>
///             // Pseudo api that returns a Future of SearchResults
///             api.search((action as PerformSearch).searchTerm)
///               .then((results) => new SearchResultsAction(results))
///               .catchError((error) => new SearchErrorAction(error)));
///       }
///     }
abstract class EpicClass<State> {
  Stream<dynamic> call(
    Stream<dynamic> actions,
    EpicStore<State> store,
  );
}

/// An wrapper that allows you to create Epics which handle actions of a
/// specific type, rather than all actions.
///
/// ### Example
///
///     Stream<dynamic> searchEpic(
///       // Note: this epic only works with PerformSearchActions
///       Stream<PerformSearchAction> actions,
///       EpicStore<State> store,
///     ) {
///       return actions
///         .asyncMap((action) =>
///           api.search(action.searchTerm)
///             .then((results) => new SearchResultsAction(results))
///             .catchError((error) => new SearchErrorAction(error)));
///     }
///
///     final epic = new TypedEpic<State, PerformSearchAction>(typedSearchEpic);
///
/// ### Combining Typed Epics
///
///     final epic = combineEpics([
///       new TypedEpic<State, SearchAction>(searchEpic),
///       new TypedEpic<State, ProfileAction>(profileEpic),
///       new TypedEpic<State, ChatAction>(chatEpic),
///     ]);
class TypedEpic<State, Action> extends EpicClass<State> {
  final Stream<dynamic> Function(
    Stream<Action> actions,
    EpicStore<State> store,
  ) epic;

  TypedEpic(this.epic);

  @override
  Stream<dynamic> call(Stream<dynamic> actions, EpicStore<State> store) {
    return epic(
      actions.transform(StreamTransformer<dynamic, Action>.fromHandlers(
        handleData: (dynamic action, EventSink<Action> sink) {
          if (action is Action) {
            sink.add(action);
          }
        },
      )),
      store,
    );
  }
}
