import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// 拉出 history 里 logLevel == error 的最后一条 TalkerData，用于断言 typed 分派。
TalkerData? _lastErrorEntry() {
  final entries = talker.history
      .where((d) => d.logLevel == LogLevel.error)
      .toList();
  return entries.isEmpty ? null : entries.last;
}

void main() {
  group('printError - 结构化异常上报契约', () {
    setUp(() {
      talker.cleanHistory();
    });

    test('exception 作为 typed 参数存进 talker，而不是拼进 message 字符串', () {
      final exception = FormatException('bad payload', 'raw');
      final stack = StackTrace.current;

      printError('parseJson 失败', exception, stack);

      final entry = _lastErrorEntry();
      expect(entry, isNotNull);
      expect(entry!.exception, same(exception),
          reason: 'typed exception 必须原样传给 talker，让 sink 端按类型聚合');
      expect(entry.stackTrace, same(stack), reason: 'stackTrace 原样传，不能吞');
      expect(entry.message, 'parseJson 失败',
          reason: 'context 与 exception 分开传，message 里不能拼接 exception 字符串');
    });

    test('未传 stackTrace 时不 crash，talker.stackTrace 为 null', () {
      final err = ArgumentError('missing arg');
      printError('业务前置校验失败', err);
      final entry = _lastErrorEntry();
      expect(entry, isNotNull);
      expect(entry!.exception, same(err));
      expect(entry.stackTrace, isNull);
    });
  });

  group('printLog - 既有单参 / 双参兼容', () {
    setUp(() {
      talker.cleanHistory();
    });

    test('传 Error 会挂到 talker 的 exception 位（typed）', () {
      final err = StateError('bad state');
      final stack = StackTrace.current;
      printLog(err, stack);
      final entry = _lastErrorEntry();
      expect(entry, isNotNull);
      expect(entry!.exception, same(err));
      expect(entry.stackTrace, same(stack));
    });

    test('传 Exception + stack 会走 Exception 分支', () {
      final ex = FormatException('nope');
      final stack = StackTrace.current;
      printLog(ex, stack);
      final entry = _lastErrorEntry();
      expect(entry, isNotNull);
      expect(entry!.exception, same(ex));
      expect(entry.stackTrace, same(stack));
    });

    test('String + stack 时 exception 位为 null（旧兼容分支）', () {
      final stack = StackTrace.current;
      printLog('some context', stack);
      final entry = _lastErrorEntry();
      expect(entry, isNotNull);
      expect(entry!.exception, isNull);
      expect(entry.stackTrace, same(stack));
      expect(entry.message, 'some context');
    });

    test('只传纯 String（无 stack）不产生 error 级条目', () {
      printLog('just a message');
      expect(_lastErrorEntry(), isNull,
          reason: '普通日志不能被误分类为 error');
    });
  });
}
