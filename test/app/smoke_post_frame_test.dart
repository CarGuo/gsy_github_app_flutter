import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/app.dart' show navKey, smokePostFrame;

/// [smokePostFrame] 的分支契约守约（对应 commit 8106529 / 661bfa7 的 R3 修改）。
///
/// 为什么落 test 而不是每次靠真机注入验证：
/// - 真机自测（`tool/ai/smoke/evidence/8106529_r3_selftest/`）只能覆盖 app
///   停在 `SchedulerPhase.idle` 时的两条 idle 分支——因为 evaluate 排队时
///   isolate 大概率就是 idle，post-frame 分支很难被真机自然触发；
/// - post-frame 分支和 navKey null 分支必须靠可控 scheduler 单测来保证，
///   否则永远处于"实现存在但没验过"的灰色地带；
/// - AGENTS.md「稀有分支覆盖率无法靠真机保证时，优先加模型层单测 +
///   真实 JSON fixture」条款直接适用（此处不需要 fixture，纯控制流）。
///
/// 覆盖 4 条分支：
/// 1. navKey.currentContext 为 null → 早退返回 null，不抛
/// 2. idle path, sync throw → FlutterError.reportError('idle path, sync throw')
///    + Future.error 上抛（同步 throw 走 try/catch 分支）
/// 3. idle path, async reject → FlutterError.reportError('idle path, async reject')
///    + Future 保持 error 状态（catchError 分支 rethrow）
/// 4. post-frame path → FlutterError.reportError('post-frame path')
///    + Completer.completeError（非 idle 时走 postFrameCallback 分支）
///
/// 每个 case 都用 [_hookFlutterErrorInsideTest] 在 test 内部（binding
/// 已经装完 onError 之后）chain 一层 hook，抓下 [FlutterErrorDetails]
/// 用于对 `library` / `context.description` / `exception` 三个字段做严格断言。
///
/// 为什么不用 setUp 装 hook：flutter_test 的 [TestWidgetsFlutterBinding.runTest]
/// 是在每个 `testWidgets` 内部装 [FlutterError.onError] 的，时机在 setUp 之后。
/// setUp 装的 hook 会被 binding 装的覆盖，抓不到东西。
void main() {
  group('smokePostFrame — navKey null 分支', () {
    testWidgets('navKey 未挂到 MaterialApp 时早退，返回 null 且不抛', (tester) async {
      final captured = _hookFlutterErrorInsideTest();
      // 不 pump 任何持有 navKey 的 widget → navKey.currentContext 恒为 null
      // 但仍需要给 tester 一个 pump 目标，不然 binding 抱怨"没 root widget"
      await tester.pumpWidget(const SizedBox());

      final result = await smokePostFrame<Object?>(
        'navkey_null_test',
        (ctx) async => 'should not be called',
      );

      expect(result, isNull,
          reason: 'navKey.currentContext == null 时应早退，返回 Future(null)');
      expect(captured, isEmpty,
          reason: '早退不是异常，不应触发 FlutterError.reportError');
    });
  });

  group('smokePostFrame — idle path', () {
    testWidgets('sync throw：走 try/catch 分支 → reportError + Future.error',
        (tester) async {
      await _pumpWithNav(tester);
      await tester.pump();
      expect(SchedulerBinding.instance.schedulerPhase, SchedulerPhase.idle,
          reason: '前置：确认 pump 结束后 scheduler 回到 idle，才能命中 idle 分支');

      final captured = _hookFlutterErrorInsideTest();
      final future = smokePostFrame<Object?>(
        'm4_sync_throw_ut',
        (ctx) => throw Exception('sync throw from ut'),
      );

      await expectLater(
        future,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'toString',
          contains('sync throw from ut'),
        )),
      );

      expect(captured, hasLength(1),
          reason: 'idle path sync throw 分支应触发一次 reportError');
      final d = captured.single;
      expect(d.library, 'gsy smoke');
      expect(d.context?.toDescription(),
          'while running m4_sync_throw_ut (idle path, sync throw)');
      expect((d.exception as Exception).toString(),
          contains('sync throw from ut'));
    });

    testWidgets('async reject：走 future.catchError 分支 → reportError + Future 保持 error',
        (tester) async {
      await _pumpWithNav(tester);
      await tester.pump();
      expect(SchedulerBinding.instance.schedulerPhase, SchedulerPhase.idle);

      final captured = _hookFlutterErrorInsideTest();
      final future = smokePostFrame<Object?>(
        'm4_async_reject_ut',
        (ctx) => Future<Object?>.error(Exception('async reject from ut')),
      );

      await expectLater(
        future,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'toString',
          contains('async reject from ut'),
        )),
      );

      expect(captured, hasLength(1),
          reason: 'idle path async reject 分支应触发一次 reportError');
      final d = captured.single;
      expect(d.library, 'gsy smoke');
      expect(d.context?.toDescription(),
          'while running m4_async_reject_ut (idle path, async reject)');
      expect((d.exception as Exception).toString(),
          contains('async reject from ut'));
    });

    testWidgets('idle path 正常返回：不触发 reportError', (tester) async {
      await _pumpWithNav(tester);
      await tester.pump();
      expect(SchedulerBinding.instance.schedulerPhase, SchedulerPhase.idle);

      final captured = _hookFlutterErrorInsideTest();
      final result = await smokePostFrame<int>(
        'm4_idle_ok',
        (ctx) async => 42,
      );

      expect(result, 42);
      expect(captured, isEmpty,
          reason: '正常返回不该走任何 reportError 分支');
    });
  });

  group('smokePostFrame — post-frame path', () {
    testWidgets('非 idle 期间调用：排入 postFrameCallback，action 在下一帧末跑到',
        (tester) async {
      await _pumpWithNav(tester);
      await tester.pump();

      final captured = _hookFlutterErrorInsideTest();
      Future<int?>? nested;
      SchedulerPhase? phaseInsideCallback;
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        phaseInsideCallback = SchedulerBinding.instance.schedulerPhase;
        nested = smokePostFrame<int>(
          'm4_postframe_ok',
          (ctx) async => 7,
        );
        // 立即挂一个 no-op error listener，避免 nested Future 成为
        // "unhandled Future error"污染 Zone —— 即便本用例走的是正常路径，
        // 也不留隐患。
        nested!.catchError((_) => null);
      });

      await tester.pump(const Duration(milliseconds: 16));
      expect(phaseInsideCallback, isNot(SchedulerPhase.idle),
          reason: '前置：frameCallback 内部必须处于非 idle 阶段（transientCallbacks），'
              '这样 smokePostFrame 才会走 postFrame 分支而不是 idle 直跑');

      await tester.pump(const Duration(milliseconds: 16));

      expect(nested, isNotNull);
      final v = await nested;
      expect(v, 7);
      expect(captured, isEmpty,
          reason: 'post-frame 正常返回不应触发 reportError');
    });

    testWidgets('非 idle 期间 action 抛：走 completer.completeError → reportError',
        (tester) async {
      await _pumpWithNav(tester);
      await tester.pump();

      final captured = _hookFlutterErrorInsideTest();
      Future<int?>? nested;
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        nested = smokePostFrame<int>(
          'm4_postframe_err',
          (ctx) => Future<int>.error(Exception('post-frame err from ut')),
        );
        // 立即挂 error listener 消费掉 Future，避免 Zone 把它当作
        // unhandled Future error 报到 Zone.handleUncaughtError，
        // 再触发一次 FlutterError.reportError（否则 captured 会多一条）。
        nested!.catchError((_) => null);
      });

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(nested, isNotNull);
      await expectLater(
        nested,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'toString',
          contains('post-frame err from ut'),
        )),
      );

      expect(captured, hasLength(1),
          reason: 'post-frame path 异常分支应触发一次 reportError');
      final d = captured.single;
      expect(d.library, 'gsy smoke');
      expect(d.context?.toDescription(),
          'while running m4_postframe_err (post-frame path)');
    });
  });
}

/// 在 test 内部（binding 已经装完 [FlutterError.onError] 之后）替换一层 hook。
///
/// 返回一个 list，测试代码可以在 test 结束前对它做断言。
/// hook 会：
/// 1. 把 details 抓到返回的 list 里做字段断言用
/// 2. **故意不 forward 给 previous**（也就是 flutter_test 的 onError）——
///    因为 previous 会把 details 记到 test 的 `_pendingExceptions` 里，
///    test 结束时如果有 pending exception 就判红；而本用例断言的正是
///    「`smokePostFrame` 期望 report 这条 error」，属于预期行为，
///    不该被 test framework 视作 fail。
///
/// addTearDown 保证 test 结束时把 onError 还原到 binding 装的版本，
/// 用例之外的意外 exception 仍由 flutter_test framework 正常处理。
List<FlutterErrorDetails> _hookFlutterErrorInsideTest() {
  final captured = <FlutterErrorDetails>[];
  final FlutterExceptionHandler? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    captured.add(details);
  };
  addTearDown(() {
    FlutterError.onError = previous;
  });
  return captured;
}

/// 挂一个最小 MaterialApp，`navigatorKey: navKey` 让 `navKey.currentContext`
/// 有效。不引入任何业务栈（Redux/Riverpod/Dio/GraphQL），避免测试污染。
Future<void> _pumpWithNav(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navKey,
      home: const Scaffold(body: SizedBox()),
    ),
  );
}
