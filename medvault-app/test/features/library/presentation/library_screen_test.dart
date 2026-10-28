import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
import 'package:medvault_app/features/library/domain/entities/learning_resource.dart';
import 'package:medvault_app/features/library/presentation/providers/note_search_provider.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';
import 'package:medvault_app/features/library/presentation/providers/library_roots_provider.dart';
import 'package:medvault_app/features/library/presentation/screens/library_screen.dart';

void main() {
  final nodes = [
    TaxonomyNode(
      uuid: 'root-1',
      path: 'root-1',
      depth: 0,
      nodeType: NodeType.subject,
      title: 'Medicine',
      slug: 'medicine',
      sortOrder: 0,
      noteCount: 10,
      isUserCreated: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      sync: SyncMetadata(
        lastModifiedLocal: DateTime(2026, 1, 1),
        isDirty: false,
        isDeleted: false,
        deviceId: 'test-device',
        syncRevision: 1,
      ),
    ),
    TaxonomyNode(
      uuid: 'root-2',
      path: 'root-2',
      depth: 0,
      nodeType: NodeType.subject,
      title: 'Surgery',
      slug: 'surgery',
      sortOrder: 1,
      noteCount: 5,
      isUserCreated: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      sync: SyncMetadata(
        lastModifiedLocal: DateTime(2026, 1, 1),
        isDirty: false,
        isDeleted: false,
        deviceId: 'test-device',
        syncRevision: 1,
      ),
    ),
  ];

  Widget buildTestApp(List<TaxonomyNode> roots) {
    return ProviderScope(
      overrides: [
        allLearningResourcesProvider.overrideWith((ref) async => const []),
        libraryRootsProvider.overrideWith((ref) async => roots),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const LibraryScreen(),
      ),
    );
  }

  testWidgets('filters notes by mode and clears filters', (tester) async {
    final now = DateTime(2026, 1, 1);
    Note makeNote(String uuid, String title, Mode mode) => Note(
          uuid: uuid,
          topicUuid: 'root-1',
          mode: mode,
          title: title,
          bodyMarkdown: 'Synthetic test content.',
          plainTextExtract: 'Synthetic test content.',
          tags: const [],
          citationOrder: const [],
          isPinned: false,
          createdAt: now,
          updatedAt: now,
          sync: SyncMetadata(
            lastModifiedLocal: now,
            isDirty: false,
            isDeleted: false,
            deviceId: 'test-device',
            syncRevision: 1,
          ),
        );

    final detailed = makeNote(
      'detailed-test',
      'Detailed Fixture',
      Mode.detailedNotes,
    );
    final quick = makeNote(
      'quick-test',
      'Quick Fixture',
      Mode.quickReview,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allLearningResourcesProvider.overrideWith((ref) async => const []),
          libraryRootsProvider.overrideWith((ref) async => nodes),
          libraryTaxonomyNodesProvider.overrideWith((ref) async => nodes),
          allLibraryNotesProvider
              .overrideWith((ref) async => [detailed, quick]),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const LibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detailed Fixture'), findsNothing);
    expect(find.text('Quick Fixture'), findsNothing);

    await tester.tap(find.byTooltip('Open filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Mode?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quick review').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(find.text('Quick Fixture'), findsOneWidget);
    expect(find.text('Detailed Fixture'), findsNothing);
    expect(find.text('1 note found'), findsOneWidget);
    expect(find.byTooltip('Open filters (1 active)'), findsOneWidget);

    await tester.tap(find.byTooltip('Open filters (1 active)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Open filters (1 active)'), findsNothing);
    expect(find.text('Quick Fixture'), findsNothing);
    expect(find.text('Detailed Fixture'), findsNothing);
    expect(find.text('Medicine'), findsOneWidget);
  });

  testWidgets('subject filter includes descendant-topic notes', (tester) async {
    final now = DateTime(2026, 1, 1);
    final medicine = nodes.first;
    final cardiology = TaxonomyNode(
      uuid: 'cardiology-topic',
      path: 'root-1/cardiology-topic',
      depth: 1,
      nodeType: NodeType.topic,
      title: 'Cardiology',
      slug: 'cardiology',
      sortOrder: 0,
      noteCount: 1,
      isUserCreated: false,
      createdAt: now,
      updatedAt: now,
      sync: SyncMetadata(
        lastModifiedLocal: now,
        isDirty: false,
        isDeleted: false,
        deviceId: 'test-device',
        syncRevision: 1,
      ),
    );

    Note makeNote(String uuid, String title, String topicUuid) => Note(
          uuid: uuid,
          topicUuid: topicUuid,
          mode: Mode.detailedNotes,
          title: title,
          bodyMarkdown: 'Synthetic test content.',
          plainTextExtract: 'Synthetic test content.',
          tags: const [],
          citationOrder: const [],
          isPinned: false,
          createdAt: now,
          updatedAt: now,
          sync: SyncMetadata(
            lastModifiedLocal: now,
            isDirty: false,
            isDeleted: false,
            deviceId: 'test-device',
            syncRevision: 1,
          ),
        );

    final childNote = makeNote(
      'cardiology-note',
      'Cardiology Fixture',
      cardiology.uuid,
    );
    final otherSubjectNote = makeNote(
      'surgery-note',
      'Surgery Fixture',
      'root-2',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allLearningResourcesProvider.overrideWith((ref) async => const []),
          libraryRootsProvider.overrideWith((ref) async => nodes),
          libraryTaxonomyNodesProvider.overrideWith(
            (ref) async => [medicine, cardiology, nodes.last],
          ),
          allLibraryNotesProvider.overrideWith(
            (ref) async => [childNote, otherSubjectNote],
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const LibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open filters'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownButtonFormField<String?>).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medicine').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Open filters (1 active)'), findsOneWidget);
    expect(find.text('Cardiology Fixture'), findsOneWidget);
    expect(find.text('Surgery Fixture'), findsNothing);
    expect(find.text('1 note found'), findsOneWidget);
  });

  testWidgets('displays root taxonomy nodes', (tester) async {
    await tester.pumpWidget(buildTestApp(nodes));
    await tester.pumpAndSettle();

    expect(find.text('Medicine'), findsOneWidget);
    expect(find.text('Surgery'), findsOneWidget);
  });

  testWidgets('displays node type and note count', (tester) async {
    await tester.pumpWidget(buildTestApp(nodes));
    await tester.pumpAndSettle();

    expect(find.text('Subject · 10 notes'), findsOneWidget);
    expect(find.text('Subject · 5 notes'), findsOneWidget);
  });

  testWidgets('navigates to a root taxonomy node when tapped', (tester) async {
    final router = GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/library/node/:nodeUuid',
          builder: (context, state) => Scaffold(
            body: Text(
              'Node: ${state.pathParameters['nodeUuid']}',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allLearningResourcesProvider.overrideWith((ref) async => const []),
          libraryRootsProvider.overrideWith((ref) async => nodes),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Medicine'));
    await tester.pumpAndSettle();

    expect(find.text('Node: root-1'), findsOneWidget);
  });

  testWidgets('displays an empty state when no roots exist', (tester) async {
    await tester.pumpWidget(buildTestApp(const []));
    await tester.pumpAndSettle();

    expect(find.text('No library content yet'), findsOneWidget);
  });

  testWidgets('searches notes and displays matching results', (tester) async {
    final searchNote = Note(
      uuid: 'heart-note',
      topicUuid: 'cardiology-topic',
      mode: Mode.detailedNotes,
      title: 'Heart Failure',
      bodyMarkdown: 'Assessment and management of heart failure.',
      plainTextExtract: 'Assessment and management of heart failure.',
      tags: const ['Cardiology'],
      citationOrder: const [],
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allLearningResourcesProvider.overrideWith((ref) async => const []),
          libraryRootsProvider.overrideWith((ref) async => nodes),
          libraryTaxonomyNodesProvider.overrideWith((ref) async => nodes),
          noteSearchProvider('heart').overrideWith(
            (ref) async => [searchNote],
          ),
        ],
        child: const MaterialApp(
          home: LibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medicine'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'heart',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Heart Failure'), findsOneWidget);
    expect(find.textContaining('Cardiology'), findsOneWidget);
    expect(
      find.textContaining('Assessment and management of heart failure.'),
      findsOneWidget,
    );
    expect(find.text('Medicine'), findsNothing);
  });
  testWidgets('searches imported PDFs by title and original filename', (
    tester,
  ) async {
    final pdf = LearningResource(
      uuid: 'neurology-pdf',
      topicUuid: 'root-1',
      title: 'Neurology Review',
      originalFileName: 'lecture-2026.pdf',
      relativeFilePath: 'resources/lecture-2026.pdf',
      fileSizeBytes: 1024,
      importedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRootsProvider.overrideWith((ref) async => nodes),
          libraryTaxonomyNodesProvider.overrideWith((ref) async => nodes),
          noteSearchProvider('neuro').overrideWith((ref) async => []),
          noteSearchProvider('lecture').overrideWith((ref) async => []),
          allLearningResourcesProvider.overrideWith((ref) async => [pdf]),
        ],
        child: const MaterialApp(home: LibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);

    await tester.enterText(searchField, 'neuro');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Neurology Review'), findsOneWidget);
    expect(find.text('lecture-2026.pdf'), findsOneWidget);

    await tester.enterText(searchField, 'lecture');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Neurology Review'), findsOneWidget);
    expect(find.text('lecture-2026.pdf'), findsOneWidget);
  });

  testWidgets('waits for the search debounce before showing results',
      (tester) async {
    final searchNote = Note(
      uuid: 'heart-note',
      topicUuid: 'cardiology-topic',
      mode: Mode.detailedNotes,
      title: 'Heart Failure',
      bodyMarkdown: 'Assessment and management of heart failure.',
      plainTextExtract: 'Assessment and management of heart failure.',
      tags: const ['Cardiology'],
      citationOrder: const [],
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allLearningResourcesProvider.overrideWith((ref) async => const []),
          libraryRootsProvider.overrideWith((ref) async => nodes),
          libraryTaxonomyNodesProvider.overrideWith((ref) async => nodes),
          noteSearchProvider('heart').overrideWith(
            (ref) async => [searchNote],
          ),
        ],
        child: const MaterialApp(home: LibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'heart');
    await tester.pump(const Duration(milliseconds: 299));

    expect(find.text('Heart Failure'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Heart Failure'), findsOneWidget);
  });

  testWidgets('displays an empty state when search finds no notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allLearningResourcesProvider.overrideWith((ref) async => const []),
          libraryRootsProvider.overrideWith((ref) async => nodes),
          libraryTaxonomyNodesProvider.overrideWith((ref) async => nodes),
          noteSearchProvider('unknown').overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: LibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'unknown');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('No library results found for "unknown"'), findsOneWidget);
    expect(find.text('Medicine'), findsNothing);
  });

  testWidgets('clears search and restores library roots', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allLearningResourcesProvider.overrideWith((ref) async => const []),
          libraryRootsProvider.overrideWith((ref) async => nodes),
          libraryTaxonomyNodesProvider.overrideWith((ref) async => nodes),
          noteSearchProvider('unknown').overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: LibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'unknown');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('No library results found for "unknown"'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('No library results found for "unknown"'), findsNothing);
    expect(find.text('Medicine'), findsOneWidget);
    expect(find.text('Surgery'), findsOneWidget);
  });

  testWidgets('shows an excerpt around a match deep in the note',
      (tester) async {
    final now = DateTime(2026, 1, 1);
    final longText = List.filled(
          12,
          'Opening paragraph contains general background information.',
        ).join(' ') +
        ' The distinctiveMatchPhrase appears here with useful surrounding context.';

    final note = Note(
      uuid: 'deep-match-note',
      topicUuid: 'root-1',
      mode: Mode.detailedNotes,
      title: 'General Reference',
      bodyMarkdown: longText,
      plainTextExtract: longText,
      tags: const [],
      citationOrder: const [],
      isPinned: false,
      createdAt: now,
      updatedAt: now,
      sync: SyncMetadata(
        lastModifiedLocal: now,
        isDirty: false,
        isDeleted: false,
        deviceId: 'test-device',
        syncRevision: 1,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allLearningResourcesProvider.overrideWith((ref) async => const []),
          libraryRootsProvider.overrideWith((ref) async => nodes),
          libraryTaxonomyNodesProvider.overrideWith((ref) async => nodes),
          noteSearchProvider('distinctivematchphrase')
              .overrideWith((ref) async => [note]),
        ],
        child: const MaterialApp(home: LibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'distinctivematchphrase',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('General Reference'), findsOneWidget);
    expect(find.textContaining('distinctiveMatchPhrase'), findsOneWidget);
    expect(find.textContaining('Opening paragraph'), findsNothing);
  });

  testWidgets('ranks search results by relevance', (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final titleMatch = Note(
      uuid: 'asthma-title',
      topicUuid: 'respiratory-topic',
      mode: Mode.detailedNotes,
      title: 'Asthma',
      bodyMarkdown: 'Respiratory management notes.',
      plainTextExtract: 'Respiratory management notes.',
      tags: const ['Respiratory'],
      citationOrder: const [],
      isPinned: false,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      sync: SyncMetadata(
        lastModifiedLocal: DateTime(2025, 1, 1),
        isDirty: false,
        isDeleted: false,
        deviceId: 'test-device',
        syncRevision: 1,
      ),
    );

    final tagMatch = Note(
      uuid: 'asthma-tag',
      topicUuid: 'respiratory-topic',
      mode: Mode.detailedNotes,
      title: 'Respiratory Review',
      bodyMarkdown: 'Review of respiratory conditions.',
      plainTextExtract: 'Review of respiratory conditions.',
      tags: const ['Asthma'],
      citationOrder: const [],
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

    final extractMatch = Note(
      uuid: 'asthma-extract',
      topicUuid: 'respiratory-topic',
      mode: Mode.detailedNotes,
      title: 'Emergency Notes',
      bodyMarkdown: 'Emergency assessment notes.',
      plainTextExtract: 'Asthma exacerbation assessment.',
      tags: const ['Emergency'],
      citationOrder: const [],
      isPinned: false,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
      sync: SyncMetadata(
        lastModifiedLocal: DateTime(2026, 6, 1),
        isDirty: false,
        isDeleted: false,
        deviceId: 'test-device',
        syncRevision: 1,
      ),
    );

    final bodyMatch = Note(
      uuid: 'asthma-body',
      topicUuid: 'respiratory-topic',
      mode: Mode.detailedNotes,
      title: 'General Review',
      bodyMarkdown: 'Asthma treatment plan.',
      plainTextExtract: 'General respiratory management.',
      tags: const ['General'],
      citationOrder: const [],
      isPinned: false,
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
      sync: SyncMetadata(
        lastModifiedLocal: DateTime(2026, 10, 1),
        isDirty: false,
        isDeleted: false,
        deviceId: 'test-device',
        syncRevision: 1,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allLearningResourcesProvider.overrideWith((ref) async => const []),
          libraryRootsProvider.overrideWith((ref) async => nodes),
          libraryTaxonomyNodesProvider.overrideWith((ref) async => nodes),
          noteSearchProvider('asthma').overrideWith(
            (ref) async => [
              bodyMatch,
              extractMatch,
              tagMatch,
              titleMatch,
            ],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/library',
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'asthma');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final titleY = tester.getTopLeft(find.text('Asthma')).dy;
    final tagY = tester.getTopLeft(find.text('Respiratory Review')).dy;
    final extractY = tester.getTopLeft(find.text('Emergency Notes')).dy;
    final bodyY = tester.getTopLeft(find.text('General Review')).dy;

    expect(titleY, lessThan(tagY));
    expect(tagY, lessThan(extractY));
    expect(extractY, lessThan(bodyY));
  });

  testWidgets('hides internal details when the library fails to load',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allLearningResourcesProvider.overrideWith((ref) async => const []),
          libraryRootsProvider.overrideWith(
            (ref) async => throw Exception('sensitive internal detail'),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const LibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load the library'), findsOneWidget);
    expect(find.text('Please try again later.'), findsOneWidget);
    expect(find.textContaining('sensitive internal detail'), findsNothing);
  });

  testWidgets('hides internal details when note search fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allLearningResourcesProvider.overrideWith((ref) async => const []),
          libraryRootsProvider.overrideWith((ref) async => nodes),
          noteSearchProvider('heart').overrideWith(
            (ref) async => throw Exception('sensitive internal detail'),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const LibraryScreen(),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField),
      'heart',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Unable to search notes'), findsOneWidget);
    expect(find.text('Please try again later.'), findsOneWidget);
    expect(find.textContaining('sensitive internal detail'), findsNothing);
  });
}
