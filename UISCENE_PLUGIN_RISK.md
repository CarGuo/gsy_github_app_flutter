# UIScene Plugin Risk Checklist

- Project: `gsy_github_app_flutter`
- Generated on: 2026-02-13
- Scope: iOS plugins listed in `.flutter-plugins-dependencies`
- Method: static source scan for Scene lifecycle compatibility signals (`FlutterSceneLifeCycleDelegate`, `addSceneDelegate`, usage of `UIApplication.keyWindow` / `windows`, and AppDelegate lifecycle hooks).

## High Risk

### 1. `url_launcher_ios 6.3.6`
- Risk level: High
- Why:
  - Uses deprecated window lookup via `UIApplication.shared.keyWindow`, which is scene-unaware.
- Evidence:
  - `/Users/guoshuyu/.pub-cache/hosted/pub.dev/url_launcher_ios-6.3.6/ios/url_launcher_ios/Sources/url_launcher_ios/URLLauncherPlugin.swift:22`
- Impact:
  - In multi-scene/iPad multi-window mode, in-app Safari presentation may target the wrong scene or fail to present.

### 2. `flutter_inappwebview_ios 1.1.2`
- Risk level: High
- Why:
  - Multiple code paths still use `keyWindow` / `UIApplication.shared.windows`, which can be incorrect under multi-scene.
- Evidence:
  - `/Users/guoshuyu/.pub-cache/hosted/pub.dev/flutter_inappwebview_ios-1.1.2/ios/Classes/HeadlessInAppWebView/HeadlessInAppWebView.swift:40`
  - `/Users/guoshuyu/.pub-cache/hosted/pub.dev/flutter_inappwebview_ios-1.1.2/ios/Classes/UIApplication/VisibleViewController.swift:13`
  - `/Users/guoshuyu/.pub-cache/hosted/pub.dev/flutter_inappwebview_ios-1.1.2/ios/Classes/WebAuthenticationSession/WebAuthenticationSession.swift:93`
- Impact:
  - Headless WebView attach point, visible view-controller resolution, and web-auth presentation anchor may bind to the wrong window/scene.

## Medium Risk

### 1. `fluttertoast 8.2.10`
- Risk level: Medium
- Why:
  - Chooses UI window via `UIApplication.sharedApplication.windows` and key-window iteration.
- Evidence:
  - `/Users/guoshuyu/.pub-cache/hosted/pub.dev/fluttertoast-8.2.10/ios/Classes/FluttertoastPlugin.m:130`
- Impact:
  - Toast may appear on a non-active scene window or behave inconsistently in multi-window mode.

## Low Risk

### 1. `share_plus 12.0.1`
- Risk level: Low
- Why:
  - Uses `connectedScenes` and `UIWindowScene.windows` for root view-controller selection on iOS 13+.
- Evidence:
  - `/Users/guoshuyu/.pub-cache/hosted/pub.dev/share_plus-12.0.1/ios/share_plus/Sources/share_plus/FPPSharePlusPlugin.m:12`
- Note:
  - Keeps a fallback to `keyWindow` for iOS 12 and below (acceptable for non-scene OS versions).

### 2. Other installed iOS plugins in this repo
- `connectivity_plus 6.0.5`
- `device_info_plus 10.1.2`
- `package_info_plus 8.0.2`
- `path_provider_foundation 2.5.1`
- `permission_handler_apple 9.4.7`
- `rive_common 0.4.11`
- `shared_preferences_foundation 2.5.6`
- `sqflite 2.3.3+1`
- `webview_flutter_wkwebview 3.23.5`

Risk level: Low (for UIScene lifecycle migration)
- Why:
  - No direct AppDelegate lifecycle hook usage (`addApplicationDelegate` / `openURL` callbacks / `continueUserActivity`) detected in plugin runtime source paths.

## Recommended Actions

1. Upgrade first:
- `url_launcher_ios`
- `flutter_inappwebview_ios`
- `fluttertoast`

2. Run targeted iPad multi-window validation:
- `url_launcher` in-app Safari presentation
- InAppWebView / headless webview attach
- Web auth session presentation anchor
- Toast display target window
- Share sheet presentation

3. If upgrade is blocked:
- Apply local patch to resolve active `UIWindowScene` and active window/VC instead of `keyWindow`/global `windows`.
