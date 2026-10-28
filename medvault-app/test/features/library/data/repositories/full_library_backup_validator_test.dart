import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/library/data/repositories/full_library_backup_validator.dart';

const topicId = '11111111-1111-4111-8111-111111111111';
const noteId = '22222222-2222-4222-8222-222222222222';
const citationId = '33333333-3333-4333-8333-333333333333';
const bookmarkId = '44444444-4444-4444-8444-444444444444';
const historyId = '55555555-5555-4555-8555-555555555555';
const resourceId = '66666666-6666-4666-8666-666666666666';

void main() {
  const validator = FullLibraryBackupValidator();

  group('FullLibraryBackupValidator', () {
    test('accepts a complete archive with valid payload checksums', () {
      final result = validator.validate(_makeBackup());

      expect(result.formatVersion, 1);
      expect(result.createdAt, DateTime.utc(2026, 10, 22));
      expect(result.payloads.keys, contains('database/taxonomy.json'));
      expect(result.payloads.keys, contains('personal-data/bookmarks.json'));
      expect(
        jsonDecode(utf8.decode(result.payloads['resources/metadata.json']!)),
        hasLength(1),
      );
      expect(
        result.payloads.keys,
        contains('resources/pdfs/$resourceId.pdf'),
      );
    });

    test('rejects an empty archive input', () {
      expect(
        () => validator.validate(Uint8List(0)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a payload whose checksum does not match', () {
      expect(
        () => validator.validate(_makeBackup(corruptChecksum: true)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('checksum'),
          ),
        ),
      );
    });

    test('rejects an archive missing a required payload', () {
      expect(
        () => validator.validate(
          _makeBackup(omitPayload: 'database/notes.json'),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('incomplete'),
          ),
        ),
      );
    });

    test('rejects unsafe ZIP paths before reading the manifest', () {
      final archive = Archive()
        ..addFile(ArchiveFile('../outside.json', 2, utf8.encode('{}')));

      final bytes = ZipEncoder().encode(archive);

      expect(
        () => validator.validate(Uint8List.fromList(bytes)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an unsupported note mode', () {
      expect(
        () => validator.validate(_makeBackup(invalidNoteMode: true)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('mode'),
          ),
        ),
      );
    });

    test('rejects a bookmark referencing a missing note', () {
      expect(
        () => validator.validate(_makeBackup(brokenBookmarkReference: true)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('missing note'),
          ),
        ),
      );
    });

    test('rejects resource metadata with the wrong PDF size', () {
      expect(
        () => validator.validate(_makeBackup(wrongResourceSize: true)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('fileSizeBytes'),
          ),
        ),
      );
    });

    test('rejects an invalid preference value', () {
      expect(
        () => validator.validate(_makeBackup(invalidPreference: true)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('themePreference'),
          ),
        ),
      );
    });
  });
  test('rejects a malformed HTML lesson package with a valid checksum', () {
    expect(
      () => const FullLibraryBackupValidator().validate(
        _makeBackup(invalidHtmlLesson: true),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

Uint8List _makeBackup({
  bool corruptChecksum = false,
  String? omitPayload,
  bool invalidNoteMode = false,
  bool brokenBookmarkReference = false,
  bool wrongResourceSize = false,
  bool invalidPreference = false,
  bool invalidHtmlLesson = false,
}) {
  const now = '2026-10-22T00:00:00.000Z';
  final sync = <String, Object?>{
    'remoteId': null,
    'lastModifiedLocal': now,
    'lastSyncedAt': null,
    'isDirty': true,
    'isDeleted': false,
    'deviceId': 'test-device',
    'syncRevision': 0,
  };

  const pdfBytes = <int>[
    0x25, 0x50, 0x44, 0x46, 0x2D,
    0x31, 0x2E, 0x37, 0x0A,
  ];
  const pdfPath = 'resources/pdfs/$resourceId.pdf';
  const htmlPath = 'resources/html_lessons/$resourceId.zip';
  final resourcePath = invalidHtmlLesson ? htmlPath : pdfPath;
  final resourceBytes = invalidHtmlLesson
      ? const <int>[1, 2, 3, 4, 5, 6]
      : pdfBytes;

  final taxonomy = <Map<String, Object?>>[
    {
      'uuid': topicId,
      'parentUuid': null,
      'path': topicId,
      'depth': 0,
      'nodeType': 'topic',
      'title': 'Test topic',
      'slug': 'test-topic',
      'shortDescription': null,
      'iconKey': null,
      'sortOrder': 0,
      'noteCount': 1,
      'curriculumPackUuid': null,
      'curriculumPackVersion': null,
      'isUserCreated': false,
      'createdAt': now,
      'updatedAt': now,
      'sync': sync,
    },
  ];

  final notes = <Map<String, Object?>>[
    {
      'uuid': noteId,
      'topicUuid': topicId,
      'mode': invalidNoteMode ? 'notARealMode' : 'detailedNotes',
      'title': 'Test note',
      'bodyMarkdown': 'Test body',
      'plainTextExtract': null,
      'tags': <String>['test'],
      'citationOrder': <String>[citationId],
      'isPinned': false,
      'createdAt': now,
      'updatedAt': now,
      'sync': sync,
    },
  ];

  final citations = <Map<String, Object?>>[
    {
      'uuid': citationId,
      'sourceType': 'textbook',
      'title': 'Test reference',
      'authors': null,
      'publicationYear': 2024,
      'pageReference': null,
      'url': null,
      'createdAt': now,
      'updatedAt': now,
      'sync': sync,
    },
  ];

  final bookmarks = <Map<String, Object?>>[
    {
      'uuid': bookmarkId,
      'noteUuid': brokenBookmarkReference
          ? '77777777-7777-4777-8777-777777777777'
          : noteId,
      'label': null,
      'createdAt': now,
      'sync': sync,
    },
  ];

  final history = <Map<String, Object?>>[
    {
      'uuid': historyId,
      'noteUuid': noteId,
      'viewedAt': now,
      'sync': sync,
    },
  ];

  final resources = <Map<String, Object?>>[
    {
      'uuid': resourceId,
      'topicUuid': topicId,
      'title': invalidHtmlLesson ? 'Test HTML lesson' : 'Test PDF',
      'originalFileName': invalidHtmlLesson ? 'test.zip' : 'test.pdf',
      'fileSizeBytes': resourceBytes.length + (wrongResourceSize ? 1 : 0),
      'importedAt': now,
      if (invalidHtmlLesson) 'format': 'htmlLesson',
      'archivePath': resourcePath,
    },
  ];

  final curriculumPack = <String, Object?>{
    'manifest': {
      'formatVersion': 1,
      'packUuid': '88888888-8888-4888-8888-888888888888',
      'version': 1,
      'title': 'Test backup',
      'description': 'Validator fixture',
    },
    'taxonomyNodes': [
      {
        'uuid': topicId,
        'nodeType': 'topic',
        'title': 'Test topic',
        'slug': 'test-topic',
        'sortOrder': 0,
      },
    ],
    'notes': [
      {
        'uuid': noteId,
        'topicUuid': topicId,
        'mode': 'detailedNotes',
        'title': 'Test note',
        'bodyMarkdown': 'Test body',
        'tags': ['test'],
        'citationOrder': [citationId],
      },
    ],
    'citations': [
      {
        'uuid': citationId,
        'sourceType': 'textbook',
        'title': 'Test reference',
        'publicationYear': 2024,
      },
    ],
  };

  final payloads = <String, List<int>>{
    'curriculum-pack.json': utf8.encode(jsonEncode(curriculumPack)),
    'database/taxonomy.json': utf8.encode(jsonEncode(taxonomy)),
    'database/notes.json': utf8.encode(jsonEncode(notes)),
    'database/citations.json': utf8.encode(jsonEncode(citations)),
    'personal-data/bookmarks.json': utf8.encode(jsonEncode(bookmarks)),
    'personal-data/history.json': utf8.encode(jsonEncode(history)),
    'personal-data/preferences.json': utf8.encode(jsonEncode({
      'values': {
        'appearance.themePreference':
            invalidPreference ? 'neon' : 'system',
        'reading.textSize': 'normal',
        'pdf_reader_continuous_mode': true,
        'pdf_reader_last_page_$resourceId': 1,
        'reader.scrollOffset.$noteId': 0.0,
      },
    })),
    'resources/metadata.json': utf8.encode(jsonEncode(resources)),
    resourcePath: resourceBytes,
  };

  if (omitPayload != null) {
    payloads.remove(omitPayload);
  }

  final manifestPayloads = <String, Object>{};
  for (final entry in payloads.entries) {
    manifestPayloads[entry.key] = {
      'sha256': sha256.convert(entry.value).toString(),
      'sizeBytes': entry.value.length,
    };
  }

  if (corruptChecksum) {
    final metadata =
        manifestPayloads['database/notes.json'] as Map<String, Object>;
    metadata['sha256'] = List<String>.filled(64, '0').join();
  }

  final manifest = <String, Object>{
    'formatVersion': 1,
    'createdAt': '2026-10-22T00:00:00.000Z',
    'payloads': manifestPayloads,
  };

  final archive = Archive();
  for (final entry in payloads.entries) {
    archive.addFile(
      ArchiveFile(entry.key, entry.value.length, entry.value),
    );
  }

  final manifestBytes = utf8.encode(jsonEncode(manifest));
  archive.addFile(
    ArchiveFile(
      'backup-manifest.json',
      manifestBytes.length,
      manifestBytes,
    ),
  );

  return Uint8List.fromList(ZipEncoder().encode(archive));
}
