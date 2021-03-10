import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/model/TrendingRepoModel.dart';
import 'package:rxdart/rxdart.dart';

/**
 * Created by guoshuyu
 * on 2019/3/23.
 */
class TrendBloc {
  bool _requested = false;

  bool _isLoading = false;

  ///是否正在loading
  bool get isLoading => _isLoading;

  ///是否已经请求过
  bool get requested => _requested;

  ///rxdart 实现的 stream
  var _subject = PublishSubject<List<TrendingRepoModel>?>();

  Stream<List<TrendingRepoModel>?> get stream => _subject.stream;

  ///根据数据库和网络返回数据
  Future<void> requestRefresh(selectTime, selectType) async {
    _isLoading = true;
    //_subject.add([]);
    var res = await ReposDao.getTrendDao(since: selectTime.value, languageType: selectType.value);
    if (res != null && res.result) {
      _subject.add(res.data);
    }
    await doNext(res);
    _isLoading = false;
    _requested = true;
    return;
  }

  ///请求next，是否有网络
  doNext(res) async {
    if (res.next != null) {
      var resNext = await res.next();
      if (resNext != null && resNext.result) {
          _subject.add(resNext.data);
      }
    }
  }
}
