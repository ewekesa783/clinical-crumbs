import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
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
        libraryRootsProvider.overrideWith((ref) async => roots),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const LibraryScreen(),
      ),
    );
  }

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
          libraryRootsProvider.overrideWith((ref) async => nodes),
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
    await tester.pumpAndSettle();

    expect(find.text('Heart Failure'), findsOneWidget);
    expect(find.textContaining('Cardiology'), findsOneWidget);
    expect(find.text('Medicine'), findsNothing);
  });
}
