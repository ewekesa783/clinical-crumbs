import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.isLinux) {
    final library = File(
      '${Directory.current.parent.path}/medvault-infrastructure/'
      'vendor/isar_flutter_libs/linux/libisar.so',
    );

    await Isar.initializeIsarCore(
      libraries: {Abi.linuxX64: library.absolute.path},
    );
  }

  await testMain();
}
