# 功能模板：修改调试页相关功能

## 开始前先读

1. `docs/02-features/debug.md`
2. `lib/common/net/AGENTS.md`

## 优先定位

- 调试页 UI：`lib/page/debug/debug_data_page.dart`
- 日志数据结构：`log_interceptor.dart`、`common/logger.dart`

## 修改策略

- 调试页只服务开发和诊断，不要引入业务依赖
- 改日志字段时同步检查调试页展示
- 复制和 JSON 弹窗链路都要能工作

## 最低验证

1. 调试页可打开
2. 四个 tab 可切换
3. 列表项可点击查看 JSON
4. 长按和双击复制正常

## 收尾步骤

调试页改动完成后，仍需先经过新的 reviewer subagent 审查，再对外汇报结果。
