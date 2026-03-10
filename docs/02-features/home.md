# 首页容器功能

## 相关文件

- `lib/page/home/home_page.dart`
- `lib/page/home/widget/home_drawer.dart`
- `lib/page/dynamic/dynamic_page.dart`
- `lib/page/trend/trend_page.dart`
- `lib/page/my_page.dart`

## 当前实现

首页不是单一业务页，而是应用主容器，负责：

- 三个主 tab 切换
- 搜索入口
- drawer 入口
- 双击 tab 回到顶部
- Android 返回键回桌面

## 数据流

首页主要负责导航和容器调度，本身不直接承接业务数据。
业务数据由各 tab 页面自己拉取。

## 状态管理

- 主要是页面容器本地状态
- 通过 `GlobalKey` 驱动各 tab 的 `scrollToTop`

## 高风险点

- 改 tab 结构会影响动态页、趋势页、我的页面联动
- 搜索入口依赖右上角控件位置计算
- 返回键行为是首页特有容器逻辑

## 修改建议

- 首页问题优先限制在容器和导航层
- 不要把某个 tab 的业务逻辑加回首页
- 改搜索入口时要验证动画起点和跳转
