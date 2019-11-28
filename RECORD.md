flutter build apk --target-platform android-arm64 -t lib/main_prod.dart


query getUserDetail($name:String!){
  user(login: $name) {
    login,
  	avatarUrl,
    company,
    location,
    bio,
  	email,
    bioHTML,
    websiteUrl,
    viewerIsFollowing,
    createdAt,
    repositories(first: 100) {
      totalCount,
      nodes {
        stargazers {
          totalCount
        }
    	}
    }
    followers {
      totalCount
    }
    following {
      totalCount
    }
    starredRepositories {
      totalCount
    }
    isViewer,
    #pinnedItems {
    #  
    #}
    organizations(first: 100) {
      nodes {
        login,
        avatarUrl,
        name
      }
    }
  }
}