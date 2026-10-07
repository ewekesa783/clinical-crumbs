import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../lib/app/router/app_router.dart';
import '../../../../lib/core/sync/sync_metadata.dart';
import '../../../../lib/features/library/domain/entities/taxonomy_node.dart';
import '../../../../lib/features/library/presentation/providers/library_roots_provider.dart';
import '../../../../lib/features/library/presentation/screens/library_screen.dart';

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
}
