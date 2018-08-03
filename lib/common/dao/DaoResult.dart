import 'dart:async';

class DataResult {
  var data;
  bool result;
  Future next;

  DataResult(this.data, this.result, {this.next});
}
