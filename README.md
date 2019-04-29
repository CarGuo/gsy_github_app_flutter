![](https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/logo.png)


[![GitHub stars](https://img.shields.io/github/stars/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/network)
[![GitHub issues](https://img.shields.io/github/issues/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/issues)
[![GitHub license](https://img.shields.io/github/license/CarGuo/GSYGithubAppFlutter.svg)](https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/LICENSE)

### [English Readme](https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/README_EN.md)

## 一款跨平台的开源Github客户端App，提供更丰富的功能，更好体验，旨在更好的日常管理和维护个人Github，提供更好更方便的驾车体验～～Σ(￣。￣ﾉ)ﾉ。项目涉及各种常用控件、网络、数据库、设计模式、主题切换、多语言、Redux等。在开发学习过程中，提供丰富的同款对比：

* ### 同款Weex版 （ https://github.com/CarGuo/GSYGithubAppWeex ）
* ### 同款ReactNative版 （ https://github.com/CarGuo/GSYGithubApp ）
* ### 同款Android Kotlin版本（ https://github.com/CarGuo/GSYGithubAppKotlin ）

```
基于Flutter开发，适配Android与IOS。目前初版，持续完善中。

项目的目的是为方便个人日常维护和查阅Github，更好的沉浸于码友之间的互基，Github就是你的家。

项目同时适合Flutter的练手学习，覆盖了各种框架的使用，与原生的交互等。

随着项目的使用情况和反馈，将时不时根据更新并完善用户体验与功能优化吗，欢迎提出问题。
```
-----


## 最近回顾项目，发现了不少问题，目前优化调整中：

- Dao层其实可以定制到Bloc层，隔离数据逻辑（已修改部分，但是写Bloc好懒）。
- bloc 搭配 StreamBuilder （但是改起来好懒怎么办？）
- 调整 redux，已经完成全局部分调整，是否使用 redux 做局部状态管理？（但是改起来好懒怎么办？）
- scoped_model 已应用部分（但是改起来好懒怎么办？）
- 自定义图片缓存（DefaultCacheManager居然用数据库存ID）
- 一些布局可以简化重构（但是改起来好懒怎么办？）


```!

因为是偏学习项目，所以项目里会才有各式各样的模式和库，请不要介意

1、 TrendPage ： 目前采用纯 bloc 的 rxdart(stream) + streamBuilder 模式效果

```

### [目前各种主流状态管理演示Demo](https://github.com/CarGuo/state_manager_demo)


## 相关文章

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



### 编译运行流程

1、配置好Flutter开发环境(目前Flutter SDK 版本 **v1.5.8** 的 Tag )，可参阅 [【搭建环境】](https://flutterchina.club)。

2、clone代码，执行`Packages get`安装第三方包。(因为某些不可抗力原因，国内可能需要设置代理: [代理环境变量](https://flutterchina.club/setup-windows/))

>### 3、重点：你需要自己在lib/common/config/目录下 创建一个`ignoreConfig.dart`文件，然后输入你申请的Github client_id 和 client_secret。

     class NetConfig {
       static const CLIENT_ID = "xxxx";
     
       static const CLIENT_SECRET = "xxxxxxxxxxx";
     }


   [      注册 Github APP 传送门](https://github.com/settings/applications/new)，当然，前提是你现有一个github账号(～￣▽￣)～ 。

<div>
<img src="https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/register0.jpg" width="426px"/>
<img src="https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/register1.jpg" width="426px"/>
</div>

4、运行之前请注意下

>### 1、本地Flutter SDK 版本 v1.5.8 以上。2、pubspec.yaml 中的第三方包版本和 pubspec.lock 中的是否对应的上



## 项目结构图

![](https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/framework2.png)

![](https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/folder.png)

### 下载

#### Apk下载链接： [Apk下载链接](https://www.pgyer.com/vj2B)


| 类型          | 二维码                                      |
| ----------- | ---------------------------------------- |
| **Apk二维码**  | ![](https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/download.png) |
| **IOS暂无下载** | [ipa下载地址，需自己改签](https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/GSYGithubFllutter-1.3.0.ipa) ![](https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/ios_wait.png) |




### 常见问题

* 如果包同步失败，一般都是因为没设置包代理，可以参考：[环境变量问题](https://github.com/CarGuo/GSYGithubAppFlutter/issues/13)



### 示例图片

![](https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/ios.gif)

![](https://raw.githubusercontent.com/CarGuo/GSYGithubAppFlutter/master/theme.gif)

<img src="https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/1.jpg" width="426px"/>

<img src="https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/2.jpg" width="426px"/>

<img src="https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/3.jpg" width="426px"/>


### 第三方框架

>当前 Flutter SDK 版本 v1.5.8

| 库                          | 功能             |
| -------------------------- | -------------- |
| **dio**                    | **网络框架**       |
| **shared_preferences**     | **本地数据缓存**     |
| **fluttertoast**           | **toast**      |
| **flutter_redux**          | **redux**      |
| **device_info**            | **设备信息**       |
| **connectivity**           | **网络链接**       |
| **flutter_markdown**       | **markdown解析** |
| **json_annotation**        | **json模板**     |
| **json_serializable**      | **json模板**     |
| **url_launcher**           | **启动外部浏览器**    |
| **iconfont**               | **字库图标**       |
| **share**                  | **系统分享**       |
| **flutter_spinkit**        | **加载框样式**      |
| **get_version**            | **版本信息**       |
| **flutter_webview_plugin** | **全屏的webview** |
| **sqflite**                | **数据库**        |
| **flutter_statusbar**      | **状态栏**        |
| **flutter_svg**            | **svg**        |
| **photo_view**             | **图片预览**       |
| **flutter_slidable**       | **侧滑**         |
| **flutter_cache_manager**  | **缓存管理**       |
| **path_provider**          | **本地路径**       |
| **permission_handler**     | **权限**         |
| **scope_model**            | **状态管理和共享**    |
| **lottie**                 | **svg动画**    |

### 进行中：

[版本更新说明](https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/VERSION.md)


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
