![](https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/logo.png)

## An open source Github client App developed by Flutter，Provide richer functionality and comparison with the same program by other language:

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

### [state manager demo](https://github.com/CarGuo/state_manager_demo)


## Chinese Articles

* ### [Flutter 完整开发实战详解(一、Dart 语言和 Flutter 基础)](https://juejin.im/entry/5b631e3e51882519861c2ef1 )
* ### [Flutter 完整开发实战详解(二、快速实战篇)](https://juejin.im/entry/5b685bd4e51d451994602cae )
* ### [Flutter 完整开发实战详解(三、打包填坑篇)](https://juejin.im/entry/5b6fd5ee6fb9a009d36a4104 )
* ### [Flutter 完整开发实战详解(四、Redux、主题、国际化)](https://juejin.im/post/5b79767ff265da435450a873 )
* ### [Flutter 完整开发实战详解(五、深入探索)](https://juejin.im/post/5bc450dff265da0a951f032b )
* ### [Flutter 完整开发实战详解(六、 深入Widget原理)](https://juejin.im/post/5c7e853151882549664b0543 )
* ### [Flutter 完整开发实战详解(七、 深入布局原理)](https://juejin.im/post/5c8c6ef7e51d450ba7233f51 )
* ### [Flutter 完整开发实战详解(八、 实用技巧与填坑)](https://juejin.im/post/5c9e328251882567b91e1cfb)
* ### [Flutter 完整开发实战详解(九、 深入绘制原理)](https://juejin.im/post/5ca0e0aff265da309728659a)
* ### [Flutter 完整开发实战详解(十、 深入图片加载流程)](https://juejin.im/post/5cb1896ce51d456e63760449)
* ### [Flutter 完整开发实战详解(十一、全面深入理解Stream)](https://juejin.im/post/5cc2acf86fb9a0321f042041)
* ### [Flutter 完整开发实战详解(十二、全面深入理解状态管理设计)](https://juejin.im/post/5cc816866fb9a03231209c7c)




[![GitHub stars](https://img.shields.io/github/stars/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/network)
[![GitHub issues](https://img.shields.io/github/issues/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/issues)
[![GitHub license](https://img.shields.io/github/license/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/LICENSE)

### Operation instructions

1. Configure the Flutter development environment (Tag of the current version of Flutter SDK ** v1.5.8 **).

2. Clone code, execute `Packages get'to install third-party packages.


> ### 3. Emphasis: You need to create a `ignoreConfig.dart'file in the lib/common/config/directory by yourself, and then enter the Github client_id and client_secret you applied for.

     class NetConfig {
       static const CLIENT_ID = "xxxx";
     
       static const CLIENT_SECRET = "xxxxxxxxxxx";
     }


   [      Register Github APP ](https://github.com/settings/applications/new) 。

<div>
<img src="https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/register0.jpg" width="426px"/>
<img src="https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/register1.jpg" width="426px"/>
</div>

4、Be careful

>### Local Flutter SDK version v1.5.8 or more. 2. Does the third-party package version in pubspec. yaml correspond to the third-party package version in pubspec. lock?


## Project Structure

![](https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/framework2.png)

![](https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/folder.png)

### 下载

#### Apk Download Link： [ Apk Download Link](https://www.pgyer.com/vj2B)


| Type          | Apk QR code                                    |
| ----------- | ---------------------------------------- |
| **Apk QR code**  | ![](https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/download.png) |
| **IOS Null** |  |




### Demo

![](https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/ios.gif)

![](https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/theme.gif)

<img src="https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/1.jpg" width="426px"/>

<img src="https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/2.jpg" width="426px"/>

<img src="https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/3.jpg" width="426px"/>


### Third-party framework

>Current Flutter SDK version v1.5.8

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


<img src="https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/thanks.jpg" width="426px"/>


### LICENSE
```
CarGuo/GSYGithubAppFlutter is licensed under the
Apache License 2.0

A permissive license whose main conditions require preservation of copyright and license notices. 
Contributors provide an express grant of patent rights. 
Licensed works, modifications, and larger works may be distributed under different terms and without source code.
```



​    
