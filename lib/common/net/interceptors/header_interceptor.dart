import 'package:dio/dio.dart';

/**
 * header拦截器
 * Created by guoshuyu
 * on 2019/3/23.
 */
class HeaderInterceptors extends InterceptorsWrapper {
  @override
  onRequest(RequestOptions options) async {
    ///超时
    options.connectTimeout = 30000;
    options.receiveTimeout = 30000;

    return options;
  }
}
