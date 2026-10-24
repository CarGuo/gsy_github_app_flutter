import 'dart:convert';
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

/// OS ownership, shared by independent isolates/Flutter engines and processes.
/// An isolate-local Set and POSIX fcntl locks cannot provide this guarantee.
final class OutboxOwnership implements Finalizable {
  OutboxOwnership._(SendPort requests) : _requests = requests {
    _abandoned.attach(this, requests, detach: this);
  }

  // Explicit dispose is deterministic; the owner-exit listener is the shutdown
  // guarantee. This also releases an abandoned low-level wrapper during GC.
  static final _abandoned = Finalizer<SendPort>(
    (requests) => requests.send(null),
  );

  SendPort? _requests;
  Future<void>? _releasing;

  static Future<OutboxOwnership?> acquire(String path) async {
    final response = ReceivePort();
    try {
      await Isolate.spawn(_ownershipWorker, (
        response.sendPort,
        path,
        Isolate.current,
      ));
      final result = await response.first;
      if (result == null) return null;
      if (result is! SendPort) {
        throw const FileSystemException('Cannot acquire outbox ownership');
      }
      return OutboxOwnership._(result);
    } finally {
      response.close();
    }
  }

  Future<void> release() => _releasing ??= () async {
    final requests = _requests;
    if (requests == null) return;
    _abandoned.detach(this);
    final response = ReceivePort();
    try {
      requests.send(response.sendPort);
      if (await response.first != true) {
        throw const FileSystemException('Cannot close outbox ownership');
      }
      _requests = null;
    } finally {
      response.close();
    }
  }();
}

/// Handles never cross an isolate boundary. A worker owns acquisition, release
/// and finalization, including when its caller isolate/Flutter engine exits.
Future<void> _ownershipWorker((SendPort, String, Isolate) message) async {
  final (response, path, owner) = message;
  final requests = ReceivePort();
  _OwnedFiles? files;
  var closing = false;
  Future<void>? releasing;
  Future<void> close(SendPort? reply) async {
    closing = true;
    final owned = files;
    if (owned == null) return; // Acquisition will observe closing before ready.
    releasing ??= owned.release();
    try {
      await releasing;
      reply?.send(true);
    } catch (_) {
      reply?.send(false);
    } finally {
      owner.removeOnExitListener(requests.sendPort);
      requests.close();
    }
  }

  requests.listen((request) {
    unawaited(close(request is SendPort ? request : null));
  });
  owner.addOnExitListener(requests.sendPort);
  try {
    files = await _OwnedFiles.acquire(path);
    if (files == null) {
      response.send(null);
      owner.removeOnExitListener(requests.sendPort);
      requests.close();
    } else if (closing) {
      await close(null);
    } else {
      response.send(requests.sendPort);
    }
  } catch (_) {
    response.send(false);
    owner.removeOnExitListener(requests.sendPort);
    requests.close();
  }
}

final class _OwnedFiles implements Finalizable {
  _OwnedFiles._(this._nativeAddress) {
    if (_nativeAddress != 0) {
      _nativeFinalizer.attach(
        this,
        Pointer.fromAddress(_nativeAddress),
        detach: this,
      );
    }
  }

  int _nativeAddress;
  RandomAccessFile? _compatibilityLock;

  // fclose takes one pointer on every supported POSIX ABI. Its integer return
  // is intentionally ignored by the native finalizer callback. No Dart code
  // runs from the finalizer, including during Flutter engine group shutdown.
  static final _nativeFinalizer = NativeFinalizer(
    DynamicLibrary.process()
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>('fclose')
        .cast(),
  );

  static Future<_OwnedFiles?> acquire(String path) async {
    var nativeAddress = 0;
    if (!Platform.isWindows) {
      if (!(Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isLinux)) {
        throw UnsupportedError('Outbox ownership is unsupported on this OS');
      }
      // 2026-10-23: flock is tied to an open file description, unlike Dart's
      // process-scoped POSIX FileLock. Independent opens conflict even in one
      // process; closing a failed contender cannot unlock the live owner.
      // Keep the legacy fcntl lock on a different inode: Darwin interoperates
      // flock/fcntl, and POSIX closing any descriptor of a legacy lock inode
      // can release the process's fcntl lock, including a rejected contender.
      nativeAddress = _PosixFiles.instance.acquire('$path.flock');
      if (nativeAddress == 0) return null;
    }
    final ownership = _OwnedFiles._(nativeAddress);
    try {
      final file = await File(path).open(mode: FileMode.append);
      ownership._compatibilityLock = file;
      try {
        // Windows locks are handle scoped. On POSIX retain fcntl as well so a
        // separately running older SDK cannot ignore the new flock protocol.
        await file.lock(FileLock.exclusive);
      } on FileSystemException catch (error) {
        final code = error.osError?.errorCode;
        final contended = Platform.isWindows
            ? code == 32 || code == 33
            : code == 13 || code == 11 || code == 35;
        if (!contended) rethrow;
        await ownership.release();
        return null;
      }
      return ownership;
    } catch (_) {
      await ownership.release();
      rethrow;
    }
  }

  Future<void> release() async {
    final compatibilityLock = _compatibilityLock;
    _compatibilityLock = null;
    try {
      if (compatibilityLock != null) await compatibilityLock.close();
    } finally {
      final address = _nativeAddress;
      if (address != 0) {
        _nativeAddress = 0;
        _nativeFinalizer.detach(this);
        // 2026-10-23: detach and close on the owning worker without an await or
        // native-pointer handoff. The UI never blocks on libc/file operations.
        _PosixFiles.instance.close(address);
      }
    }
  }
}

final class _PosixFiles {
  _PosixFiles() {
    final library = DynamicLibrary.process();
    _malloc = library
        .lookupFunction<
          Pointer<Uint8> Function(IntPtr),
          Pointer<Uint8> Function(int)
        >('malloc');
    _free = library
        .lookupFunction<
          Void Function(Pointer<Void>),
          void Function(Pointer<Void>)
        >('free');
    _fopen = library
        .lookupFunction<
          Pointer<Void> Function(Pointer<Uint8>, Pointer<Uint8>),
          Pointer<Void> Function(Pointer<Uint8>, Pointer<Uint8>)
        >('fopen');
    _fileno = library
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('fileno');
    _flock = library
        .lookupFunction<Int32 Function(Int32, Int32), int Function(int, int)>(
          'flock',
        );
    _fclose = library
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('fclose');
    _errno = library
        .lookupFunction<Pointer<Int32> Function(), Pointer<Int32> Function()>(
          Platform.isMacOS || Platform.isIOS
              ? '__error'
              : Platform.isAndroid
              ? '__errno'
              : '__errno_location',
        );
  }

  static final instance = _PosixFiles();
  late final Pointer<Uint8> Function(int) _malloc;
  late final void Function(Pointer<Void>) _free;
  late final Pointer<Void> Function(Pointer<Uint8>, Pointer<Uint8>) _fopen;
  late final int Function(Pointer<Void>) _fileno, _fclose;
  late final int Function(int, int) _flock;
  late final Pointer<Int32> Function() _errno;

  Pointer<Uint8> _string(String value) {
    final bytes = utf8.encode(value);
    final pointer = _malloc(bytes.length + 1);
    if (pointer == nullptr) throw StateError('Native allocation failed');
    pointer.asTypedList(bytes.length + 1)
      ..setRange(0, bytes.length, bytes)
      ..[bytes.length] = 0;
    return pointer;
  }

  int acquire(String path) {
    final name = _string(path);
    Pointer<Uint8>? mode;
    Pointer<Void> stream;
    try {
      mode = _string('a+');
      stream = _fopen(name, mode);
    } finally {
      _free(name.cast());
      if (mode != null) _free(mode.cast());
    }
    if (stream == nullptr) {
      throw FileSystemException('Cannot open outbox ownership file', path);
    }
    // LOCK_EX | LOCK_NB from sys/file.h on Darwin, Linux and Android/Bionic.
    if (_flock(_fileno(stream), 2 | 4) != 0) {
      final error = _errno().value;
      _fclose(stream);
      final wouldBlock = Platform.isMacOS || Platform.isIOS ? 35 : 11;
      if (error == wouldBlock) return 0;
      throw FileSystemException(
        'Cannot lock outbox ownership file',
        path,
        OSError('flock failed', error),
      );
    }
    return stream.address;
  }

  void close(int address) {
    if (_fclose(Pointer<Void>.fromAddress(address)) != 0) {
      throw const FileSystemException('Cannot close outbox ownership file');
    }
  }
}
