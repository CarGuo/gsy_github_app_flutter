import 'dart:convert';

import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/common/local/local_storage.dart';

/// 搜索历史读写
///
/// - 存储：SharedPreferences 单 key（[Config.SEARCH_HISTORY_KEY]），JSON 编码 `List<String>`
/// - 容量：最多保留 [Config.SEARCH_HISTORY_MAX] 条（默认 10），满则淘汰最老
/// - 去重：新 query 若已存在则前移到首位，不重复占位
/// - 忽略：空串或纯空白 query 不入库
///
/// 所有 IO 都跑在 SharedPreferences 内部线程，UI 侧只需 await。
class SearchHistoryRepository {
  SearchHistoryRepository._();

  static Future<List<String>> load() async {
    final raw = await LocalStorage.get(Config.SEARCH_HISTORY_KEY);
    if (raw is! String || raw.isEmpty) return <String>[];
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) return <String>[];
      return decoded.whereType<String>().toList(growable: false);
    } catch (_) {
      return <String>[];
    }
  }

  static Future<List<String>> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return load();
    final current = await load();
    final next = <String>[trimmed];
    for (final q in current) {
      if (q == trimmed) continue;
      next.add(q);
      if (next.length >= Config.SEARCH_HISTORY_MAX) break;
    }
    await LocalStorage.save(Config.SEARCH_HISTORY_KEY, json.encode(next));
    return next;
  }

  static Future<void> clear() async {
    await LocalStorage.remove(Config.SEARCH_HISTORY_KEY);
  }
}
