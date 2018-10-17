package com.shuyu.gsygithub.gsygithubappflutter.webivew

/**
 * Created by guoshuyu
 * Date: 2018-10-17
 */
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class WebViewFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, args: Any): PlatformView {
        val params = args as Map<String, Any>
        return FlutterWebView(context, messenger, id, params)
    }
}