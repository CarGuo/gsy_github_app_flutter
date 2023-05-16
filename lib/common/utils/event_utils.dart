import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/model/Event.dart';
import 'package:gsy_github_app_flutter/model/PushEventCommit.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';

/**
 * 事件逻辑
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class EventUtils {
  ///事件描述与动作
  static ({String? actionStr, String? des})getActionAndDes(Event event) {
    String? actionStr;
    String? des;
    switch (event.type) {
      case "CommitCommentEvent":
        actionStr = "Commit comment at " + event.repo!.name!;
        break;
      case "CreateEvent":
        if (event.payload!.refType == "repository") {
          actionStr = "Created repository " + event.repo!.name!;
        } else {
          actionStr = "Created " +
              event.payload!.refType! +
              " " +
              event.payload!.ref! +
              " at " +
              event.repo!.name!;
        }
        break;
      case "DeleteEvent":
        actionStr = "Delete " +
            event.payload!.refType! +
            " " +
            event.payload!.ref! +
            " at " +
            event.repo!.name!;
        break;
      case "ForkEvent":
        String oriRepo = event.repo!.name!;
        String newRepo = event.actor!.login! + "/" + event.repo!.name!;
        actionStr = "Forked " + oriRepo + " to " + newRepo;
        break;
      case "GollumEvent":
        actionStr = event.actor!.login! + " a wiki page ";
        break;

      case "InstallationEvent":
        actionStr = event.payload!.action! + " an GitHub App ";
        break;
      case "InstallationRepositoriesEvent":
        actionStr = event.payload!.action! + " repository from an installation ";
        break;
      case "IssueCommentEvent":
        actionStr = event.payload!.action! +
            " comment on issue " +
            event.payload!.issue!.number.toString() +
            " in " +
            event.repo!.name!;
        des = event.payload!.comment!.body;
        break;
      case "IssuesEvent":
        actionStr = event.payload!.action! +
            " issue " +
            event.payload!.issue!.number.toString() +
            " in " +
            event.repo!.name!;
        des = event.payload!.issue!.title;
        break;

      case "MarketplacePurchaseEvent":
        actionStr = event.payload!.action! + " marketplace plan ";
        break;
      case "MemberEvent":
        actionStr = event.payload!.action! + " member to " + event.repo!.name!;
        break;
      case "OrgBlockEvent":
        actionStr = event.payload!.action! + " a user ";
        break;
      case "ProjectCardEvent":
        actionStr = event.payload!.action! + " a project ";
        break;
      case "ProjectColumnEvent":
        actionStr = event.payload!.action! + " a project ";
        break;

      case "ProjectEvent":
        actionStr = event.payload!.action! + " a project ";
        break;
      case "PublicEvent":
        actionStr = "Made " + event.repo!.name! + " public";
        break;
      case "PullRequestEvent":
        actionStr = event.payload!.action! + " pull request " + event.repo!.name!;
        break;
      case "PullRequestReviewEvent":
        actionStr =
            event.payload!.action! + " pull request review at" + event.repo!.name!;
        break;
      case "PullRequestReviewCommentEvent":
        actionStr = event.payload!.action! +
            " pull request review comment at" +
            event.repo!.name!;
        break;

      case "PushEvent":
        String ref = event.payload!.ref!;
        ref = ref.substring(ref.lastIndexOf("/") + 1);
        actionStr = "Push to " + ref + " at " + event.repo!.name!;

        des = '';
        String descSpan = '';

        int count = event.payload!.commits!.length;
        int maxLines = 4;
        int max = count > maxLines ? maxLines - 1 : count;

        for (int i = 0; i < max; i++) {
          PushEventCommit commit = event.payload!.commits![i];
          if (i != 0) {
            descSpan += ("\n");
          }
          String sha = commit.sha!.substring(0, 7);
          descSpan += sha;
          descSpan += " ";
          descSpan += commit.message!;
        }
        if (count > maxLines) {
          descSpan = descSpan + "\n" + "...";
        }
        break;
      case "ReleaseEvent":
        actionStr = event.payload!.action! +
            " release " +
            event.payload!.release!.tagName! +
            " at " +
            event.repo!.name!;
        break;
      case "WatchEvent":
        actionStr = event.payload!.action! + " " + event.repo!.name!;
        break;
    }

    return (actionStr: actionStr, des: des != null ? des : "");
  }

  ///跳转
  static ActionUtils(BuildContext context, Event event, currentRepository) {
    if (event.repo == null) {
      NavigatorUtils.goPerson(context, event.actor!.login);
      return;
    }
    var [owner, repositoryName] = event.repo!.name!.split("/");
    String fullName = owner + '/' + repositoryName;
    switch (event.type) {
      case 'ForkEvent':
        String forkName = event.actor!.login! + "/" + repositoryName;
        if (forkName.toLowerCase() == currentRepository.toLowerCase()) {
          return;
        }
        NavigatorUtils.goReposDetail(
            context, event.actor!.login, repositoryName);
        break;
      case 'PushEvent':
        if (event.payload!.commits == null) {
          if (fullName.toLowerCase() == currentRepository.toLowerCase()) {
            return;
          }
          NavigatorUtils.goReposDetail(context, owner, repositoryName);
        } else if (event.payload!.commits!.length == 1) {
          NavigatorUtils.goPushDetailPage(context, owner, repositoryName,
              event.payload!.commits![0].sha, true);
        } else {
          StringList list = [];
          for (int i = 0; i < event.payload!.commits!.length; i++) {
            list.add(event.payload!.commits![i].message! +
                " " +
                event.payload!.commits![i].sha!.substring(0, 4));
          }
          CommonUtils.showCommitOptionDialog(context, list, (index) {
            NavigatorUtils.goPushDetailPage(context, owner, repositoryName,
                event.payload!.commits![index].sha, true);
          });
        }
        break;
      case 'ReleaseEvent':
        String url = event.payload!.release!.tarballUrl!;
        CommonUtils.launchWebView(context, repositoryName, url);
        break;
      case 'IssueCommentEvent':
      case 'IssuesEvent':
        NavigatorUtils.goIssueDetail(context, owner, repositoryName,
            event.payload!.issue!.number.toString(),
            needRightLocalIcon: true);
        break;
      default:
        if (fullName.toLowerCase() == currentRepository.toLowerCase()) {
          return;
        }
        NavigatorUtils.goReposDetail(context, owner, repositoryName);
        break;
    }
  }
}
