import 'package:flutter/widgets.dart';

/// A compact navigation context, never a route, URL, arguments, or widget tree.
class SceneSnapshot {
  const SceneSnapshot(this.scene, this.revision);
  final String scene;
  final int revision;
}

/// Observes page navigation on one Navigator. Register allowed names centrally.
///
/// This reports navigation context, not visual ownership or transition completion.
/// PopupRoute overlays inherit the nearest underlying non-popup route's scene.
/// Anonymous pages remain unknown; named popups do not create page boundaries.
/// Install separate observers for separate Navigators when appropriate; the
/// optional go_router adapter is preferable for router-managed nested branches.
class PerformanceNavigatorObserver extends NavigatorObserver {
  PerformanceNavigatorObserver({required void Function(String) onScene})
    : _onScene = onScene;

  void Function(String)? _onScene;
  final _routes = <Route<dynamic>>[];
  Route<dynamic>? _publishedRoute;
  bool _hasPublished = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_onScene == null) return;
    _routes.add(route);
    _publishPage();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_onScene == null) return;
    _routes.remove(route);
    _publishPage();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_onScene == null) return;
    _routes.remove(route);
    _publishPage();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_onScene == null || oldRoute == null) return;
    final index = _routes.indexOf(oldRoute);
    if (index < 0) return;
    if (newRoute == null) {
      _routes.removeAt(index);
    } else {
      _routes[index] = newRoute;
    }
    _publishPage();
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    _publishPage();
  }

  void _publishPage() {
    if (_onScene == null) return;
    Route<dynamic>? page;
    for (final route in _routes.reversed) {
      if (route is! PopupRoute<dynamic>) {
        page = route;
        break;
      }
    }
    // 2026-10-23: dialogs change Navigator's top route but not its page scene.
    // Route identity still publishes equal/unknown labels for real page changes.
    if (_hasPublished && identical(page, _publishedRoute)) return;
    _hasPublished = true;
    _publishedRoute = page;
    _onScene!(page?.settings.name ?? 'unknown');
  }

  /// Makes an observer already installed in a Navigator inert.
  void dispose() {
    _onScene = null;
    _routes.clear();
    _publishedRoute = null;
  }
}
