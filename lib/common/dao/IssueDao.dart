import 'package:gsy_github_app_flutter/common/dao/DaoResult.dart';
import 'package:gsy_github_app_flutter/common/net/Address.dart';
import 'package:gsy_github_app_flutter/common/net/Api.dart';
import 'package:gsy_github_app_flutter/widget/IssueItem.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-19
 */

class IssueDao {
  /**
   * 获取仓库issue
   * @param page
   * @param userName
   * @param repository
   * @param state issue状态
   * @param sort 排序类型 created updated等
   * @param direction 正序或者倒序
   */
  static getRepositoryIssueDao(userName, repository, state, {sort, direction, page = 0}) async {
    String url = Address.getReposIssue(userName, repository, state, sort, direction) + Address.getPageParams("&", page);
    var res = await HttpManager.netFetch(url, null, {"Accept": 'application/vnd.github.html,application/vnd.github.VERSION.raw'}, null);
    if (res != null && res.result) {
      List<IssueItemViewModel> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(IssueItemViewModel.fromMap(data[i]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }
}
