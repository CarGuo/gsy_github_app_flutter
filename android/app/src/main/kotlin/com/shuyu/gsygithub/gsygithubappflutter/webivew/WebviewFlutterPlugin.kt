package com.shuyu.gsygithub.gsygithubappflutter.webivew

/**
 * Created by guoshuyu
 * Date: 2018-10-17
 */
import io.flutter.plugin.common.PluginRegistry.Registrar

/** WebviewFlutterPlugin  */
object WebviewFlutterPlugin {
    /** Plugin registration.  */
    fun registerWith(registrar: Registrar) {
        registrar.platformViewRegistry().registerViewFactory("plugins.flutter.io/webview", WebViewFactory(registrar.messenger()))
    }
}