flutter build apk --target-platform android-arm64 -t lib/main_prod.dart --no-sound-null-safety

flutter packages pub run build_runner build --delete-conflicting-outputs

dart migrate --skip-import-check

flutter run --no-sound-null-safety

https://flutter.cn/docs/development/tools/devtools/cli   http://localhost:9100

sudo gem install -n /usr/local/bin cocoapods -v 1.9.3


# 如何查看dill文件

我们可以通过dart sdk中的vm package提供的dump_kernel.dart打印出dill的内部结构。

```
dart bin/dump_kernel.dart /Users/kylewong/Codes/AOP/aspectd/example/aop/build/app.dill /Users/kylewong/Codes/AOP/aspectd/example/aop/build/app.dill.txt
注意bin/dump_kernel.dart需要改成自己dart sdk中的具体路径。
```



///配置多渠道
flutter run --dart-define=CHANNEL=GSY --dart-define=LANGUAGE=Dart
const CHANNEL = String.fromEnvironment('CHANNEL');
const LANGUAGE = String.fromEnvironment('LANGUAGE');


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

query GetStars($name: String!, $owner: String!, $after: String) {
  repository(name: $name, owner: $owner) {
    createdAt
      stargazers(first: 100, after: $after) {
        edges {
           node {
              id
              login
              name
              avatarUrl
              __typename
           }
           starredAt
           __typename
        }
        pageInfo {
          startCursor
           endCursor
           hasNextPage
            __typename↵     
           }
           totalCount
           __typename
        }
        __typename
    }
}