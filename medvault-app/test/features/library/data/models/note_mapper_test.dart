import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/note_mapper.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'device-1',
      syncRevision: 1,
    );

void main() {
  group('NoteMapper', () {
    test('toModel then toDomain round-trips all fields', () {
      final domain = Note(
        uuid: 'note-1',
        topicUuid: 'topic-1',
        mode: Mode.detailedNotes,
        title: 'Heart failure',
        bodyMarkdown: '# Heart failure\n...',
        plainTextExtract: 'Heart failure ...',
        tags: ['cardiology', 'exam'],
        citationOrder: ['cite-1', 'cite-2'],
        isPinned: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        sync: _sync(),
      );

      final model = NoteMapper.toModel(domain);
      final roundTripped = NoteMapper.toDomain(model);

      expect(roundTripped.uuid, domain.uuid);
      expect(roundTripped.topicUuid, domain.topicUuid);
      expect(roundTripped.mode, domain.mode);
      expect(roundTripped.title, domain.title);
      expect(roundTripped.tags, domain.tags);
      expect(roundTripped.citationOrder, domain.citationOrder);
    });

    test('toModel copies tags defensively (no shared list instance)', () {
      final tags = ['cardiology'];
      final domain = Note(
        uuid: 'note-1',
        topicUuid: 'topic-1',
        mode: Mode.detailedNotes,
        title: 'Heart failure',
        bodyMarkdown: 'body',
        tags: tags,
        citationOrder: const [],
        isPinned: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        sync: _sync(),
      );

      final model = NoteMapper.toModel(domain);
      tags.add('mutated-after-mapping');

      expect(model.tags, ['cardiology']);
    });

    test('toDomain copies tags defensively (no shared list instance)', () {
      final domain = NoteMapper.toDomain(
        NoteMapper.toModel(
          Note(
            uuid: 'note-1',
            topicUuid: 'topic-1',
            mode: Mode.detailedNotes,
            title: 'Heart failure',
            bodyMarkdown: 'body',
            tags: ['cardiology'],
            citationOrder: const [],
            isPinned: false,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
            sync: _sync(),
          ),
        ),
      );

      final originalTags = List<String>.from(domain.tags);
      domain.tags.add('mutated');

      expect(originalTags, ['cardiology']);
    });
  });
}
