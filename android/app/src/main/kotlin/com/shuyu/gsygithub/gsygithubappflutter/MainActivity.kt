package com.shuyu.gsygithub.gsygithubappflutter

import android.os.Bundle

import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import com.shuyu.gsygithub.gsygithubappflutter.webivew.WebviewFlutterPlugin

class MainActivity(): FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)
    UpdateAlbumPlugin.register(this, flutterView)
    WebviewFlutterPlugin.registerWith(flutterView.pluginRegistry.registrarFor("com.shuyu.gsygithub.gsygithubappflutter"))
  }
}
