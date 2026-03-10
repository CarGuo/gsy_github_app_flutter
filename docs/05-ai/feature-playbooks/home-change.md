# 功能模板：修改首页容器相关功能

## 开始前先读

1. `docs/02-features/home.md`
2. `docs/04-quality/smoke-matrix.md`
3. `lib/page/AGENTS.md`

## 优先定位

- tab 容器和搜索入口：`lib/page/home/home_page.dart`
- drawer：`lib/page/home/widget/home_drawer.dart`

## 修改策略

- 首页只负责容器和导航，不要承接具体业务逻辑
- 改 tab 结构时，同时验证 dynamic/trend/my 三个入口
- 改搜索入口时，要验证右上角位置计算与动画起点

## 最低验证

1. 首页可正常进入
2. 三个 tab 可切换
3. 双击 tab 可回到顶部
4. 搜索入口可打开搜索页
5. Android 返回键行为符合预期

## 收尾步骤

首页容器相关改动在完成验证后，必须先经过新的 reviewer subagent 审查。
这是容器层改动，不应由 author 自己直接宣布完成。
