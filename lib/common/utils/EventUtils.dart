class EventUtils {
  static getActionAndDes(event) {
    String actionStr;
    String des;
    switch (event["type"]) {
      case "CommitCommentEvent":
        actionStr = "Commit comment at " + event["repo"]["name"];
        break;
      case "CreateEvent":
        if (event["payload"]["ref_type"] == "repository") {
          actionStr = "Created repository " + event["repo"]["name"];
        } else {
          actionStr = "Created " + event["payload"]["ref_type"] + " " + event["payload"]["ref"] + " at " + event["repo"]["name"];
        }
        break;
      case "DeleteEvent":
        actionStr = "Delete " + event["payload"]["ref_type"] + " " + event["payload"]["ref"] + " at " + event["repo"]["name"];
        break;
      case "ForkEvent":
        String oriRepo = event["repo"]["name"];
        String newRepo = event["actor"]["login"] + "/" + event["repo"]["name"];
        actionStr = "Forked " + oriRepo + " to " + newRepo;
        break;
      case "GollumEvent":
        actionStr = event["actor"]["login"] + " a wiki page ";
        break;

      case "InstallationEvent":
        actionStr = event["payload"]["action"] + " an GitHub App ";
        break;
      case "InstallationRepositoriesEvent":
        actionStr = event["payload"]["action"] + " repository from an installation ";
        break;
      case "IssueCommentEvent":
        actionStr = event["payload"]["action"] + " comment on issue " + event["payload"]["issue"]["number"].toString() + " in " + event["repo"]["name"];
        des = event["payload"]["comment"]["body"];
        break;
      case "IssuesEvent":
        actionStr = event["payload"]["action"] + " issue " + event["payload"]["issue"]["number"].toString().toString() + " in " + event["repo"]["name"];
        des = event["payload"]["issue"]["title"];
        break;

      case "MarketplacePurchaseEvent":
        actionStr = event["payload"]["action"] + " marketplace plan ";
        break;
      case "MemberEvent":
        actionStr = event["payload"]["action"] + " member to " + event["repo"]["name"];
        break;
      case "OrgBlockEvent":
        actionStr = event["payload"]["action"] + " a user ";
        break;
      case "ProjectCardEvent":
        actionStr = event["payload"]["action"] + " a project ";
        break;
      case "ProjectColumnEvent":
        actionStr = event["payload"]["action"] + " a project ";
        break;

      case "ProjectEvent":
        actionStr = event["payload"]["action"] + " a project ";
        break;
      case "PublicEvent":
        actionStr = "Made " + event["repo"]["name"] + " public";
        break;
      case "PullRequestEvent":
        actionStr = event["payload"]["action"] + " pull request " + event["repo"]["name"];
        break;
      case "PullRequestReviewEvent":
        actionStr = event["payload"]["action"] + " pull request review at" + event["repo"]["name"];
        break;
      case "PullRequestReviewCommentEvent":
        actionStr = event["payload"]["action"] + " pull request review comment at" + event["repo"]["name"];
        break;

      case "PushEvent":
        String ref = event["payload"]["ref"];
        ref = ref.substring(ref.lastIndexOf("/") + 1);
        actionStr = "Push to " + ref + " at " + event["repo"]["name"];

        des = '';
        String descSpan = '';

        int count = event["comments"];
        if(count != null) {
          int maxLines = 4;
          int max = (count != null && count > maxLines) ? maxLines - 1 : count;

          for (int i = 0; i < max; i++) {
            var commit = event["payload"]["comment"].get(i);
            if (i != 0) {
              descSpan += ("\n");
            }
            String sha = commit["sha"].substring(0, 7);
            descSpan += sha;
            descSpan += " ";
            descSpan += commit["message"];
          }
          if (count > maxLines) {
            descSpan = descSpan + "\n" + "...";
          }
        }
        break;
      case "ReleaseEvent":
        actionStr = event["payload"]["action"] + " release " + event["payload"]["release"]["tag_name"] + " at " + event["repo"]["name"];
        break;
      case "WatchEvent":
        actionStr = event["payload"]["action"] + " " + event["repo"]["name"];
        break;
    }

    return {"actionStr": actionStr, "des": des != null ? des : ""};
  }
}
