import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/settings/data/appearance_preferences.dart';
import '../features/settings/data/reading_preferences.dart';
import 'router/app_router.dart';

class MedVaultApp extends ConsumerWidget {
  const MedVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePreference = ref.watch(appearancePreferencesProvider);
    final readingSize = ref.watch(readingPreferencesProvider);

    return MaterialApp.router(
      title: 'Clinical Crumbs',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themePreference.themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(readingSize.scale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
