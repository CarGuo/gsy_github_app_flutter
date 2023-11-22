![](./logo.png)

## An open source Github client App developed by Flutter，Provide richer functionality and comparison with the same program by other language:

[![](http://img.cdn.guoshuyu.cn/WechatIMG65.jpeg)](https://item.jd.com/12883054.html)

* ### Weex Version （ https://github.com/CarGuo/GSYGithubAppWeex ）
* ### ReactNative Version （ https://github.com/CarGuo/GSYGithubApp ）
* ### Android Kotlin Version（ https://github.com/CarGuo/GSYGithubAppKotlin ）

```
Based on Flutter development, it adapts Android and IOS. At present, the first edition is in continuous improvement.

The purpose of the project is to facilitate personal daily maintenance and access to Github, better immerse in the mutual base between coders, Github is your home.

The project is also suitable for Flutter's hands-on learning, covering the use of various frameworks, interaction with native students and so on.

With the use and feedback of the project, will user experience and function optimization be updated and improved from time to time? Welcome to ask questions.
```
-----


![](http://img.cdn.guoshuyu.cn/WeChat-Code)


## Chinese Articles

- ## [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
- ## [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)

----
- ## [Flutter 独立简单学习演示项目](https://github.com/CarGuo/gsy_flutter_demo)
- ## [Flutter 完整开发实战详解 Gitbook 预览下载](https://github.com/CarGuo/gsy_flutter_book)
- ## [所有运行问题请点击这里](https://github.com/CarGuo/gsy_github_app_flutter/issues/13)

----


[![GitHub stars](https://img.shields.io/github/stars/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/network)
[![GitHub issues](https://img.shields.io/github/issues/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/issues)
[![GitHub license](https://img.shields.io/github/license/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/LICENSE)

### Operation instructions

1. Configure the Flutter development environment (Tag of the current version of Flutter SDK  **3.16** ).

2. Clone code, execute `Packages get'to install third-party packages.


> ### 3. Emphasis: You need to create a `ignoreConfig.dart'file in the lib/common/config/directory by yourself, and then enter the Github client_id and client_secret you applied for.

     class NetConfig {
       static const CLIENT_ID = "xxxx";

       static const CLIENT_SECRET = "xxxxxxxxxxx";
     }


   [      Register Github APP ](https://github.com/settings/applications/new) 。

### 3、 Github App  Authorization callback URL must be `gsygithubapp://authed`

<div>
<img src="./register0.png" width="426px"/>
<img src="./register1.jpg" width="426px"/>
</div>

4、Be careful

>### Local Flutter SDK version  3.16 or more. 2. Does the third-party package version in pubspec. yaml correspond to the third-party package version in pubspec. lock?

### Download

#### Apk Link： [Apk Link](https://www.pgyer.com/guqa)


| 类型          | 二维码                                      |
| ----------- | ---------------------------------------- |
| **Apk**  | ![](./download.png) |
| **GooglePlay**  | ![](./googleplay.png) |
| **iOS null** | ![](./ios_wait.png) |



## Project Structure

![](./framework2.png)

![](./folder.png)




### Demo

![](./ios.gif)

![](./theme.gif)

<img src="./1.jpg" width="426px"/>

<img src="./2.jpg" width="426px"/>

<img src="./3.jpg" width="426px"/>


### Third-party framework

>Current Flutter SDK version **3.16**

| 库                          | 功能             |
| -------------------------- | -------------- |
| **dio**                    | **net**       |
| **shared_preferences**     | **local storage**     |
| **fluttertoast**           | **toast**      |
| **flutter_redux**          | **redux**      |
| **device_info**            | **device info**       |
| **connectivity**           | **network status**       |
| **flutter_markdown**       | **markdown parse** |
| **json_annotation**        | **json**     |
| **json_serializable**      | **json**     |
| **url_launcher**           | **intent**    |
| **iconfont**               | **ttf**       |
| **share**                  | **share**       |
| **flutter_spinkit**        | **loading**      |
| **get_version**            | **version**       |
| **flutter_webview_plugin** | **webview** |
| **sqflite**                | **sqlite**        |
| **flutter_statusbar**      | **status bar**        |
| **flutter_svg**            | **svg**        |
| **photo_view**             | **preview**       |
| **flutter_slidable**       | **slide view**         |
| **flutter_cache_manager**  | **cache manager**       |
| **path_provider**          | **path**       |
| **permission_handler**     | **permission**         |
| **scope_model**            | **like redux**    |
| **lottie**                 | **svg**    |
| **flare**                  | **flare**    |


![](https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/thanks.jpg)


### LICENSE
```
CarGuo/GSYGithubAppFlutter is licensed under the
Apache License 2.0

A permissive license whose main conditions require preservation of copyright and license notices.
Contributors provide an express grant of patent rights.
Licensed works, modifications, and larger works may be distributed under different terms and without source code.
```



​
