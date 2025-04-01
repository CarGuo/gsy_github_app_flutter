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

  getRepositoryDetailRequest(String userName, String reposName, String branch,
      {needDb = true}) {
    return ReposRepository.getRepositoryDetailRequest(
        userName, reposName, branch);
  }

  getReposCommitsRequest(String userName, String reposName,
      {page = 0, branch = "master", needDb = false}) async {
    return ReposRepository.getReposCommitsRequest(
      userName,
      reposName,
      page: page,
      branch: branch,
      needDb: page <= 1,
    );
  }

  getRepositoryEventRequest(String userName, String reposName,
      {page = 0, branch = "master", needDb = false}) async {
    return ReposRepository.getRepositoryEventRequest(
      userName,
      reposName,
      page: page,
      branch: branch,
      needDb: page <= 1,
    );
  }

  createForkRequest(String userName, String reposName) async {
    return ReposRepository.createForkRequest(userName, reposName);
  }

  doRepositoryWatchRequest(String userName, String reposName, watch) async {
    return ReposRepository.doRepositoryWatchRequest(userName, reposName, watch);
  }

  doRepositoryStarRequest(String userName, String reposName, star) async {
    return ReposRepository.doRepositoryStarRequest(userName, reposName, star);
  }

  getReposFileDirRequest(String userName, String reposName,
      {path = '', branch, text = false, isHtml = false}) async {
    return ReposRepository.getReposFileDirRequest(userName, reposName,
        path: path, branch: branch, text: text, isHtml: isHtml);
  }

  getRepositoryIssueRequest(String userName, String repository, state,
      {sort, direction, page = 0, needDb = false}) async {
    return IssueRepository.getRepositoryIssueRequest(
        userName, repository, state,
        sort: sort, direction: direction, page: page, needDb: needDb);
  }

  searchRepositoryRequest(String q, String name, String reposName, state,
      {page = 1}) async {
    return IssueRepository.searchRepositoryRequest(q, name, reposName, state,
        page: page);
  }

  createIssueRequest(String userName, String repository, issue) async {
    return IssueRepository.createIssueRequest(userName, repository, issue);
  }
}
