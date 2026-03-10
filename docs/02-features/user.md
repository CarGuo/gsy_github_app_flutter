# 用户页功能

## 相关文件

- `lib/page/user/person_page.dart`
- `lib/page/user/base_person_provider.dart`
- `lib/page/user/base_person_state.dart`
- `lib/common/repositories/user_repository.dart`
- `lib/common/repositories/event_repository.dart`

## 当前实现

用户页负责展示用户或组织的详情页，并根据用户类型展示不同内容：

- 用户信息头部
- 关注/取消关注
- 用户动态
- 组织成员
- 组织信息与荣誉数据

## 数据流

1. 刷新时先拉用户信息
2. 再根据用户类型拉用户动态或组织成员
3. 并行获取关注状态和 honor 数据
4. 头部与列表一起渲染到嵌套下拉页面

## 状态管理

- 页面主体基于 `BasePersonState`
- honor 相关使用 provider
- 页面本地 state 保存关注状态、用户信息等

## 高风险点

- 用户和组织走的列表数据源不同
- 关注状态、用户信息、动态列表是多条链路
- `BasePersonState` 和 provider 共同参与页面行为

## 修改建议

- 用户页展示问题优先改 `person_page.dart` 与 widget
- honor 或头部共享逻辑再看 `base_person_provider.dart`
- 数据源问题分别看 `UserRepository` 与 `EventRepository`
