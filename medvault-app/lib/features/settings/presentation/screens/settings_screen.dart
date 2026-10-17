import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/appearance_preferences.dart';
import '../../data/reading_preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(appearancePreferencesProvider);
    final controller = ref.read(appearancePreferencesProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Personalise how MedVault looks on your device.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final preference in AppThemePreference.values)
                  RadioListTile<AppThemePreference>(
                    value: preference,
                    groupValue: selectedTheme,
                    title: Text(preference.label),
                    subtitle: Text(_descriptionFor(preference)),
                    secondary: Icon(_iconFor(preference)),
                    onChanged: (value) {
                      if (value != null) {
                        controller.setThemePreference(value);
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Reading',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final size in AppReadingTextSize.values)
                  RadioListTile<AppReadingTextSize>(
                    value: size,
                    groupValue: ref.watch(readingPreferencesProvider),
                    title: Text(size.label),
                    subtitle: Text(size.description),
                    secondary: Icon(
                      size == AppReadingTextSize.small
                          ? Icons.text_fields
                          : size == AppReadingTextSize.normal
                              ? Icons.format_size
                              : Icons.text_increase,
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(readingPreferencesProvider.notifier)
                            .setTextSize(value);
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Data & backup',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.backup_outlined),
              title: Text('Back up your library'),
              subtitle: Text(
                'Use Export in the Library to create a portable JSON backup.',
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('MedVault'),
              subtitle: Text(
                'Your personal, offline-first learning library.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _descriptionFor(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.system:
        return 'Follow your device appearance setting';
      case AppThemePreference.light:
        return 'Use a bright interface';
      case AppThemePreference.dark:
        return 'Use a darker interface';
    }
  }

  IconData _iconFor(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.system:
        return Icons.settings_suggest_outlined;
      case AppThemePreference.light:
        return Icons.light_mode_outlined;
      case AppThemePreference.dark:
        return Icons.dark_mode_outlined;
    }
  }
}
