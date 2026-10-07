import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/core/sync/sync_metadata.dart';
import '../../../../lib/features/library/domain/entities/citation.dart';
import '../../../../lib/features/library/domain/entities/note.dart';
import '../../../../lib/features/library/domain/services/dto/note_with_citations.dart';
import '../../../../lib/features/library/presentation/providers/note_reader_provider.dart';
import '../../../../lib/features/library/presentation/screens/note_reader_screen.dart';

Note makeNote({
  required String uuid,
  String title = 'Test Note',
  String bodyMarkdown = '# Test Note\n\nThis is **important**.',
}) {
  return Note(
    uuid: uuid,
    topicUuid: 'topic-1',
    mode: Mode.detailedNotes,
    title: title,
    bodyMarkdown: bodyMarkdown,
    tags: const [],
    citationOrder: const ['citation-1'],
    isPinned: false,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    sync: SyncMetadata(
      lastModifiedLocal: DateTime(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'test-device',
      syncRevision: 1,
    ),
  );
}

Citation makeCitation() {
  return Citation(
    uuid: 'citation-1',
    sourceType: SourceType.textbook,
    title: 'Nelson Textbook of Pediatrics',
    authors: 'Kliegman et al.',
    publicationYear: 2024,
    pageReference: 'p. 120',
    url: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    sync: SyncMetadata(
      lastModifiedLocal: DateTime(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'test-device',
      syncRevision: 1,
    ),
  );
}

Widget buildTestApp({
  required String noteUuid,
  required AsyncValue<NoteWithCitations?> value,
}) {
  return ProviderScope(
    overrides: [
      noteReaderProvider(noteUuid).overrideWith(
        (ref) async => value.requireValue,
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: NoteReaderScreen(noteUuid: noteUuid),
    ),
  );
}

void main() {
  testWidgets('displays loading state', (tester) async {
    final completer = Completer<NoteWithCitations?>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteReaderProvider('note-1').overrideWith(
            (ref) => completer.future,
          ),
        ],
        child: const MaterialApp(
          home: NoteReaderScreen(noteUuid: 'note-1'),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays not-found state', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        noteUuid: 'missing',
        value: const AsyncData<NoteWithCitations?>(null),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Note not found'), findsOneWidget);
  });

  testWidgets('renders note title and markdown body', (tester) async {
    final note = makeNote(
      uuid: 'note-1',
      title: 'Acute Kidney Injury',
      bodyMarkdown: '# Acute Kidney Injury\n\nThis is **important**.',
    );

    final data = NoteWithCitations(
      note: note,
      citations: [makeCitation()],
    );

    await tester.pumpWidget(
      buildTestApp(
        noteUuid: note.uuid,
        value: AsyncData<NoteWithCitations?>(data),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acute Kidney Injury'), findsWidgets);
    final markdownFinder = find.byType(MarkdownBody);
    expect(markdownFinder, findsOneWidget);

    final markdown = tester.widget<MarkdownBody>(markdownFinder);
    expect(markdown.data, contains('This is **important**.'));
  });

  testWidgets('renders resolved citations', (tester) async {
    final note = makeNote(uuid: 'note-1');

    final data = NoteWithCitations(
      note: note,
      citations: [makeCitation()],
    );

    await tester.pumpWidget(
      buildTestApp(
        noteUuid: note.uuid,
        value: AsyncData<NoteWithCitations?>(data),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('References'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('Nelson Textbook of Pediatrics'), findsOneWidget);
    expect(find.text('Kliegman et al. · 2024 · p. 120'), findsOneWidget);
  });
}
