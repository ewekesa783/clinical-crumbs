import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/settings/data/appearance_preferences.dart';
import 'router/app_router.dart';

class MedVaultApp extends ConsumerWidget {
  const MedVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePreference = ref.watch(appearancePreferencesProvider);

    return MaterialApp.router(
      title: 'MedVault',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themePreference.themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
