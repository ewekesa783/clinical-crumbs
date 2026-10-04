import '../entities/citation.dart';

abstract class CitationRepository {
  Future<void> save(Citation citation);

  Future<Citation?> getByUuid(String uuid);

  /// Returns citations for each UUID in [uuids], preserving both the
  /// input order and multiplicity (a repeated UUID yields a repeated
  /// entry). A UUID with no matching citation is silently omitted from
  /// the result rather than causing an error or a null placeholder —
  /// this contract was clarified during MV-IP-001 Task A.3A specifically
  /// to resolve ambiguity about missing-UUID handling.
  Future<List<Citation>> getByUuids(List<String> uuids);
}
