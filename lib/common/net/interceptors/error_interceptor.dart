import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/common/net/Code.dart';
import 'package:gsy_github_app_flutter/common/net/ResultData.dart';

///是否需要弹提示
const NOT_TIP_KEY = "noTip";

/**
 * 错误拦截
 * Created by guoshuyu
 * on 2019/3/23.
 */
class ErrorInterceptors extends InterceptorsWrapper {
  final Dio _dio;

  ErrorInterceptors(this._dio);

  @override
  onRequest(RequestOptions options) async {
    //没有网络
    var connectivityResult = await (new Connectivity().checkConnectivity());
    var noTip = options.headers[NOT_TIP_KEY];
    if (connectivityResult == ConnectivityResult.none) {
      return _dio.resolve(new ResultData(Code.errorHandleFunction(Code.NETWORK_ERROR, "", noTip ?? false), false, Code.NETWORK_ERROR));
    }
    return options;
  }

  @override
  onError(DioError e) {
    Response errorResponse;
    print("………………………………");
    var noTip = e.response != null ? e.response.headers[NOT_TIP_KEY] : true;
    if (e.response != null) {
      errorResponse = e.response;
    } else {
      errorResponse = new Response(statusCode: 666);
    }
    if (e.type == DioErrorType.CONNECT_TIMEOUT) {
      errorResponse.statusCode = Code.NETWORK_TIMEOUT;
    }
    return _dio.resolve(new ResultData(Code.errorHandleFunction(errorResponse.statusCode, e.message, noTip ?? false), false, errorResponse.statusCode));
  }
}
