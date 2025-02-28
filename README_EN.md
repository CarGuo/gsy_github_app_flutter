![](./logo.png)

[![Github Actions](https://github.com/CarGuo/gsy_github_app_flutter/workflows/CI/badge.svg)](https://github.com/CarGuo/gsy_github_app_flutter/actions)
[![GitHub stars](https://img.shields.io/github/stars/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/network)
[![GitHub issues](https://img.shields.io/github/issues/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/issues)
[![GitHub license](https://img.shields.io/github/license/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/LICENSE)

### [Chinese Readme](https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/README.md)


## A cross-platform open source Github client App, offering richer features and better experience. Designed for better daily management and maintenance of your personal Github account, providing a more convenient driving experience～～Σ(￣。￣ﾉ)ﾉ. The project involves various common widgets, networking, databases, design patterns, theme switching, multi-language support, state management (Redux, Riverpod, Provider), and more. During the development and learning process, it provides rich comparisons with equivalent implementations:


* ### Simple Flutter standalone learning project ( https://github.com/CarGuo/gsy_flutter_demo )
* ### Same Weex version ( https://github.com/CarGuo/GSYGithubAppWeex )
* ### Same ReactNative version ( https://github.com/CarGuo/GSYGithubApp )
* ### Same Android Kotlin version ( https://github.com/CarGuo/GSYGithubAppKotlin )



## Related Articles

- ## [Flutter Series Articles Column](https://juejin.cn/column/6960546078202527774)

----
- ## [Flutter Simple Learning Demo Project](https://github.com/CarGuo/gsy_flutter_demo)
- ## [Flutter Complete Development Practical Detailed Gitbook Preview Download](https://github.com/CarGuo/gsy_flutter_book)
- ## [For all running issues please click here](https://github.com/CarGuo/gsy_github_app_flutter/issues/13)




* ### GSY's book: ["Flutter Development Practical Guide"](https://item.jd.com/12883054.html) is now available: [JD](https://item.jd.com/12883054.html) / [Dangdang](http://product.dangdang.com/28558519.html) / E-version [JD Reading](https://e.jd.com/30624414.html) and [Kindle](https://www.amazon.cn/dp/B08BHQ4TKK/ref=sr_1_5?__mk_zh_CN=亚马逊网站&keywords=flutter&qid=1593498531&s=digital-text&sr=1-5)

[![](http://img.cdn.guoshuyu.cn/WechatIMG65.jpeg)](https://item.jd.com/12883054.html)


| WeChat Official Account   | Juejin     |  Zhihu    |  CSDN   |   Jianshu   
|---------|---------|--------- |---------|---------|
| GSYTech  |  [Click me](https://juejin.im/user/582aca2ba22b9d006b59ae68/posts)    |   [Click me](https://www.zhihu.com/people/carguo)       |   [Click me](https://blog.csdn.net/ZuoYueLiang)  |   [Click me](https://www.jianshu.com/u/6e613846e1ea)  

- ### [If cloning is too slow or if images don't display, you can try downloading from the Gitee address](https://gitee.com/CarGuo/GSYGithubAppFlutter)



-----

## Important Notes

> **Since this is primarily a learning and demonstration project, it includes various patterns, libraries, UIs, etc. Please don't mind the diversity**
> 
> 0. Global state management currently has multiple patterns, including Provider, Redux, Riverpod, etc.
> 
> 1. TrendPage: Currently uses pure Riverpod state management for demonstration
>
> 2. Scoped Model: Currently used in RepositoryDetailPage
>
> 3. Redux: Currently demonstrated for global login and user information, etc.
> 
> 4. ReposDetailPage: Currently uses Provider state management to demonstrate combined usage
>
> 5. LoginPage: An alternative BLoC pattern
> 
> 6. Repos and other requests demonstrate graphQL
> 
> **There are multiple list displays, including:**
> 
> 1. **gsy_pull_load_widget.dart**
> `Used in common_list_page.dart, etc., paired with gsy_list_state.dart`
>
> 2. **gsy_pull_new_load_widget.dart**
> `Used in dynamic_page.dart, etc., paired with gsy_bloc_list_state.dart`
> `Supports both iOS and Android pull-to-refresh styles`
> 
> 3. **gsy_nested_pull_load_widget.dart**
> `Used in trend_page.dart, etc., configured with sliver effect`


## Compilation and Running Process

1. Set up the Flutter development environment (current Flutter SDK version **3.29**), see [Setting up the environment](https://flutterchina.club).

2. Clone the code, run `Packages get` to install third-party packages. (Due to certain reasons beyond control, you may need to set up a proxy in China: [Proxy environment variables](https://flutterchina.club/setup-windows/))

>### 3. Important: You need to create an `ignoreConfig.dart` file in the lib/common/config/ directory yourself, and then enter your registered Github client_id and client_secret.

     class NetConfig {
       static const CLIENT_ID = "xxxx";
     
       static const CLIENT_SECRET = "xxxxxxxxxxx";
     }


   [      Register Github APP link](https://github.com/settings/applications/new), of course, the prerequisite is that you already have a github account (～￣▽￣)～.
 
### 4. If using secure login (authorization login), then in the above Github App registration, the Authorization callback URL field must be filled with `gsygithubapp://authed`

<div>
<img src="http://img.cdn.guoshuyu.cn/register0.png" width="426px"/>
<img src="http://img.cdn.guoshuyu.cn/register1.jpg" width="426px"/>
</div>

### 5. Please note before running

>### 1. Local Flutter SDK version 3.29; 2. Have you executed `flutter pub get`; 3. For network and other issues, refer to: [If login fails or requests fail](https://github.com/CarGuo/gsy_github_app_flutter/issues/643)


### Download

#### APK download link: [APK download link 1](https://github.com/CarGuo/gsy_github_app_flutter/releases)
#### APK download link: [APK download link 2](https://www.openapk.net/gsygithubappflutter/com.shuyu.gsygithub.gsygithubappflutter/)
![openapk](https://www.openapk.net/images/openapk-badge.png)

| Type          | QR Code                                      |
| ----------- | ---------------------------------------- |
| **APK QR Code**  | ![](./download.png) |
| **iOS download not available** | |



## Project Structure Diagram

![](./framework2.png)




### Common Issues

* If package synchronization fails, it's usually because the package proxy is not set. You can refer to: [Environment variable issues](https://github.com/CarGuo/GSYGithubAppFlutter/issues/13)

* [If cloning is too slow, you can try downloading from the Gitee address](https://gitee.com/CarGuo/GSYGithubAppFlutter)

### Example Images

![](./ios.gif)

![](./theme.gif)

<img src="http://img.cdn.guoshuyu.cn/showapp1.jpg" width="426px"/>

<img src="http://img.cdn.guoshuyu.cn/showapp2.jpg" width="426px"/>

<img src="http://img.cdn.guoshuyu.cn/showapp3.jpg" width="426px"/>


### Framework

>Current Flutter SDK version 3.29

```
User Interaction → UI Layer(Widget/Page) → State Layer(Redux/Provider/Riverpod) → Service Layer(Repositories) 
       → Network Layer(Net) → GitHub API → Data Model(Model) → Local Storage(DB) → UI Update
```

```
┌─────────────────────────────────────────────────────────────────┐
│                         GSY GitHub App                          │
├─────────────┬───────────────┬────────────────┬─────────────────┤
│   UI Layer  │  State Layer  │  Service Layer │     Data Layer  │
├─────────────┼───────────────┼────────────────┼─────────────────┤
│             │               │                │                 │
│  ┌─────────┐│  ┌─────────┐  │  ┌─────────┐   │   ┌─────────┐   │
│  │ Pages   ││  │ Redux   │  │  │Repositories│  │   │ Models │   │
│  └─────────┘│  └─────────┘  │  └─────────┘   │   └─────────┘   │
│             │               │                │                 │
│  ┌─────────┐│  ┌─────────┐  │  ┌─────────┐   │   ┌─────────┐   │
│  │ Widgets ││  │ Provider│  │  │Network API│  │   │Database │   │
│  └─────────┘│  └─────────┘  │  └─────────┘   │   └─────────┘   │
│             │               │                │                 │
│  ┌─────────┐│  ┌─────────┐  │                │                 │
│  │Common UI││  │Riverpod │  │                │                 │
│  └─────────┘│  └─────────┘  │                │                 │
│             │               │                │                 │
└─────────────┴───────────────┴────────────────┴─────────────────┘
```

```
lib/
├── main.dart              # Application entry point
├── main_prod.dart         # Production environment entry point
├── app.dart               # Application configuration and routing
├── common/                # Common functionality modules
│   ├── config/            # Application configuration
│   ├── event/             # Event bus
│   ├── local/             # Localization
│   ├── localization/      # Multi-language support
│   ├── net/               # Network requests
│   ├── repositories/      # Data repositories
│   ├── router/            # Routing configuration
│   ├── style/             # Style configuration
│   └── utils/             # Utility classes
├── db/                    # Database related
│   ├── provider/          # Database providers
│   ├── sql_manager.dart   # SQL manager
│   └── sql_provider.dart  # SQL provider
├── env/                   # Environment configuration
├── model/                 # Data models
├── page/                  # Pages
│   ├── debug/             # Debug pages
│   ├── dynamic/           # Dynamic pages
│   ├── home/              # Home page
│   ├── issue/             # Issue related pages
│   ├── login/             # Login page
│   ├── push/              # Push related pages
│   ├── release/           # Release related pages
│   ├── repos/             # Repository related pages
│   ├── search/            # Search page
│   ├── trend/             # Trend page
│   └── user/              # User related pages
├── provider/              # Provider state management
├── redux/                 # Redux state management
│   ├── middleware/        # Redux middleware
│   ├── gsy_state.dart     # Redux state definition
│   ├── login_redux.dart   # Login state management
│   └── user_redux.dart    # User state management
├── test/                  # Test related
└── widget/                # Custom widgets
    ├── anima/             # Animation widgets
    ├── markdown/          # Markdown rendering widgets
    ├── menu/              # Menu widgets
    ├── particle/          # Particle effect widgets
    ├── pull/              # Pull-to-refresh widgets
    └── state/             # State related widgets
```

Riverpod page state management:

```
┌───────────────────────────────────────────────────────────────────────────┐
│                           TrendPage Architecture                           │
└───────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                              Global State                                  │
│  ┌───────────────────┐   ┌────────────────────┐   ┌────────────────────┐  │
│  │ appThemeProvider  │   │ appLocalProvider   │   │ appGrepProvider    │  │
│  │ (Theme Data)      │   │ (Localization)     │   │ (Grayscale Mode)   │  │
│  └───────────────────┘   └────────────────────┘   └────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                         TrendPage Specific State                           │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                      Riverpod Providers                             │  │
│  │  ┌───────────────────────────────┐  ┌─────────────────────────────┐ │  │
│  │  │        trendFirstProvider     │  │     trendSecondProvider     │ │  │
│  │  │ (Primary Data Source)         │  │ (Secondary Data Source)     │ │  │
│  │  │ - Takes time & language params│  │ - Depends on firstProvider  │ │  │
│  │  │ - Fetches trending repos      │  │ - Processes additional data │ │  │
│  │  └───────────────────────────────┘  └─────────────────────────────┘ │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                    │                                      │
│                                    ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                   Local State (StatefulWidget)                      │  │
│  │  ┌───────────────────────────┐  ┌───────────────────────────────┐  │  │
│  │  │ User Interface Controls   │  │ Filter Parameters             │  │  │
│  │  │ - scrollController        │  │ - selectTime (daily/weekly)   │  │  │
│  │  │ - _isOpen                 │  │ - selectType (language)       │  │  │
│  │  │ - refreshIndicatorKey     │  │ - selectTimeIndex            │  │  │
│  │  └───────────────────────────┘  │ - selectTypeIndex            │  │  │
│  │                                 └───────────────────────────────┘  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                    │                                      │
│                                    ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                     Global State Flags                             │  │
│  │  ┌───────────────────────────────┐  ┌─────────────────────────────┐ │  │
│  │  │ trendLoadingState (boolean)   │  │ trendRequestedState (bool)  │ │  │
│  │  │ - Tracks loading status       │  │ - Tracks if data requested  │ │  │
│  │  └───────────────────────────────┘  └─────────────────────────────┘ │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                            Data Layer                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                       ReposRepository                                 │ │
│  │  ┌────────────────────────┐       ┌─────────────────────────────────┐ │ │
│  │  │ Network Request        │───┬──▶│ TrendRepositoryDbProvider       │ │ │
│  │  │ - API calls            │   │   │ - Database caching              │ │ │
│  │  └────────────────────────┘   │   │ - Offline data retrieval        │ │ │
│  │                               │   └─────────────────────────────────┘ │ │
│  │                               │                                       │ │
│  │                               │   ┌─────────────────────────────────┐ │ │
│  │                               └──▶│ TrendingRepoModel               │ │ │
│  │                                   │ - Data model for trending repos │ │ │
│  │                                   └─────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                              UI Components                                 │
│  ┌────────────────────────────┐ ┌─────────────────────────┐ ┌───────────┐ │
│  │ TrendTypeModel             │ │ ReposViewModel          │ │ ReposItem │  │
│  │ - Filter options           │ │ - UI data wrapper       │ │ - UI      │ │
│  └────────────────────────────┘ └─────────────────────────┘ └───────────┘ │
└───────────────────────────────────────────────────────────────────────────┘

```

Provider page state management:

```
+-----------------------------------------------------+
|                   App User Interface                 |
+-----------------------------------------------------+
                          |
                          v
+-----------------------------------------------------+
|              RepositoryDetailPage (StatefulWidget)  |
|            with SingleTickerProviderStateMixin      |
+-----------------------------------------------------+
                          |
                          v
+-----------------------------------------------------+
|                   MultiProvider                      |
+-----------------------------------------------------+
        |                                 |
        v                                 v
+------------------+           +-----------------------+
| ReposNetWork     |<----------|  ReposDetailProvider  |
| Provider         |           |                       |
+---------+--------+           +-----------------------+
          |                                |
          |                                |
          v                                v
+-----------------------------------------------------+
|              Repository Data Services               |
| (ReposRepository, IssueRepository)                  |
+-----------------------------------------------------+
          |
          v
+-----------------------------------------------------+
|                Four Tab Pages (Consumers)           |
+-----------------------------------------------------+
    |           |           |           |
    v           v           v           v
+----------+ +----------+ +----------+ +----------+
| Info     | | Readme   | | Issues   | | Files    |
| Page     | | Page     | | Page     | | Page     |
+----------+ +----------+ +----------+ +----------+
    |           |           |           |
    |           |           |           |
    v           v           v           v
+-----------------------------------------------------+
|                GlobalKeys for Tab Access             |
| (infoListKey, readmeKey, issueListKey, fileListKey) |
+-----------------------------------------------------+

```


## Star History Chart

[![Star History Chart](https://api.star-history.com/svg?repos=CarGuo/gsy_github_app_flutter&type=Date)](https://star-history.com/#CarGuo/gsy_github_app_flutter&Date)


![](http://img.cdn.guoshuyu.cn/thanks.jpg)

![](http://img.cdn.guoshuyu.cn/wechat_qq.png)


### LICENSE
```
CarGuo/GSYGithubAppFlutter is licensed under the
Apache License 2.0

A permissive license whose main conditions require preservation of copyright and license notices. 
Contributors provide an express grant of patent rights. 
Licensed works, modifications, and larger works may be distributed under different terms and without source code.
```



​
