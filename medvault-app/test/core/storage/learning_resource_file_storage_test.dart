import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/storage/learning_resource_file_storage.dart';

void main() {
  late Directory tempDir;
  late LearningResourceFileStorage storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('medvault_file_storage_');
    storage = LearningResourceFileStorage(
      documentsDirectoryProvider: () async => tempDir,
      temporaryDirectoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('imports a PDF into managed storage and preserves the source', () async {
    final source = File('${tempDir.path}/original.pdf');
    await source.writeAsBytes([37, 80, 68, 70, 45, 49]);

    final relativePath = await storage.importPdf(source.path);
    final storedFile = await storage.resolvePdf(relativePath);

    expect(
      relativePath,
      matches(RegExp(r'^learning_resources/pdfs/[0-9a-f-]+\.pdf$')),
    );
    expect(await storedFile.readAsBytes(), [37, 80, 68, 70, 45, 49]);
    expect(await source.exists(), isTrue);
  });

  test('imports with unique paths for separate files', () async {
    final first = File('${tempDir.path}/first.pdf');
    final second = File('${tempDir.path}/second.pdf');
    await first.writeAsBytes([1, 2, 3]);
    await second.writeAsBytes([4, 5, 6]);

    final firstPath = await storage.importPdf(first.path);
    final secondPath = await storage.importPdf(second.path);

    expect(firstPath, isNot(secondPath));
  });

  test('rejects a source file that does not exist', () async {
    expect(
      () => storage.importPdf('${tempDir.path}/missing.pdf'),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('rejects paths outside managed PDF storage', () async {
    expect(
      () => storage.resolvePdf('../private.pdf'),
      throwsArgumentError,
    );
    expect(
      () => storage.resolvePdf('learning_resources/pdfs/../../private.pdf'),
      throwsArgumentError,
    );
  });

  test('deletes a stored PDF', () async {
    final source = File('${tempDir.path}/source.pdf');
    await source.writeAsBytes([1, 2, 3]);

    final relativePath = await storage.importPdf(source.path);
    final storedFile = await storage.resolvePdf(relativePath);

    await storage.deletePdf(relativePath);

    expect(await storedFile.exists(), isFalse);
    expect(await source.exists(), isTrue);
  });

  test('replaces a managed PDF while preserving its relative path', () async {
    final original = File('${tempDir.path}/original.pdf');
    await original.writeAsBytes([37, 80, 68, 70, 45, 49]);
    final relativePath = await storage.importPdf(original.path);

    await storage.replaceManagedPdf(
      relativeFilePath: relativePath,
      bytes: [37, 80, 68, 70, 45, 50],
    );

    final stored = await storage.resolvePdf(relativePath);
    expect(await stored.readAsBytes(), [37, 80, 68, 70, 45, 50]);
    expect(await stored.exists(), isTrue);
  });

  test('rejects invalid replacement PDF bytes without changing original',
      () async {
    final original = File('${tempDir.path}/original.pdf');
    await original.writeAsBytes([37, 80, 68, 70, 45, 49]);
    final relativePath = await storage.importPdf(original.path);

    await expectLater(
      storage.replaceManagedPdf(
        relativeFilePath: relativePath,
        bytes: [1, 2, 3, 4, 5],
      ),
      throwsA(isA<FormatException>()),
    );

    final stored = await storage.resolvePdf(relativePath);
    expect(await stored.readAsBytes(), [37, 80, 68, 70, 45, 49]);
  });

  test('recognizes PDFs with identical content', () async {
    final original = File('${tempDir.path}/original.pdf');
    final duplicate = File('${tempDir.path}/duplicate.pdf');
    await original.writeAsBytes([37, 80, 68, 70, 45, 49]);
    await duplicate.writeAsBytes([37, 80, 68, 70, 45, 49]);

    final relativePath = await storage.importPdf(original.path);

    expect(
      await storage.hasSameContent(duplicate.path, relativePath),
      isTrue,
    );
  });

  test('recognizes PDFs with different content', () async {
    final original = File('${tempDir.path}/original.pdf');
    final different = File('${tempDir.path}/different.pdf');
    await original.writeAsBytes([37, 80, 68, 70, 45, 49]);
    await different.writeAsBytes([37, 80, 68, 70, 45, 50]);

    final relativePath = await storage.importPdf(original.path);

    expect(
      await storage.hasSameContent(different.path, relativePath),
      isFalse,
    );
  });

  test('imports an HTML lesson package into managed storage', () async {
    final source = File('${tempDir.path}/lesson.zip');
    await source.writeAsBytes([80, 75, 3, 4, 1, 2, 3]);

    final relativePath = await storage.importHtmlLessonPackage(source.path);
    final storedFile = await storage.resolveHtmlLessonPackage(relativePath);

    expect(
      relativePath,
      matches(RegExp(r'^learning_resources/html_lessons/[0-9a-f-]+\.zip$')),
    );
    expect(await storedFile.readAsBytes(), [80, 75, 3, 4, 1, 2, 3]);
    expect(await source.exists(), isTrue);
  });

  test('imports HTML lesson package bytes into managed storage', () async {
    final packageBytes = [80, 75, 3, 4, 1, 2, 3];

    final relativePath = await storage.importHtmlLessonPackageBytes(
      Uint8List.fromList(packageBytes),
    );
    final storedFile = await storage.resolveHtmlLessonPackage(relativePath);

    expect(
      relativePath,
      matches(RegExp(r'^learning_resources/html_lessons/[0-9a-f-]+\.zip$')),
    );
    expect(await storedFile.readAsBytes(), packageBytes);
  });

  test('rejects empty HTML lesson package bytes', () async {
    expect(
      () => storage.importHtmlLessonPackageBytes(Uint8List(0)),
      throwsArgumentError,
    );
  });

  test('rejects paths outside managed HTML lesson storage', () async {
    expect(
      () => storage.resolveHtmlLessonPackage('../private.zip'),
      throwsArgumentError,
    );
    expect(
      () => storage.resolveHtmlLessonPackage(
        'learning_resources/pdfs/12345678.zip',
      ),
      throwsArgumentError,
    );
    expect(
      () => storage.resolveHtmlLessonPackage(
        'learning_resources/html_lessons/../../private.zip',
      ),
      throwsArgumentError,
    );
  });

  test('deletes a stored HTML lesson package', () async {
    final source = File('${tempDir.path}/lesson.zip');
    await source.writeAsBytes([80, 75, 3, 4]);

    final relativePath = await storage.importHtmlLessonPackage(source.path);
    final storedFile = await storage.resolveHtmlLessonPackage(relativePath);

    await storage.deleteHtmlLessonPackage(relativePath);

    expect(await storedFile.exists(), isFalse);
    expect(await source.exists(), isTrue);
  });

  test('rejects a missing HTML lesson package source', () async {
    expect(
      () => storage.importHtmlLessonPackage(
        '${tempDir.path}/missing.zip',
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('extracts an HTML lesson and its relative assets to temporary storage',
      () async {
    final archive = Archive()
      ..addFile(
        ArchiveFile(
          'preview/index.html',
          utf8
              .encode(
                  '<html><body><img src="../assets/example.svg"></body></html>')
              .length,
          utf8.encode(
              '<html><body><img src="../assets/example.svg"></body></html>'),
        ),
      )
      ..addFile(
        ArchiveFile(
          'assets/example.svg',
          utf8.encode('<svg xmlns="http://www.w3.org/2000/svg"></svg>').length,
          utf8.encode('<svg xmlns="http://www.w3.org/2000/svg"></svg>'),
        ),
      );
    final source = File('${tempDir.path}/lesson.zip');
    await source.writeAsBytes(ZipEncoder().encode(archive));

    final relativePath = await storage.importHtmlLessonPackage(source.path);
    final storedPackage = await storage.resolveHtmlLessonPackage(relativePath);
    final htmlFile = await storage.prepareHtmlLessonFile(relativePath);
    final assetFile = File(
      '${htmlFile.parent.parent.path}/assets/example.svg',
    );

    expect(await htmlFile.exists(), isTrue);
    expect(await htmlFile.readAsString(), contains('<html>'));
    expect(await assetFile.readAsString(), contains('<svg'));
    expect(await storedPackage.exists(), isTrue);
    expect(await storedPackage.readAsBytes(), await source.readAsBytes());
  });

  test('rejects unsafe paths inside an HTML lesson ZIP', () async {
    final archive = Archive()
      ..addFile(
        ArchiveFile(
          'index.html',
          utf8.encode('<html><body>Lesson</body></html>').length,
          utf8.encode('<html><body>Lesson</body></html>'),
        ),
      )
      ..addFile(ArchiveFile('../outside.txt', 1, [1]));
    final source = File('${tempDir.path}/unsafe.zip');
    await source.writeAsBytes(ZipEncoder().encode(archive));

    final relativePath = await storage.importHtmlLessonPackage(source.path);

    expect(
      () => storage.prepareHtmlLessonFile(relativePath),
      throwsFormatException,
    );
    expect(await storage.resolveHtmlLessonPackage(relativePath), isA<File>());
  });
}
