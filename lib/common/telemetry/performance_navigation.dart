import 'package:flutter/widgets.dart';

/// Accepted visible navigation context. Route arguments never enter telemetry.
///
/// 2026-10-23: root-only observation misses the shell's detail Navigator, while
/// forwarding both observers directly lets hidden detail callbacks overwrite a
/// fullscreen route. Keep each accepted context and publish the visible owner.
class GsyPerformanceNavigation {
  new({required this.onScene});

  final ValueChanged<String> onScene;
  String _root = 'unknown';
  String? _detail;
  NavigatorObserver? _detailOwner;
  int _homeTab = 0;

  static const homeTabs = ['home/dynamic', 'home/trend', 'home/my'];
  static const routeScenes = {
    '/',
    'login',
    'home',
    'PhotoViewPage',
    'person',
    'repos',
    'honor-list',
    'release',
    'issue',
    'discussion',
    'common-list',
    'notify',
    'trend-user',
    'search',
    'push',
    'pr-files',
    'code-detail',
    'user-profile-info',
    'web',
    'oauth',
    'debug',
    'unknown',
  };
  static const scenes = [...routeScenes, ...homeTabs];

  /// Map the existing central route vocabulary to finite business categories.
  /// Dynamic usernames/repository names/paths are discarded, never registered.
  static String sceneForRoute(String? name) {
    if (name == '/') return '/';
    final category = name?.split('/').first;
    return routeScenes.contains(category) ? category! : 'unknown';
  }

  /// Activation can finish after Navigator callbacks have already been accepted.
  void synchronize() => _publish();

  NavigatorObserver createRootObserver() => _SceneObserver((route) {
    _root = sceneForRoute(route?.settings.name);
    _publish();
  });

  NavigatorObserver createDetailObserver({
    required bool Function(Route<dynamic> route) isPlaceholder,
  }) {
    late final NavigatorObserver observer;
    observer = _SceneObserver((route) {
      _detailOwner = observer;
      // 2026-10-23: placeholder is a shell-owned identity, not a stack position.
      // A visible business page can become first after removal/replacement.
      _detail = route == null || isPlaceholder(route)
          ? null
          : sceneForRoute(route.settings.name);
      if (_root == 'home') _publish();
    });
    return observer;
  }

  /// A layout change can remove the Navigator without a route pop callback.
  void detailDetached(NavigatorObserver owner) {
    if (!identical(_detailOwner, owner)) return;
    _detailOwner = null;
    _detail = null;
    if (_root == 'home') _publish();
  }

  void selectHomeTab(int index) {
    RangeError.checkValidIndex(index, homeTabs, 'index');
    // 2026-10-23: inherited/layout changes can repeat the current tab. They are
    // not navigation boundaries; root observation and synchronize own startup.
    if (_homeTab == index) return;
    _homeTab = index;
    if (_root == 'home') _publish();
  }

  void resetHome() {
    _homeTab = 0;
    _detailOwner = null;
    _detail = null;
    if (_root == 'home') _publish();
  }

  void _publish() =>
      onScene(_root == 'home' ? _detail ?? homeTabs[_homeTab] : _root);
}

class _SceneObserver extends NavigatorObserver {
  new(this._onPage);

  final ValueChanged<Route<dynamic>?> _onPage;
  final _routes = <Route<dynamic>>[];
  Route<dynamic>? _publishedPage;
  bool _hasPublished = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _publishPage();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _publishPage();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _publishPage();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute == null) return;
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
  void didChangeTop(
    Route<dynamic> topRoute,
    Route<dynamic>? previousTopRoute,
  ) => _publishPage();

  void _publishPage() {
    Route<dynamic>? page;
    for (final route in _routes.reversed) {
      if (route is! PopupRoute<dynamic>) {
        page = route;
        break;
      }
    }
    // 2026-10-23: overlays inherit the underlying page. Track every Navigator
    // mutation because replace/remove below a popup never changes the top route.
    // Identity preserves real same-category navigation; changing a page's stack
    // position alone never changes its scene or creates a navigation boundary.
    if (_hasPublished && identical(page, _publishedPage)) {
      return;
    }
    _hasPublished = true;
    _publishedPage = page;
    _onPage(page);
  }
}
