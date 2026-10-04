import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Isar isar = await bootstrap();

  runApp(
    ProviderScope(
      overrides: [
        isarInstanceProvider.overrideWithValue(isar),
      ],
      child: const MedVaultApp(),
    ),
  );
}
