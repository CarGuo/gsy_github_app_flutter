import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.Registrar

class UpdateAlbumPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    /** Channel名称  **/

    private var channel: MethodChannel? = null
    private var context: Context? = null

    companion object {

        private val sChannelName = "com.shuyu.gsygithub.gsygithubflutter/UpdateAlbumPlugin"

        fun registerWith(registrar: Registrar) {
            val instance = UpdateAlbumPlugin()
            instance.channel = MethodChannel(registrar.messenger(), sChannelName)
            instance.context = registrar.context()
            instance.channel?.setMethodCallHandler(instance)
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
                binding.flutterEngine.dartExecutor, sChannelName)
        context = binding.applicationContext
        channel!!.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(methodCall: MethodCall, result: MethodChannel.Result) {
        when (methodCall.method) {
            "updateAlbum" -> {
                val path: String? = methodCall.argument("path")
                val name: String? = methodCall.argument("name")
                try {
                    MediaStore.Images.Media.insertImage(context?.contentResolver, path, name, null)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                // 最后通知图库更新
                context?.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, Uri.parse("file://$path")))
            }
        }
        result.success(null)
    }
}