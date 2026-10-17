import 'dart:convert';
import 'dart:io';

import 'package:medvault_shared/medvault_shared.dart';
void main(List<String> arguments) {



  try {
    if (arguments.isEmpty || arguments.contains('--help') ||
        arguments.contains('-h')) {
      _printUsage();
      return;
    }

    final command = arguments.first;

    switch (command) {
      case 'validate':
        final positional = arguments.skip(1).toList();

        if (positional.length != 1) {
          stderr.writeln(
            'Usage error: validate requires exactly one JSON file path.',
          );
          _printUsage();
          exitCode = 64;
          return;
        }

        _validateFile(File(positional.single));
        return;

      case 'help':
        _printUsage();
        return;

      default:
        stderr.writeln('Unknown command: $command');
        _printUsage();
        exitCode = 64;
        return;
    }
  } on FormatException catch (error) {
    stderr.writeln('Invalid command arguments: ${error.message}');
    _printUsage();
    exitCode = 64;
  }
}

void _validateFile(File file) {
  if (!file.existsSync()) {
    stderr.writeln('Validation failed: file not found: ${file.path}');
    exitCode = 66;
    return;
  }

  try {
    final decoded = jsonDecode(file.readAsStringSync());

    if (decoded is! Map) {
      stderr.writeln(
        'Validation failed: the JSON document must be an object.',
      );
      exitCode = 1;
      return;
    }

    final pack = CurriculumPack.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    final result = const CurriculumPackValidator().validate(pack);

    if (result.isValid) {
      stdout.writeln('Curriculum pack is structurally valid.');
      stdout.writeln('Pack: ${pack.manifest.title}');
      stdout.writeln('UUID: ${pack.manifest.packUuid}');
      stdout.writeln('Version: ${pack.manifest.version}');
      stdout.writeln('Taxonomy nodes: ${pack.taxonomyNodes.length}');
      stdout.writeln('Notes: ${pack.notes.length}');
      stdout.writeln('Citations: ${pack.citations.length}');
      exitCode = 0;
      return;
    }

    stderr.writeln(
      'Validation failed with ${result.issues.length} issue(s):',
    );
    for (final issue in result.issues) {
      stderr.writeln('- $issue');
    }
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln('Validation failed: invalid JSON: ${error.message}');
    exitCode = 1;
  } on TypeError catch (error) {
    stderr.writeln('Validation failed: malformed pack structure: $error');
    exitCode = 1;
  } on ArgumentError catch (error) {
    stderr.writeln('Validation failed: malformed pack structure: $error');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Could not read pack file: ${error.message}');
    exitCode = 74;
  }
}

void _printUsage() {
  stdout.writeln('''
MedVault Toolkit — curriculum-pack authoring tools

Usage:
  dart run bin/medvault_toolkit.dart validate <pack.json>
  dart run bin/medvault_toolkit.dart help

Commands:
  validate   Validate a curriculum-pack JSON file without modifying it.
  help       Show this help message.

Validation checks structure and references only. It does not assess
the medical accuracy of authored content.
''');
}
