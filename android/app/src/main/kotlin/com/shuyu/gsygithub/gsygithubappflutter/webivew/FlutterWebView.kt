package com.shuyu.gsygithub.gsygithubappflutter.webivew

import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import android.content.Context
import android.view.View
import android.webkit.WebView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView



/**
 * Created by guoshuyu
 * Date: 2018-10-17
 */

class FlutterWebView(context: Context, messenger: BinaryMessenger, id: Int, params: Map<String, Any>) : PlatformView, MethodCallHandler {

    private val webView: WebView

    private val methodChannel: MethodChannel

    init {
        webView = WebView(context)
        if (params.containsKey("initialUrl")) {
            val url = params["initialUrl"] as String
            webView.loadUrl(url)
        }
        applySettings(params["settings"] as Map<String, Any>)
        methodChannel = MethodChannel(messenger, "plugins.flutter.io/webview_$id")
        methodChannel.setMethodCallHandler(this)
    }

    override fun getView(): View {
        return webView
    }

    override fun onMethodCall(methodCall: MethodCall, result: Result) {
        when (methodCall.method) {
            "loadUrl" -> loadUrl(methodCall, result)
            "updateSettings" -> updateSettings(methodCall, result)
            else -> result.notImplemented()
        }
    }

    private fun loadUrl(methodCall: MethodCall, result: Result) {
        val url = methodCall.arguments as String
        webView.loadUrl(url)
        result.success(null)
    }

    private fun updateSettings(methodCall: MethodCall, result: Result) {
        applySettings(methodCall.arguments as Map<String, Any>)
        result.success(null)
    }

    private fun applySettings(settings: Map<String, Any>) {
        for (key in settings.keys) {
            when (key) {
                "jsMode" -> updateJsMode(settings[key] as Int)
                else -> throw IllegalArgumentException("Unknown WebView setting: $key")
            }
        }
    }

    private fun updateJsMode(mode: Int) {
        when (mode) {
            0 // disabled
            -> webView.settings.javaScriptEnabled = false
            1 //unrestricted
            -> webView.settings.javaScriptEnabled = true
            else -> throw IllegalArgumentException("Trying to set unknown Javascript mode: $mode")
        }
    }

    override fun dispose() {}
}