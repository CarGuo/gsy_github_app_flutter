import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/net/Code.dart';
import 'package:gsy_github_app_flutter/common/net/ResultData.dart';

/**
 * Created with guoshuyu
 * Date: 2018-07-16
 */

class GitHubTrending {
  fetchTrending(url) async {
    Dio dio = new Dio();
    Response res;
    try {
      res = await dio.request(url, data: null, options: new Options(contentType: ContentType.parse("application/x-www-form-urlencoded")));
    } on DioError catch (e) {
      Response errorResponse;
      if (e.response != null) {
        errorResponse = e.response;
      } else {
        errorResponse = new Response(statusCode: 666);
      }
      if (e.type == DioErrorType.CONNECT_TIMEOUT) {
        errorResponse.statusCode = Code.NETWORK_TIMEOUT;
      }
      if (Config.DEBUG) {
        print('请求异常: ' + e.toString());
        print('请求异常url: ' + url);
      }
      return new ResultData(Code.errorHandleFunction(errorResponse.statusCode, e.message), false, errorResponse.statusCode);
    }
    if (res != null && res.statusCode == 200) {
      return new ResultData(TrendingUtil.htmlToRepo(res.data), true, Code.SUCCESS);
    } else {
      return res;
    }
  }
}

const TAGS = {
  "meta": {"start": '<span class="d-inline-block float-sm-right">', "end": '</span>'},
  "starCount": {"start": '<a class="muted-link d-inline-block mr-3"', "flag": '/stargazers">', "end": '</a>'},
  "forkCount": {"start": '<a class="muted-link d-inline-block mr-3"', "flag": '/network">', "end": '</a>'}
};

class TrendingUtil {
  static htmlToRepo(String responseData) {
    try {
      responseData = responseData.replaceAll(new RegExp('\n'), '');
    } catch (e) {
    }
    var repos = new List();
    var splitWithH3 = responseData.split('<h3');
    splitWithH3.removeAt(0);
    for (var i = 0; i < splitWithH3.length; i++) {
      var repo = new TrendingRepoModel();
      var html = splitWithH3[i];

      parseRepoBaseInfo(repo, html);

      var metaNoteContent = parseContentWithNote(html, 'class="f6 text-gray mt-2">', '</li>');
      repo.meta = parseRepoLabelWithTag(repo, metaNoteContent, TAGS["meta"]);
      repo.starCount = parseRepoLabelWithTag(repo, metaNoteContent, TAGS["starCount"]);
      repo.forkCount = parseRepoLabelWithTag(repo, metaNoteContent, TAGS["forkCount"]);

      parseRepoLang(repo, metaNoteContent);
      parseRepoContributors(repo, metaNoteContent);
      repos.add(repo);
    }
    return repos;
  }

  static parseContentWithNote(htmlStr, startFlag, endFlag) {
    var noteStar = htmlStr.indexOf(startFlag);
    if (noteStar == -1) {
      return '';
    } else {
      noteStar += startFlag.length;
    }

    var noteEnd = htmlStr.indexOf(endFlag, noteStar);
    var content = htmlStr.substring(noteStar, noteEnd);
    return trim(content);
  }

  static parseRepoBaseInfo(repo, htmlBaseInfo) {
    var urlIndex = htmlBaseInfo.indexOf('<a href="') + '<a href="'.length;
    var url = htmlBaseInfo.substring(urlIndex, htmlBaseInfo.indexOf('">', urlIndex));
    repo.url = url;
    repo.fullName = url.substring(1, url.length);
    if (repo.fullName != null && repo.fullName.indexOf('/') != -1) {
      repo.name = repo.fullName.split('/')[0];
      repo.reposName = repo.fullName.split('/')[1];
    }

    var description = parseContentWithNote(htmlBaseInfo, '<p class="col-9 d-inline-block text-gray m-0 pr-4">', '</p>');
    repo.description = description;
  }

  static parseRepoLabelWithTag(repo, noteContent, tag) {
    var startFlag;
    if (TAGS["starCount"] == tag || TAGS["forkCount"] == tag) {
      startFlag = tag["start"] + ' href="/' + repo.fullName + tag["flag"];
    } else {
      startFlag = tag["start"];
    }
    var content = parseContentWithNote(noteContent, startFlag, tag["end"]);
    var metaContent = content.substring(content.indexOf('</svg>') + '</svg>'.length, content.length);
    return trim(metaContent);
  }

  static parseRepoLang(repo, metaNoteContent) {
    var content = parseContentWithNote(metaNoteContent, 'programmingLanguage">', '</span>');
    repo.language = trim(content);
  }

  static parseRepoContributors(repo, htmlContributors) {
    htmlContributors = parseContentWithNote(htmlContributors, 'Built by', '</a>');
    var splitWitSemicolon = htmlContributors.split('"');
    repo.contributorsUrl = splitWitSemicolon[1];
    var contributors = new List<String>();
    for (var i = 0; i < splitWitSemicolon.length; i++) {
      String url = splitWitSemicolon[i];
      if (url.indexOf('http') != -1) {
        contributors.add(url);
      }
    }
    repo.contributors = contributors;
  }

  static trim(text) {
    if (text is String) {
      return text.trim();
    } else {
      return text.toString().trim();
    }
  }
}

class TrendingRepoModel {
  String fullName;
  String url;

  String description;
  String language;
  String meta;
  List<String> contributors;
  String contributorsUrl;

  String starCount;
  String forkCount;
  String name;

  String reposName;

  TrendingRepoModel();
}
