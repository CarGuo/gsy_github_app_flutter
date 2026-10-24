import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

// 2026-10-23: export committed release inputs, never a developer's mutable
// checkout/build directories, and verify the exact bytes used by this app.
final _root = Directory.fromUri(Platform.script.resolve('../../'));
final _snapshot = Directory.fromUri(
  _root.uri.resolve('vendor/flutter_performance_monitor/'),
);
const _packages = {
  'flutter_performance_monitor',
  'flutter_performance_monitor_dio',
};
const _releaseFiles = {
  'pubspec.yaml',
  'README.md',
  'LICENSE',
  'CHANGELOG.md',
  'analysis_options.yaml',
};
const _releaseDirectories = {'lib', 'android', 'ios', 'macos'};

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    await _verify();
  } else if (args.length == 3 && args.first == '--freeze') {
    await _freeze(Directory(args[1]).absolute.path, args[2]);
  } else {
    throw ArgumentError(
      'Usage: dart run tool/telemetry/sdk_snapshot.dart '
      '[--freeze <source-checkout> <full-commit-sha>]',
    );
  }
}

bool _isReleaseInput(String path) {
  final parts = path.split('/');
  if (parts.length < 3 ||
      parts[0] != 'packages' ||
      !_packages.contains(parts[1])) {
    return false;
  }
  if (parts.length == 3) return _releaseFiles.contains(parts[2]);
  return _releaseDirectories.contains(parts[2]) &&
      !parts.any({'build', '.dart_tool', '.gradle', '.build', 'test'}.contains);
}

String _contentHash(Map<String, String> files) {
  final names = files.keys.toList()..sort();
  return sha256
      .convert(
        utf8.encode(names.map((name) => '${files[name]}  $name\n').join()),
      )
      .toString();
}

Future<void> _verify() async {
  await for (final entity in _snapshot.list(followLinks: false)) {
    final name = entity.uri.pathSegments.where((part) => part.isNotEmpty).last;
    if (!((entity is File && name == 'release.json') ||
        (entity is Directory && name == 'packages'))) {
      throw StateError('Unexpected SDK snapshot root entry: $name');
    }
  }
  final manifest = jsonDecode(
    await File.fromUri(_snapshot.uri.resolve('release.json')).readAsString(),
  ) as Map<String, dynamic>;
  final source = manifest['source'] as Map<String, dynamic>;
  if (manifest['schema_version'] != 1 ||
      !RegExp(r'^[0-9a-f]{40}$').hasMatch(source['commit'] as String)) {
    throw StateError('Invalid SDK snapshot provenance');
  }
  final expected = Map<String, String>.from(manifest['files'] as Map);
  final actual = <String, String>{};
  await for (final entity in Directory.fromUri(
    _snapshot.uri.resolve('packages/'),
  ).list(recursive: true, followLinks: false)) {
    if (entity is Directory) continue;
    final name = entity.uri.path.substring(_snapshot.uri.path.length);
    if (entity is! File || !_isReleaseInput(name)) {
      throw StateError('Unexpected SDK snapshot entry: $name');
    }
    actual[name] = sha256.convert(await entity.readAsBytes()).toString();
  }
  if (actual.length != expected.length ||
      expected.entries.any((entry) => actual[entry.key] != entry.value) ||
      _contentHash(actual) != manifest['content_sha256']) {
    throw StateError('SDK snapshot differs from its pinned release manifest');
  }
  stdout.writeln(
    'SDK snapshot verified: ${source['commit']} (${actual.length} files)',
  );
}

Future<ProcessResult> _git(String source, List<String> args) async {
  final result = await Process.run('git', [
    '-C',
    source,
    ...args,
  ], stdoutEncoding: null);
  if (result.exitCode != 0) {
    throw StateError('Cannot read committed SDK source');
  }
  return result;
}

Future<void> _freeze(String source, String revision) async {
  if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(revision)) {
    throw ArgumentError('A full committed source revision is required');
  }
  if (await _snapshot.exists()) await _verify();
  final tree = await _git(source, [
    'ls-tree',
    '-r',
    '--name-only',
    revision,
    ..._packages.map((name) => 'packages/$name'),
  ]);
  final names =
      utf8
          .decode(tree.stdout as List<int>)
          .split('\n')
          .where(_isReleaseInput)
          .toList()
        ..sort();
  for (final package in _packages) {
    if (!names.contains('packages/$package/pubspec.yaml')) {
      throw StateError('SDK source revision is missing $package');
    }
  }
  final payloads = <String, List<int>>{};
  for (final name in names) {
    payloads[name] =
        (await _git(source, ['show', '$revision:$name'])).stdout as List<int>;
  }
  final packageDirectory = Directory.fromUri(
    _snapshot.uri.resolve('packages/'),
  );
  if (await packageDirectory.exists()) {
    await packageDirectory.delete(recursive: true);
  }
  final hashes = <String, String>{};
  for (final entry in payloads.entries) {
    final destination = File.fromUri(_snapshot.uri.resolve(entry.key));
    await destination.parent.create(recursive: true);
    await destination.writeAsBytes(entry.value);
    hashes[entry.key] = sha256.convert(entry.value).toString();
  }
  final manifest = {
    'schema_version': 1,
    'source': {
      'repository': 'https://github.com/CarGuo/flutter_performance_monitor',
      'commit': revision,
    },
    'content_sha256': _contentHash(hashes),
    'files': hashes,
  };
  await File.fromUri(
    _snapshot.uri.resolve('release.json'),
  ).writeAsString('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
  await _verify();
}
