/**
 * 网络结果数据
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class ResultData {
  var data;
  bool result;
  int code;
  var headers;

  ResultData(this.data, this.result, this.code, {this.headers});
}
