import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:gsy_github_app_flutter/model/event.dart';
import 'package:gsy_github_app_flutter/model/push_event_commit.dart';
import 'package:gsy_github_app_flutter/model/repo_commit.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';

/// 事件逻辑
/// Created by guoshuyu
/// Date: 2018-07-16
class EventUtils {
  static bool _isInvalidCompareBase(String? sha) {
    if (sha == null || sha.isEmpty) {
      return true;
    }
    return RegExp(r'^0+$').hasMatch(sha);
  }

  static String _shortSha(String? sha, [int length = 7]) {
    if (sha == null || sha.isEmpty) {
      return "";
    }
    if (sha.length <= length) {
      return sha;
    }
    return sha.substring(0, length);
  }

  ///事件描述与动作
  static ({String? actionStr, String? des}) getActionAndDes(Event event) {
    String? actionStr;
    String? des;
    switch (event.type) {
      case "CommitCommentEvent":
        actionStr = "Commit comment at ${event.repo!.name!}";
        break;
      case "CreateEvent":
        if (event.payload!.refType == "repository") {
          actionStr = "Created repository ${event.repo!.name!}";
        } else {
          actionStr =
              "Created ${event.payload!.refType!} ${event.payload!.ref!} at ${event.repo!.name!}";
        }
        break;
      case "DeleteEvent":
        actionStr =
            "Delete ${event.payload!.refType!} ${event.payload!.ref!} at ${event.repo!.name!}";
        break;
      case "ForkEvent":
        String oriRepo = event.repo!.name!;
        String newRepo = "${event.actor!.login!}/${event.repo!.name!}";
        actionStr = "Forked $oriRepo to $newRepo";
        break;
      case "GollumEvent":
        actionStr = "${event.actor!.login!} a wiki page ";
        break;

      case "InstallationEvent":
        actionStr = "${event.payload!.action!} an GitHub App ";
        break;
      case "InstallationRepositoriesEvent":
        actionStr =
            "${event.payload!.action!} repository from an installation ";
        break;
      case "IssueCommentEvent":
        actionStr =
            "${event.payload!.action!} comment on issue ${event.payload!.issue!.number} in ${event.repo!.name!}";
        des = event.payload!.comment!.body;
        break;
      case "IssuesEvent":
        actionStr =
            "${event.payload!.action!} issue ${event.payload!.issue!.number} in ${event.repo!.name!}";
        des = event.payload!.issue!.title;
        break;

      case "MarketplacePurchaseEvent":
        actionStr = "${event.payload!.action!} marketplace plan ";
        break;
      case "MemberEvent":
        actionStr = "${event.payload!.action!} member to ${event.repo!.name!}";
        break;
      case "OrgBlockEvent":
        actionStr = "${event.payload!.action!} a user ";
        break;
      case "ProjectCardEvent":
        actionStr = "${event.payload!.action!} a project ";
        break;
      case "ProjectColumnEvent":
        actionStr = "${event.payload!.action!} a project ";
        break;

      case "ProjectEvent":
        actionStr = "${event.payload!.action!} a project ";
        break;
      case "PublicEvent":
        actionStr = "Made ${event.repo!.name!} public";
        break;
      case "PullRequestEvent":
        actionStr =
            "${event.payload!.action!} pull request ${event.repo!.name!}";
        break;
      case "PullRequestReviewEvent":
        actionStr =
            "${event.payload!.action!} pull request review at${event.repo!.name!}";
        break;
      case "PullRequestReviewCommentEvent":
        actionStr =
            "${event.payload!.action!} pull request review comment at${event.repo!.name!}";
        break;

      case "PushEvent":
        if (event.payload != null && event.payload?.ref != null) {
          String ref = event.payload!.ref!;
          ref = ref.substring(ref.lastIndexOf("/") + 1);
          actionStr = "Push to $ref at ${event.repo!.name!}";

          String descSpan = "";
          List<PushEventCommit> commits = event.payload?.commits ?? [];
          int count = commits.length;
          int maxLines = 4;
          int max = count > maxLines ? maxLines - 1 : count;

          for (int i = 0; i < max; i++) {
            PushEventCommit commit = commits[i];
            if (i != 0) {
              descSpan += ("\n");
            }
            String sha = _shortSha(commit.sha);
            descSpan += sha;
            descSpan += " ";
            descSpan += (commit.message ?? "Commit");
          }
          if (count > maxLines) {
            descSpan = "$descSpan\n...";
          }
          if (descSpan.trim().isNotEmpty) {
            des = descSpan;
          } else if (event.payload?.description != null &&
              event.payload!.description!.trim().isNotEmpty) {
            des = event.payload!.description;
          } else if (event.payload?.head != null &&
              event.payload!.head!.trim().isNotEmpty) {
            String head = _shortSha(event.payload!.head);
            des = "head: $head";
          } else {
            des = "";
          }
        } else {
          actionStr = "";
        }
        break;
      case "ReleaseEvent":
        actionStr =
            "${event.payload!.action!} release ${event.payload!.release!.tagName!} at ${event.repo!.name!}";
        break;
      case "WatchEvent":
        actionStr = "${event.payload!.action!} ${event.repo!.name!}";
        break;
    }

    return (actionStr: actionStr, des: des ?? "");
  }

  ///跳转
  static Future<void> ActionUtils(
    BuildContext context,
    Event event,
    currentRepository,
  ) async {
    if (event.repo == null) {
      NavigatorUtils.goPerson(context, event.actor!.login);
      return;
    }
    var [owner, repositoryName] = event.repo!.name!.split("/");
    String fullName = '$owner/$repositoryName';
    switch (event.type) {
      case 'ForkEvent':
        String forkName = "${event.actor!.login!}/$repositoryName";
        if (forkName.toLowerCase() == currentRepository.toLowerCase()) {
          return;
        }
        NavigatorUtils.goReposDetail(
          context,
          event.actor!.login!,
          repositoryName,
        );
        break;
      case 'PushEvent':
        List<PushEventCommit> commits = event.payload?.commits ?? [];
        String? beforeSha = event.payload?.before;
        String? headSha = event.payload?.head;
        List<RepoCommit> compareCommits = [];

        if (!_isInvalidCompareBase(beforeSha) &&
            headSha != null &&
            headSha.isNotEmpty &&
            beforeSha != headSha) {
          CommonUtils.showLoadingDialog(context);
          try {
            var compareRes = await ReposRepository.getReposCompareRequest(
              owner,
              repositoryName,
              beforeSha!,
              headSha,
            );
            if (compareRes != null &&
                compareRes.result &&
                compareRes.data != null) {
              compareCommits = compareRes.data.commits ?? [];
            }
          } finally {
            if (context.mounted) {
              Navigator.pop(context);
            }
          }
        }
        if (!context.mounted) {
          return;
        }

        if (compareCommits.length == 1 && compareCommits.first.sha != null) {
          NavigatorUtils.goPushDetailPage(
            context,
            owner,
            repositoryName,
            compareCommits.first.sha,
            true,
          );
          return;
        }

        if (compareCommits.length > 1) {
          StringList list = [];
          for (int i = 0; i < compareCommits.length; i++) {
            RepoCommit commit = compareCommits[i];
            String message =
                commit.commit?.message?.split('\n').first.trim() ?? "Commit";
            if (message.isEmpty) {
              message = "Commit";
            }
            list.add("$message ${_shortSha(commit.sha, 4)}");
          }
          CommonUtils.showCommitOptionDialog(context, list, (index) {
            NavigatorUtils.goPushDetailPage(
              context,
              owner,
              repositoryName,
              compareCommits[index].sha,
              true,
            );
          });
          return;
        }

        if (commits.isEmpty) {
          if (headSha != null && headSha.isNotEmpty) {
            NavigatorUtils.goPushDetailPage(
              context,
              owner,
              repositoryName,
              headSha,
              true,
            );
            return;
          }
          if (fullName.toLowerCase() == currentRepository.toLowerCase()) {
            return;
          }
          NavigatorUtils.goReposDetail(context, owner, repositoryName);
        } else if (commits.length == 1 && commits.first.sha != null) {
          NavigatorUtils.goPushDetailPage(
            context,
            owner,
            repositoryName,
            commits.first.sha,
            true,
          );
        } else {
          List<PushEventCommit> validCommits = commits
              .where((item) => item.sha != null && item.sha!.isNotEmpty)
              .toList();
          if (validCommits.isEmpty) {
            if (headSha != null && headSha.isNotEmpty) {
              NavigatorUtils.goPushDetailPage(
                context,
                owner,
                repositoryName,
                headSha,
                true,
              );
            } else {
              NavigatorUtils.goReposDetail(context, owner, repositoryName);
            }
            return;
          }
          if (validCommits.length == 1) {
            NavigatorUtils.goPushDetailPage(
              context,
              owner,
              repositoryName,
              validCommits.first.sha,
              true,
            );
            return;
          }
          StringList list = [];
          for (int i = 0; i < validCommits.length; i++) {
            PushEventCommit commit = validCommits[i];
            String shaShort = _shortSha(commit.sha, 4);
            String message = (commit.message == null || commit.message!.isEmpty)
                ? "Commit"
                : commit.message!;
            list.add("$message $shaShort");
          }
          CommonUtils.showCommitOptionDialog(context, list, (index) {
            NavigatorUtils.goPushDetailPage(
              context,
              owner,
              repositoryName,
              validCommits[index].sha,
              true,
            );
          });
        }
        break;
      case 'ReleaseEvent':
        String url = event.payload!.release!.tarballUrl!;
        CommonUtils.launchWebView(context, repositoryName, url);
        break;
      case 'IssueCommentEvent':
      case 'IssuesEvent':
        NavigatorUtils.goIssueDetail(
          context,
          owner,
          repositoryName,
          event.payload!.issue!.number.toString(),
          needRightLocalIcon: true,
        );
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
