import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

object UpdateAlbumPlugin {

    /** Channel名称  **/
    private const val ChannelName = "com.shuyu.gsygithub.gsygithubflutter/UpdateAlbumPlugin"

    /**
     * 注册Toast插件
     * @param context 上下文对象
     * @param messenger 数据信息交流对象
     */
    @JvmStatic
    fun register(context: Context, messenger: BinaryMessenger) = MethodChannel(messenger, ChannelName).setMethodCallHandler { methodCall, result ->
        when (methodCall.method) {
            "updateAlbum" -> {
                val path: String? = methodCall.argument("path")
                val name: String? = methodCall.argument("name")
                try {
                    MediaStore.Images.Media.insertImage(context.contentResolver, path, name, null)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                // 最后通知图库更新
                context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, Uri.parse("file://$path")))
            }
        }
        result.success(null) //没有返回值，所以直接返回为null
    }

}