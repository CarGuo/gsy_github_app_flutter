# 功能模板：修改用户页相关功能

## 开始前先读

1. `docs/02-features/user.md`
2. `docs/04-quality/smoke-matrix.md`
3. `lib/page/AGENTS.md`

## 优先定位

- 页面展示与交互：`lib/page/user/person_page.dart`
- 共享头部与 honor：`lib/page/user/base_person_provider.dart`
- 数据请求：`UserRepository` / `EventRepository`

## 修改策略

- 先判断当前展示对象是用户还是组织
- 关注状态、用户信息、列表数据是多条链路，分别验证
- 不要把组织分支和普通用户分支混在一起改

## 最低验证

1. 进入用户页
2. 头部信息正常
3. 用户动态或组织成员正常展示
4. 关注/取消关注行为正常
5. 返回链路正常

## 收尾步骤

用户页改动完成后，先用新的 reviewer subagent 审查用户分支和组织分支，再对外汇报完成。
