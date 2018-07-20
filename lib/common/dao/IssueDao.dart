import 'package:gsy_github_app_flutter/common/dao/DaoResult.dart';
import 'package:gsy_github_app_flutter/common/net/Address.dart';
import 'package:gsy_github_app_flutter/common/net/Api.dart';
import 'package:gsy_github_app_flutter/widget/IssueItem.dart';

/**
 * Issue相关
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

  /**
   * 搜索仓库issue
   * @param q 搜索关键字
   * @param name 用户名
   * @param reposName 仓库名
   * @param page
   * @param state 问题状态，all open closed
   */
  static searchRepositoryIssue(q, name, reposName, state, {page = 1}) async {
    String qu;
    if (state == null || state == 'all') {
      qu = q + "+repo%3A${name}%2F${reposName}";
    } else {
      qu = q + "+repo%3A${name}%2F${reposName}+state%3A${state}";
    }
    String url = Address.repositoryIssueSearch(qu) + Address.getPageParams("&", page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<IssueItemViewModel> list = new List();
      var data = res.data["items"];
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
