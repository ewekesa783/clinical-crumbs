import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/citation_mapper.dart';
import 'package:medvault_app/features/library/domain/entities/citation.dart';

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'device-1',
      syncRevision: 1,
    );

void main() {
  test('CitationMapper round-trips all fields', () {
    final domain = Citation(
      uuid: 'cite-1',
      sourceType: SourceType.textbook,
      title: "Robbins Pathologic Basis of Disease",
      authors: 'Kumar, Abbas, Aster',
      publicationYear: 2020,
      pageReference: 'p. 542',
      url: null,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );

    final model = CitationMapper.toModel(domain);
    final roundTripped = CitationMapper.toDomain(model);

    expect(roundTripped.uuid, domain.uuid);
    expect(roundTripped.sourceType, domain.sourceType);
    expect(roundTripped.title, domain.title);
    expect(roundTripped.authors, domain.authors);
    expect(roundTripped.publicationYear, domain.publicationYear);
    expect(roundTripped.pageReference, domain.pageReference);
  });
}
