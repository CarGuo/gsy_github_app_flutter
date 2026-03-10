# 调试页功能

## 相关文件

- `lib/page/debug/debug_data_page.dart`
- `lib/page/debug/debug_label.dart`
- `lib/common/net/interceptors/log_interceptor.dart`
- `lib/common/logger.dart`

## 当前实现

调试页用于查看开发过程中的：

- HTTP Response
- HTTP Request
- HTTP Error
- Talker 错误日志

并支持复制链接、复制数据、弹出 JSON 查看器。

## 数据流

调试页本身不发起业务请求，而是消费全局日志和拦截器收集到的数据。

## 状态管理

- 页面本地 tab 状态
- 数据由全局日志容器和拦截器静态列表提供

## 高风险点

- 这是辅助调试能力，不应影响线上业务路径
- 改日志结构时要同步看调试页展示
- 大量数据展示和复制逻辑集中在单页内部

## 修改建议

- 仅在需要增强调试体验时修改
- 不要把正式业务依赖绑到调试页上
- 改日志采集字段时，顺带检查调试页是否还能正确显示
