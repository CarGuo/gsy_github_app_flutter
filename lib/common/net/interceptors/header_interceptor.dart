import 'package:dio/dio.dart';

/**
 * header拦截器
 * Created by guoshuyu
 * on 2019/3/23.
 */
class HeaderInterceptors extends InterceptorsWrapper {
  @override
  onRequest(RequestOptions options, handler) async {
    ///超时
    options.connectTimeout = Duration(seconds: 30);
    options.receiveTimeout = Duration(seconds: 30);

    return super.onRequest(options, handler);
  }
}
