import 'package:uuid/uuid.dart';

/// Generates UUID v4 identifiers for local MedVault records.
class UuidGenerator {
  UuidGenerator({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  String call() => _uuid.v4();
}
