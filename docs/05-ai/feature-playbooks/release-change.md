# 功能模板：修改 Release 相关功能

## 开始前先读

1. `docs/02-features/release.md`
2. `docs/04-quality/smoke-matrix.md`
3. `lib/page/AGENTS.md`

## 优先定位

- 页面交互与 tab：`lib/page/release/release_page.dart`
- 数据获取：`ReposRepository.getRepositoryReleaseRequest`

## 修改策略

- release 和 tag 两条链路都要测
- 内嵌 HTML 预览和外部链接打开都要测
- tab 切换后会清空并重刷列表

## 最低验证

1. 进入 release 页面
2. release 列表可加载
3. 切到 tag 列表可加载
4. 点击 release 项查看 HTML
5. 长按项可外部打开链接

## 收尾步骤

Release 页面改动完成后，先由新的 reviewer subagent 审查 release/tag 双链路，再对外汇报完成。
