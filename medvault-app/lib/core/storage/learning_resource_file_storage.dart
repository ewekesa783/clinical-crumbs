import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/uuid_generator.dart';

/// Stores imported learning-resource files in MedVault's app-private directory.
///
/// Persist [relativeFilePath] values rather than absolute device-specific paths.
class LearningResourceFileStorage {
  LearningResourceFileStorage({
    UuidGenerator? uuidGenerator,
    Future<Directory> Function()? documentsDirectoryProvider,
    Future<Directory> Function()? temporaryDirectoryProvider,
  })  : _uuidGenerator = uuidGenerator ?? UuidGenerator(),
        _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
        _temporaryDirectoryProvider =
            temporaryDirectoryProvider ?? getTemporaryDirectory;

  static const String _managedDirectoryName = 'learning_resources';
  static const String _pdfDirectoryName = 'pdfs';

  final UuidGenerator _uuidGenerator;
  final Future<Directory> Function() _documentsDirectoryProvider;
  final Future<Directory> Function() _temporaryDirectoryProvider;

  Future<Directory> _pdfDirectory() async {
    final documentsDirectory = await _documentsDirectoryProvider();
    final directory = Directory(
      '${documentsDirectory.path}/$_managedDirectoryName/$_pdfDirectoryName',
    );

    await directory.create(recursive: true);
    return directory;
  }

  static const String _htmlLessonDirectoryName = 'html_lessons';

  Future<Directory> _htmlLessonDirectory() async {
    final documentsDirectory = await _documentsDirectoryProvider();
    final directory = Directory(
      '${documentsDirectory.path}/$_managedDirectoryName/$_htmlLessonDirectoryName',
    );

    await directory.create(recursive: true);
    return directory;
  }

  /// Copies an HTML lesson ZIP package into managed storage.
  ///
  /// Package validation must happen before this method is called.
  /// The source file is left untouched.
  Future<String> importHtmlLessonPackage(String sourceFilePath) async {
    final source = File(sourceFilePath);

    if (!await source.exists()) {
      throw FileSystemException(
        'The selected HTML lesson package does not exist.',
        sourceFilePath,
      );
    }

    final directory = await _htmlLessonDirectory();
    final fileName = '${_uuidGenerator.call()}.zip';
    final destination = File('${directory.path}/$fileName');

    await source.copy(destination.path);

    return '$_managedDirectoryName/$_htmlLessonDirectoryName/$fileName';
  }

  /// Saves an already-packaged HTML or structured lesson ZIP in managed storage.
  ///
  /// The caller must validate the package before calling this method.
  Future<String> importHtmlLessonPackageBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw ArgumentError.value(
          bytes, 'bytes', 'Lesson package cannot be empty.');
    }

    final directory = await _htmlLessonDirectory();
    final fileName = '${_uuidGenerator.call()}.zip';
    final destination = File('${directory.path}/$fileName');

    await destination.writeAsBytes(bytes, flush: true);

    return '$_managedDirectoryName/$_htmlLessonDirectoryName/$fileName';
  }

  /// Resolves a managed HTML lesson ZIP package for reading.
  ///
  /// Paths outside the dedicated HTML lesson directory are rejected.
  Future<File> resolveHtmlLessonPackage(String relativeFilePath) async {
    final segments = relativeFilePath.split(RegExp(r'[/\\]'));

    if (segments.length != 3 ||
        segments[0] != _managedDirectoryName ||
        segments[1] != _htmlLessonDirectoryName ||
        !RegExp(r'^[0-9a-fA-F-]+\.zip$').hasMatch(segments[2])) {
      throw ArgumentError.value(
        relativeFilePath,
        'relativeFilePath',
        'Expected a path inside managed HTML lesson storage.',
      );
    }

    final directory = await _htmlLessonDirectory();
    final file = File('${directory.path}/${segments[2]}');

    if (!await file.exists()) {
      throw FileSystemException(
        'The stored HTML lesson package could not be found.',
        file.path,
      );
    }

    return file;
  }

  /// Deletes a managed HTML lesson package.
  Future<void> deleteHtmlLessonPackage(String relativeFilePath) async {
    final file = await resolveHtmlLessonPackage(relativeFilePath);
    await file.delete();
  }

  /// Extracts a validated copy of a stored lesson ZIP into temporary storage.
  ///
  /// The original ZIP remains unchanged. All archive paths are validated
  /// before any extracted files are written.
  Future<File> prepareHtmlLessonFile(String relativeFilePath) async {
    final package = await resolveHtmlLessonPackage(relativeFilePath);
    final segments = relativeFilePath.split(RegExp(r'[/\\\\]'));
    final packageId = segments[2].substring(0, segments[2].length - 4);

    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(packageId)) {
      throw ArgumentError.value(
        relativeFilePath,
        'relativeFilePath',
        'Expected a lesson package with a UUID filename.',
      );
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await package.readAsBytes());
    } catch (_) {
      throw const FormatException('The lesson ZIP could not be decoded.');
    }

    final entries = <String, ArchiveFile>{};
    for (final entry in archive.files) {
      var name = entry.name;
      if (!entry.isFile && name.endsWith('/')) {
        name = name.substring(0, name.length - 1);
      }

      if (name.startsWith('/') ||
          name.contains(r'\\') ||
          RegExp(r'^[A-Za-z]:').hasMatch(name) ||
          name.split('/').any(
                (part) => part.isEmpty || part == '.' || part == '..',
              )) {
        throw const FormatException('Invalid ZIP entry path.');
      }

      if (!entry.isFile) continue;
      if (entries.containsKey(name)) {
        throw const FormatException('Duplicate ZIP entry.');
      }
      entries[name] = entry;
    }

    final htmlName =
        entries.containsKey('index.html') ? 'index.html' : 'preview/index.html';
    if (!entries.containsKey(htmlName)) {
      throw const FormatException(
        'The lesson ZIP must contain index.html or preview/index.html.',
      );
    }

    final temporaryDirectory = await _temporaryDirectoryProvider();
    final cacheRoot = Directory(
      '${temporaryDirectory.path}/clinical_crumbs_html_lessons',
    );
    await cacheRoot.create(recursive: true);

    final extractionDirectory = Directory(
      '${cacheRoot.path}/$packageId',
    );
    if (await extractionDirectory.exists()) {
      await extractionDirectory.delete(recursive: true);
    }
    await extractionDirectory.create(recursive: true);

    try {
      for (final entry in entries.entries) {
        final destination = File(
          '${extractionDirectory.path}/${entry.key}',
        );
        await destination.parent.create(recursive: true);
        await destination.writeAsBytes(
          entry.value.content as List<int>,
          flush: true,
        );
      }
    } catch (_) {
      if (await extractionDirectory.exists()) {
        await extractionDirectory.delete(recursive: true);
      }
      rethrow;
    }

    return File('${extractionDirectory.path}/$htmlName');
  }

  /// Copies [sourceFilePath] into managed storage and returns its relative path.
  ///
  /// The source file is left untouched.
  Future<String> importPdf(String sourceFilePath) async {
    final source = File(sourceFilePath);

    if (!await source.exists()) {
      throw FileSystemException(
        'The selected PDF file does not exist.',
        sourceFilePath,
      );
    }

    final directory = await _pdfDirectory();
    final fileName = '${_uuidGenerator.call()}.pdf';
    final destination = File('${directory.path}/$fileName');

    await source.copy(destination.path);

    return '$_managedDirectoryName/$_pdfDirectoryName/$fileName';
  }

  /// Restores a PDF using its existing resource UUID.
  ///
  /// Unlike [importPdf], this preserves the filename and refuses to overwrite
  /// an existing file. Intended for validated backup restoration only.
  Future<String> restorePdf({
    required String uuid,
    required List<int> bytes,
  }) async {
    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(uuid);

    if (!isUuid) {
      throw ArgumentError.value(uuid, 'uuid', 'Expected a valid UUID.');
    }

    if (bytes.length < 5 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46 ||
        bytes[4] != 0x2D) {
      throw ArgumentError('The supplied bytes do not begin with a PDF header.');
    }

    final directory = await _pdfDirectory();
    final fileName = '$uuid.pdf';
    final destination = File('${directory.path}/$fileName');

    // Claim the destination exclusively so an existing file is never overwritten.
    await destination.create(exclusive: true);
    final handle = await destination.open(mode: FileMode.writeOnly);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } catch (_) {
      await handle.close();
      if (await destination.exists()) {
        await destination.delete();
      }
      rethrow;
    }
    await handle.close();

    return '$_managedDirectoryName/$_pdfDirectoryName/$fileName';
  }

  /// Resolves a managed relative path to a file for reading.
  ///
  /// Paths outside the managed resource directory are rejected.
  /// Replaces an existing managed PDF after validating and staging new bytes.
  ///
  /// This is intentionally separate from [restorePdf], which must refuse
  /// overwrites during backup restoration.
  Future<void> replaceManagedPdf({
    required String relativeFilePath,
    required List<int> bytes,
  }) async {
    final destination = await resolvePdf(relativeFilePath);
    if (bytes.length < 5 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46 ||
        bytes[4] != 0x2d) {
      throw const FormatException('The replacement is not a valid PDF file.');
    }

    final directory = destination.parent;
    final staged = File(
      '${directory.path}/.${destination.uri.pathSegments.last}.replacement',
    );
    final rollback = File(
      '${directory.path}/.${destination.uri.pathSegments.last}.rollback',
    );

    if (await staged.exists() || await rollback.exists()) {
      throw FileSystemException(
        'A previous PDF replacement operation has not been cleaned up.',
        destination.path,
      );
    }

    try {
      await staged.writeAsBytes(bytes, flush: true);
      await destination.rename(rollback.path);
      try {
        await staged.rename(destination.path);
      } catch (_) {
        await rollback.rename(destination.path);
        rethrow;
      }
      await rollback.delete();
    } catch (_) {
      if (!await destination.exists() && await rollback.exists()) {
        await rollback.rename(destination.path);
      }
      if (await staged.exists()) {
        await staged.delete();
      }
      rethrow;
    }
  }

  Future<File> resolvePdf(String relativeFilePath) async {
    final segments = relativeFilePath.split(RegExp(r'[/\\]'));

    if (segments.length != 3 ||
        segments[0] != _managedDirectoryName ||
        segments[1] != _pdfDirectoryName ||
        segments[2].isEmpty ||
        segments[2] == '.' ||
        segments[2] == '..') {
      throw ArgumentError.value(
        relativeFilePath,
        'relativeFilePath',
        'Expected a path inside MedVault managed PDF storage.',
      );
    }

    final directory = await _pdfDirectory();
    final file = File('${directory.path}/${segments[2]}');

    if (!await file.exists()) {
      throw FileSystemException(
        'The stored learning-resource PDF could not be found.',
        file.path,
      );
    }

    return file;
  }

  /// Deletes a managed PDF. Call only when the corresponding resource is removed.
  Future<bool> hasSameContent(
    String sourceFilePath,
    String relativeFilePath,
  ) async {
    final source = File(sourceFilePath);
    final stored = await resolvePdf(relativeFilePath);

    if (await source.length() != await stored.length()) {
      return false;
    }

    final sourceHandle = await source.open();
    final storedHandle = await stored.open();

    try {
      while (true) {
        const chunkSize = 64 * 1024;
        final sourceChunk = await sourceHandle.read(chunkSize);
        final storedChunk = await storedHandle.read(chunkSize);

        if (sourceChunk.length != storedChunk.length) {
          return false;
        }

        if (sourceChunk.isEmpty) {
          return true;
        }

        for (var i = 0; i < sourceChunk.length; i++) {
          if (sourceChunk[i] != storedChunk[i]) {
            return false;
          }
        }
      }
    } finally {
      await sourceHandle.close();
      await storedHandle.close();
    }
  }

  Future<void> deletePdf(String relativeFilePath) async {
    final file = await resolvePdf(relativeFilePath);
    await file.delete();
  }
}
