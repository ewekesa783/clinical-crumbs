import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'injector.g.dart';

// KNOWN GAP (preserved intentionally): this file still contains only the
// original Phase 0 demonstration repository pair below. Its own doc
// comment (immediately below) states that it "is deleted at the start of
// Phase 1," but no task has yet performed that deletion, and no
// composition root wiring the real Phase 1/2 repositories and services
// has been authorized. Do not remove this placeholder and do not add
// real wiring without an explicit task instructing it — doing so would
// be unauthorized scope expansion under the current project rules.

/// Demonstration-only repository interface used to validate the Phase 0
/// Riverpod + code-generation toolchain. This interface and its
/// implementation are deleted at the start of Phase 1.
abstract class GreetingRepository {
  String greet();
}

class StaticGreetingRepository implements GreetingRepository {
  @override
  String greet() => 'Hello from MedVault (Phase 0 demonstration).';
}

@riverpod
GreetingRepository greetingRepository(GreetingRepositoryRef ref) {
  return StaticGreetingRepository();
}
