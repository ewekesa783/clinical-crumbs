import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Directory tempDirectory;
  late String packageDirectory;

  setUp(() async {
    tempDirectory =
        await Directory.systemTemp.createTemp('medvault_toolkit_test_');
    packageDirectory = Directory.current.path;
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Future<ProcessResult> runValidator(String path) {
    return Process.run(
      Platform.resolvedExecutable,
      [
        'run',
        'bin/medvault_toolkit.dart',
        'validate',
        path,
      ],
      workingDirectory: packageDirectory,
    );
  }

  test('accepts a structurally valid synthetic pack', () async {
    final file = File('${tempDirectory.path}/valid-pack.json');
    await file.writeAsString(jsonEncode({
      'manifest': {
        'formatVersion': 1,
        'packUuid': 'demo-pack-001',
        'version': 1,
        'title': 'Synthetic Demo Pack',
      },
      'taxonomyNodes': [
        {
          'uuid': 'demo-topic',
          'nodeType': 'topic',
          'title': 'Paper Folding',
          'slug': 'paper-folding',
          'sortOrder': 0,
        },
      ],
      'notes': [],
      'citations': [],
    }));

    final result = await runValidator(file.path);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Curriculum pack is structurally valid.'));
    expect(result.stdout, contains('Taxonomy nodes: 1'));
    expect(result.stdout, contains('Notes: 0'));
    expect(result.stdout, contains('Citations: 0'));
  });

  test('rejects a pack with an unsupported format version', () async {
    final file = File('${tempDirectory.path}/invalid-pack.json');
    await file.writeAsString(jsonEncode({
      'manifest': {
        'formatVersion': 999,
        'packUuid': 'demo-pack-002',
        'version': 1,
        'title': 'Invalid Synthetic Pack',
      },
      'taxonomyNodes': [],
      'notes': [],
      'citations': [],
    }));

    final result = await runValidator(file.path);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('Unsupported format version 999'));
  });

  test('reports a missing pack file', () async {
    final missingPath = '${tempDirectory.path}/missing-pack.json';

    final result = await runValidator(missingPath);

    expect(result.exitCode, 66);
    expect(result.stderr, contains('file not found'));
  });
}
