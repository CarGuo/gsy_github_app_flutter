import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/repositories/issue_repository.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';

///#######################这部分没什么意思#########################///
///######## 就是单纯展示 Provider 依赖 Provider ###################///
class ReposNetWorkProvider with ChangeNotifier {
  refreshReadme(String userName, String reposName, String currentBranch) {
    return ReposRepository.getRepositoryDetailReadmeRequest(
        userName, reposName, currentBranch);
  }

  getRepositoryDetailRequest(userName, reposName, branch, {needDb = true}) {
    return ReposRepository.getRepositoryDetailRequest(
        userName, reposName, branch);
  }

  getReposCommitsRequest(userName, reposName,
      {page = 0, branch = "master", needDb = false}) async {
    return ReposRepository.getReposCommitsRequest(
      userName,
      reposName,
      page: page,
      branch: branch,
      needDb: page <= 1,
    );
  }

  getRepositoryEventRequest(userName, reposName,
      {page = 0, branch = "master", needDb = false}) async {
    return ReposRepository.getRepositoryEventRequest(
      userName,
      reposName,
      page: page,
      branch: branch,
      needDb: page <= 1,
    );
  }

  createForkRequest(userName, reposName) async {
    return ReposRepository.createForkRequest(userName, reposName);
  }

  doRepositoryWatchRequest(userName, reposName, watch) async {
    return ReposRepository.doRepositoryWatchRequest(userName, reposName, watch);
  }

  doRepositoryStarRequest(userName, reposName, star) async {
    return ReposRepository.doRepositoryStarRequest(userName, reposName, star);
  }

  getReposFileDirRequest(userName, reposName,
      {path = '', branch, text = false, isHtml = false}) async {
    return ReposRepository.getReposFileDirRequest(userName, reposName,
        path: path, branch: branch, text: text, isHtml: isHtml);
  }

  getRepositoryIssueRequest(userName, repository, state,
      {sort, direction, page = 0, needDb = false}) async {
    return IssueRepository.getRepositoryIssueRequest(
        userName, repository, state,
        sort: sort, direction: direction, page: page, needDb: needDb);
  }

  searchRepositoryRequest(q, name, reposName, state, {page = 1}) async {
    return IssueRepository.searchRepositoryRequest(q, name, reposName, state,
        page: page);
  }

  createIssueRequest(userName, repository, issue) async {
    return IssueRepository.createIssueRequest(userName, repository, issue);
  }
}
