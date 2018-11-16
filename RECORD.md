

https://github.com/flutter/plugins/tree/master/packages/webview_flutter  
未发布的





1、

GSYVideoPlayer 1604 的issue，会触发`inline_parser.dart`在 `List<Node> parse() ` 正则解析出现问题，等待 flutter issue 19341

2、

keyboard bot bring up

https://github.com/flutter/flutter/issues/19810
https://github.com/flutter/flutter/issues/19644





### String 字符串

在哪里存储字符串? 如何存储不同的语言
目前，最好的做法是创建一个名为Strings的类
class Strings{
  static String welcomeMessage = "Welcome To Flutter";
}
然后在你的代码中，你可以像访问你的字符串一样：new Text(Strings.welcomeMessage)

### Json序列化

生成序列化模板
flutter packages pub run build_runner build --delete-conflicting-outputs


### 配合AutomaticKeepAliveClientMixin可以keep住tab

### 如何主动刷新refresh，如何设置appbar上的leading和bottom，如何设置tabbar的live

//升级到0.5.7 对三个以上tab还是有问题，TabBarView放弃，使用PageView，实现两个control同步，GlobalKey也没问题了。
https://github.com/flutter/flutter/issues/19809
https://github.com/flutter/flutter/issues/11895 tab alive
_debugUltimatePreviousSiblingOf
GlobalKey可以记录state，但是需要跟随build创建
https://stackoverflow.com/questions/49862572

```
if you use AutomaticKeepAliveClientMixin to keep alive page item,you can't write like this:

PageView(
controller: _pageController,
onPageChanged: (index) {
onPageChanged(index);
},
children: [NewsList(),Text('page1'),Text('page2'),Text('page3')],
),

you should write like this:

List _list = [
NewsList(),
Text('page1'),
Text('page2'),
Text('page3')
];
PageView(
controller: _pageController,
onPageChanged: (index) {
onPageChanged(index);
},
children:_list,
), 
```


### webView

https://github.com/flutter/flutter/issues/19030 没有webview，残念
https://github.com/dart-flitter/flutter_webview_plugin/issues/23
https://github.com/flutter/flutter/issues/730


### 兼容性 

flutter 的跨平台见兼容性意外的话，得益于flutter engine，skia的渲染，只需要canvas
所以第一次运行意外的没有兼容问题，特别是有生之年在ios上看到完全一模一样的下拉刷新


### dialog上黄色线
https://stackoverflow.com/questions/47114639/yellow-lines-under-text-widgets-in-flutter
Dialog中，没使用Scaffold ，导致文本有黄色溢出线提示，可以使用Material ，color或者type为透明


### 热更新

hotload很有优势。

热更新的新包如果包含了原生代码，需要停止后重新运行哦。

### 动画、本地通讯

### upgrade 和 get的区别，在于lock 在yaml线下，^代表大于等于哦

### redux 下切换主题 

### 谷歌推荐redux

https://blog.csdn.net/yaoliangjun306/article/details/77824136
flutter 运行ios项目失败 'shared_preferences/SharedPreferencesPlugin.h' file not found

flutter 真机测试
https://blog.csdn.net/hekaiyou/article/details/52874796?locationNum=4&fps=1

///ios编译失败
https://github.com/flutter/flutter/issues/19241#issuecomment-404601754

https://github.com/flutter/flutter/issues/18305
```
open ios/Runner.xcodeproj
I checked Runner/Pods is empty in Xcode sidebar.
drop Pods/Pods.xcodeproj into Runner/Pods.
"Valid architectures" to only "arm64" (I removed armv7 armv7s) #13364 
```

你需要选flutter build ios
之后它会修改你的Podfile.lock文件指向


https://github.com/facebook/react-native/issues/20712 react-native 0.57.0-rc.0 问题
https://github.com/facebook/react-native/issues/20710 react-native 0.57.0-rc.0 问题



gsyvideoplayer 1407 issue 显示问题