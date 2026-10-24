// 2026-10-24 / FPR-120: composition order is not the repository's primary
// language. The shared fragment applies this contract to the parent as well.
const String readRepository = r'''
query getRepositoryDetail($owner:String!, $name:String!){
  repository(name: $name, owner: $owner) {
    ...comparisonFields
    parent {
      ...comparisonFields
    }
  }
}

fragment comparisonFields on Repository {
     issuesClosed: issues(states : CLOSED) {
      totalCount
    }
    issuesOpen: issues(states : OPEN) {
      totalCount
    }
    issues {
      totalCount
    }
    nameWithOwner,
  	id,
    name,
    owner {
      login,
      url,
      avatarUrl,
    },
  	licenseInfo {
      name
    }
    forkCount,
  	stargazers{
      totalCount
    }
    hasIssuesEnabled,
    hasDiscussionsEnabled,
    viewerHasStarred,
    viewerSubscription,
    hasIssuesEnabled,
    defaultBranchRef {
      name
    },
    watchers {
      totalCount,
    }
    isFork
    primaryLanguage {
      name
    }
    languages(first:100) {
      totalSize,
    },
    createdAt,
    pushedAt,
    pushedAt,
		sshUrl,
    url,
  	shortDescriptionHTML,
    repositoryTopics(first: 100) {
      totalCount,
      nodes {
        topic {
          name,
        }
      }
    }
}
''';
