import 'package:dio/dio.dart';

/**
 * header拦截器
 * Created by guoshuyu
 * on 2019/3/23.
 */
class HeaderInterceptors extends InterceptorsWrapper {


  @override
  onRequest(RequestOptions options) {
    ///超时
    options.connectTimeout = 15000;

    return options;
  }
}