# 线上性能监控与版本趋势

2026-10-23：在应用的中央组合位置接入，避免业务页散落埋点、动态路由泄漏和错误的网络耗时口径。此接入用于前台聚合性能趋势，不收集请求内容、用户/仓库名称或设备标识。

## 构建配置

`main.dart` 与 `main_prod.dart` 都调用 `GsyPerformanceTelemetry.instance.start()`。默认未设置 `MONITOR_ENDPOINT`，不会读取 ingest 凭据、创建监控实例或向本地服务发送数据。线上由发布流水线设置 HTTPS OTLP logs 入口和独立的写入凭据。采用现有构建期 define 配置，不改 env 生成文件或 OAuth 配置。

由本地/CI 私密配置提供 `env.local`（仓库已忽略；以下均为占位值）：

```json
{
  "MONITOR_ENDPOINT": "https://telemetry.example.com/v1/logs",
  "MONITOR_INGEST_TOKEN": "REPLACE_WITH_SCOPED_INGEST_TOKEN",
  "MONITOR_FLUTTER_VERSION": "3.47.2"
}
```

```sh
fvm flutter build apk --release --dart-define-from-file=env.local
```

域名必须替换为实际部署入口。2026-10-23：中央配置在激活前校验鉴权策略，并通过 `HttpOtlpTransport(authorization: ...)` 的每次发送回调产生 `Authorization: Bearer <ingest token>`；SDK 使用独立 HTTP 客户端、校验证书且拒绝重定向。凭据只进入发送请求头，不进入监控身份、事件、spool 或日志。

Collector 必须验证此 token，且只授予监控写入权限；不能使用 GitHub 登录 token、OAuth client secret、查询账户或管理凭据。构建期 token 会随客户端分发，不能当作只有服务端知道的长期秘密：发布侧需要限定权限、有效期、撤销/轮换和流量限制。当前默认来源是编译期值，替换该值需要重新构建；每次发送回调保留以后接入短期凭据提供器的边界。本轮不新增登录或凭据签发业务。

HTTPS 缺少/无效 token 会明确报激活失败。release 禁止 `MONITOR_ALLOW_INSECURE_LOOPBACK`；非 release 的显式 HTTP loopback 验证也禁止携带凭据。Bearer 请求头格式遵循 [RFC 6750 §2.1](https://www.rfc-editor.org/rfc/rfc6750#section-2.1)。此接入不表示生产后端已经部署完成。

| 配置 | 含义 |
|---|---|
| `MONITOR_ENDPOINT` | 完整 HTTPS OTLP logs URL；为空时关闭 |
| `MONITOR_INGEST_TOKEN` | HTTPS 必填的独立 ingest token，值不带 `Bearer ` 前缀；本地明文验证必须为空 |
| `MONITOR_FLUTTER_VERSION` | CI 实际使用的 Flutter SDK 版本，未提供为 `unknown` |
| `MONITOR_DEVICE_CLASS` | 可选的稳定硬件分组覆盖；未设置时使用平台 model，并区分真机与模拟器 |
| `MONITOR_RUN_ID` | 为空是 `daily`；非空是隔离的 `test` 验证运行 |
| `MONITOR_ALLOW_INSECURE_LOOPBACK` | 仅非 release 的显式无凭据本地验证允许 HTTP loopback；线上不设置 |

应用 ID、`version+buildNumber` 来自 `PackageInfo`，平台和构建模式来自实际运行环境。硬件只使用 Android `model`、iOS `utsname.machine` 与 `isPhysicalDevice`；不读取用户设备名或设备 ID。标签由 `physical-`/`simulator-`、可选的有界 ASCII 可读型号和完整原始型号的 SHA-256 前 128 位组成，最长 64 字符。全中文等非 ASCII 型号仍有稳定摘要，长型号即使可读部分相同，尾部差异也参与摘要；没有机型对照表。

包元数据与硬件信息并行异步获取，不阻塞 `runApp`。失败在本地日志显式报告固定消息、异常类型与堆栈，不输出配置/异常原文，也不把失败转换为启用成功。激活后重放当前可见导航状态，避免错过早期 Navigator 回调。若激活已经错过启动边界，SDK 的 late-initialization 诊断必须在验收中解释，不能将其当作完整冷启动样本。

## 接线与统计口径

- REST：`HttpManager` 包装实际 `Dio.httpClientAdapter`，保留原有拦截器、缓存、上传与取消机制。计时从 adapter `fetch` 开始到收到响应头，包含该阶段的连接/上传时间，排除响应体下载和转换；不使用 Dio `onResponse` 充当响应头边界。
- GraphQL：`Client` 中的 `HttpLink` 使用 `MonitoredHttpClient`。它与 Dio 共用 SDK 的请求计时 token，客户端可以先于监控激活创建。请求方法、状态组、起始场景与耗时以外的请求内容不传入监控。
- 导航：根与右栏 Navigator 使用独立 observer。中央边界把既有动态路由映射为固定业务类别，参数被丢弃；首页三个 tab 分别为 `home/dynamic`、`home/trend`、`home/my`。全屏路由覆盖右栏；返回、切 tab 和折叠导致右栏移除时恢复实际可见场景。仓库详情内部 tab 仍归入 `repos`，没有逐 widget 事件采集。

只有上述主 Dio 与 GraphQL HTTP 链路被此接入覆盖。WebView、图片库、插件内部网络和独立创建的其他客户端不在这一网络指标范围。自定义 Dio adapter 若在返回 `ResponseBody` 前缓存完整响应体，需要先验证其边界，不能直接沿用响应头指标名称。

## 固定 SDK 发布快照

2026-10-23：`pubspec.yaml` 的 SDK 与 Dio adapter 均指向仓库内 `vendor/flutter_performance_monitor/packages/` 的固定发布快照。克隆 GSY 即带有同一份 SDK 输入，既不依赖开发机相邻路径，也不要求某个尚未推送的 Git revision 可以下载；`pubspec.lock` 保留其余原有版本。

`vendor/flutter_performance_monitor/release.json` 记录来源仓库、完整已提交 source revision、逐文件 SHA-256 和整体内容 SHA-256。快照仅含两个包的发布源码、平台插件和发布文档，不携带 example、测试、build、`.dart_tool` 或本地配置。

当前来源提交为 `17f08d0569d2b63d836d1757acbfb1cf6299555b`。完整 SDK 操作手册、后端部署与安全说明见[该提交的来源文档](https://github.com/CarGuo/flutter_performance_monitor/tree/17f08d0569d2b63d836d1757acbfb1cf6299555b/docs)；来源提交尚未推送时，可在来源仓库检出同一 revision 查看。vendor 中保留的包 README 为来源原文，其 monorepo 相对 `docs/` 链接对应上述来源文档，并不指向 GSY 的 `docs/`；不能用开发机绝对路径替代。

```sh
fvm dart run tool/telemetry/sdk_snapshot.dart
```

该命令校验当前实际依赖文件与 release manifest 完全一致。更新 SDK 时先在来源仓库完成审查、验证和提交，再从指定 commit 冻结，不读取其未提交工作区：

```sh
fvm dart run tool/telemetry/sdk_snapshot.dart --freeze /path/to/flutter_performance_monitor FULL_COMMIT_SHA
fvm flutter pub get
```

随后一起审查快照、manifest 与依赖锁变化，重新执行 GSY 的 analyze、全量测试和 release APK 构建。禁止在 vendor 中直接修 SDK；修复应回到来源仓库后重新冻结。

## 本地完整链路验收

```sh
fvm flutter build apk --profile --target-platform=android-arm64 \
  --dart-define=MONITOR_ENDPOINT=http://127.0.0.1:4318/v1/logs \
  --dart-define=MONITOR_ALLOW_INSECURE_LOOPBACK=true \
  --dart-define=MONITOR_RUN_ID=gsy-validation-20261023 \
  --dart-define=MONITOR_FLUTTER_VERSION=3.47.2
```

这条命令只构建，不安装或清数据；不读取正式 `env.local` 或添加 token。带 token 的验收必须使用 HTTPS。保留已有登录态的装机应先确认应用 ID、签名相同且 versionCode 不降级，再显式执行 `adb install -r`；失败立即停止，禁止通过卸载、清数据或 Flutter 自动重装重试。启动已安装应用后使用 `flutter attach`，不走普通 `flutter run/install/drive` 安装或卸载流程。Android 需要先设置对应端口的 `adb reverse`；真机的 `127.0.0.1` 不代表开发电脑。性能与完整链路验收使用真机 profile；模拟器数据不得混入性能结论。

验收需要同时核对：真实 REST/GraphQL 网络事件、根/右栏/首页 tab 场景、后台恢复与 flush、ClickHouse 中相同 run ID 的落库行，以及 Grafana/SQL 的版本和硬件过滤。应用侧可从 `GsyPerformanceTelemetry.instance.monitor` 读取 `currentScene`、`frameStats`、`diagnostics`、`pendingBatches` 并显式 `flush()`。监控实例为空时应先检查 endpoint 和初始化失败日志。

通过 `test` run ID 后还需验证无 run ID 的 `daily` 数据与测试数据隔离，使用两个实际版本构建对比同平台、同模式、同硬件和同场景样本。只有本地聚合和 SDK 测试通过，不足以宣称线上部署可用。设备截图、运行错误和折叠/展开两种布局证据遵循仓库的运行验收要求。
