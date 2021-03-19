import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/model/TrendingRepoModel.dart';
import 'package:gsy_github_app_flutter/common/net/api.dart';
import 'package:gsy_github_app_flutter/common/net/code.dart';
import 'package:gsy_github_app_flutter/common/net/result_data.dart';

/**
 * 趋势数据解析
 * Created with guoshuyu
 * Date: 2018-07-16
 */
class GitHubTrending {
  fetchTrending(url) async {
    var res = await httpManager.netFetch(
        url, null, null, new Options(contentType: "text/plain; charset=utf-8"));
    if (res != null && res.result && res.data != null) {
      return new ResultData(
          TrendingUtil.htmlToRepo(res.data), true, Code.SUCCESS);
    } else {
      return res;
    }
  }
}

const TAGS = {
  "meta": {
    "start": '<span class="d-inline-block float-sm-right"',
    "flag": '/svg>',
    "end": '</span>end'
  },
  "starCount": {
    "start": '<svg aria-label="star"',
    "flag": '/svg>',
    "end": '</a>'
  },
  "forkCount": {
    "start": '<svg aria-label="repo-forked"',
    "flag": '/svg>',
    "end": '</a>'
  }
};

class TrendingUtil {
  static htmlToRepo(String responseData) {
    try {
      responseData = responseData.replaceAll(new RegExp('\n'), '');
    } catch (e) {}
    var repos = [];
    var splitWithH3 = responseData.split('<article');
    splitWithH3.removeAt(0);
    for (var i = 0; i < splitWithH3.length; i++) {
      var repo = TrendingRepoModel.empty();
      var html = splitWithH3[i];

      parseRepoBaseInfo(repo, html);

      var metaNoteContent =
          parseContentWithNote(html, 'class="f6 text-gray mt-2">', '<\/div>') +
              "end";
      repo.meta = parseRepoLabelWithTag(repo, metaNoteContent, TAGS["meta"]);
      repo.starCount =
          parseRepoLabelWithTag(repo, metaNoteContent, TAGS["starCount"]);
      repo.forkCount =
          parseRepoLabelWithTag(repo, metaNoteContent, TAGS["forkCount"]);

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
    var url =
        htmlBaseInfo.substring(urlIndex, htmlBaseInfo.indexOf('">', urlIndex));
    repo.url = url;
    repo.fullName = url.substring(1, url.length);
    if (repo.fullName != null && repo.fullName.indexOf('/') != -1) {
      repo.name = repo.fullName.split('/')[0];
      repo.reposName = repo.fullName.split('/')[1];
    }

    String? description = parseContentWithNote(
        htmlBaseInfo, '<p class="col-9 text-gray my-1 pr-4">', '</p>');
    if (description != null) {
      String reg = "<g-emoji.*?>.+?</g-emoji>";
      RegExp tag = new RegExp(reg);
      Iterable<Match> tags = tag.allMatches(description);
      for (Match m in tags) {
        String match = m
            .group(0)!
            .replaceAll(new RegExp("<g-emoji.*?>"), "")
            .replaceAll(new RegExp("</g-emoji>"), "");
        description = description?.replaceAll(new RegExp(m.group(0)!), match);
      }
    }
    repo.description = description;
  }

  static parseRepoLabelWithTag(repo, noteContent, tag) {
    var startFlag;
    if (TAGS["starCount"] == tag || TAGS["forkCount"] == tag) {
      startFlag = tag["start"];
    } else {
      startFlag = tag["start"];
    }
    var content = parseContentWithNote(noteContent, startFlag, tag["end"]);
    if (tag["flag"] != null &&
        content.indexOf(tag["flag"]) != -1 &&
        (content.indexOf(tag["flag"]) + tag["flag"].length <= content.length)) {
      var metaContent = content.substring(
          content.indexOf(tag["flag"]) + tag["flag"].length, content.length);
      return trim(metaContent);
    } else {
      return trim(content);
    }
  }

  static parseRepoLang(repo, metaNoteContent) {
    var content = parseContentWithNote(
        metaNoteContent, 'programmingLanguage">', '</span>');
    repo.language = trim(content);
  }

  static parseRepoContributors(repo, htmlContributors) {
    htmlContributors =
        parseContentWithNote(htmlContributors, 'Built by', '<\/a>');
    var splitWitSemicolon = htmlContributors.split('\"');
    if (splitWitSemicolon.length > 1) {
      repo.contributorsUrl = splitWitSemicolon[1];
    }
    var contributors = [];
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
