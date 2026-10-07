import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/core/sync/sync_metadata.dart';
import '../../../../lib/features/library/domain/entities/taxonomy_node.dart';
import '../../../../lib/features/library/presentation/providers/taxonomy_browser_provider.dart';
import '../../../../lib/features/library/presentation/screens/taxonomy_browser_screen.dart';

TaxonomyNode makeNode({
  required String uuid,
  String? parentUuid,
  required String title,
  required String slug,
  required int depth,
  required int sortOrder,
  NodeType nodeType = NodeType.topic,
  String? shortDescription,
}) {
  return TaxonomyNode(
    uuid: uuid,
    parentUuid: parentUuid,
    path: parentUuid == null ? uuid : '$parentUuid/$uuid',
    depth: depth,
    nodeType: nodeType,
    title: title,
    slug: slug,
    shortDescription: shortDescription,
    sortOrder: sortOrder,
    noteCount: 0,
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
  );
}

Widget buildTestApp(TaxonomyBrowserData data) {
  return ProviderScope(
    overrides: [
      taxonomyBrowserProvider(data.node.uuid).overrideWith(
        (ref) async => data,
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: TaxonomyBrowserScreen(nodeUuid: data.node.uuid),
    ),
  );
}

void main() {
  final medicine = makeNode(
    uuid: 'medicine',
    title: 'Medicine',
    slug: 'medicine',
    depth: 0,
    sortOrder: 0,
    nodeType: NodeType.subject,
  );

  final cardiology = makeNode(
    uuid: 'cardiology',
    parentUuid: 'medicine',
    title: 'Cardiology',
    slug: 'cardiology',
    depth: 1,
    sortOrder: 0,
    shortDescription: 'Diseases and disorders of the cardiovascular system.',
  );

  final neurology = makeNode(
    uuid: 'neurology',
    parentUuid: 'medicine',
    title: 'Neurology',
    slug: 'neurology',
    depth: 1,
    sortOrder: 1,
    shortDescription: 'Disorders of the nervous system.',
  );

  testWidgets('displays the current node and breadcrumb', (tester) async {
    final data = TaxonomyBrowserData(
      node: medicine,
      breadcrumb: [medicine],
      children: [cardiology, neurology],
    );

    await tester.pumpWidget(buildTestApp(data));
    await tester.pumpAndSettle();

    expect(find.text('Medicine'), findsWidgets);
  });

  testWidgets('displays direct child taxonomy nodes', (tester) async {
    final data = TaxonomyBrowserData(
      node: medicine,
      breadcrumb: [medicine],
      children: [cardiology, neurology],
    );

    await tester.pumpWidget(buildTestApp(data));
    await tester.pumpAndSettle();

    expect(find.text('Cardiology'), findsOneWidget);
    expect(find.text('Neurology'), findsOneWidget);
    expect(
      find.text('Diseases and disorders of the cardiovascular system.'),
      findsOneWidget,
    );
  });

  testWidgets('displays the full breadcrumb path', (tester) async {
    final cardiologyNode = makeNode(
      uuid: 'cardiology',
      parentUuid: 'medicine',
      title: 'Cardiology',
      slug: 'cardiology',
      depth: 1,
      sortOrder: 0,
    );

    final data = TaxonomyBrowserData(
      node: cardiologyNode,
      breadcrumb: [medicine, cardiologyNode],
      children: const [],
    );

    await tester.pumpWidget(buildTestApp(data));
    await tester.pumpAndSettle();

    expect(find.text('Medicine'), findsOneWidget);
    expect(find.text('Cardiology'), findsWidgets);
  });

  testWidgets('displays empty state when a node has no children', (tester) async {
    final data = TaxonomyBrowserData(
      node: medicine,
      breadcrumb: [medicine],
      children: const [],
    );

    await tester.pumpWidget(buildTestApp(data));
    await tester.pumpAndSettle();

    expect(find.text('No subtopics yet'), findsOneWidget);
  });
}
