import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

/// Placeholder provider for the application's single [Isar] instance.
///
/// Overridden at application startup in main.dart with the real instance
/// returned by `bootstrap()`. Throws if read before that override is
/// applied.
final Provider<Isar> isarInstanceProvider = Provider<Isar>((ref) {
  throw UnimplementedError(
    'isarInstanceProvider must be overridden with a real Isar instance '
    'at application startup (see main.dart).',
  );
});
