import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/spacing_tokens.dart';

class MedVaultShell extends StatelessWidget {
  const MedVaultShell({
    required this.child,
    required this.onHomeSelected,
    required this.onLibrarySelected,
    required this.onSettingsSelected,
    super.key,
  });

  final Widget child;
  final VoidCallback onHomeSelected;
  final VoidCallback onLibrarySelected;
  final VoidCallback onSettingsSelected;

  static const double _mobileBreakpoint = 720;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isLibrary = location == '/library' ||
        location.startsWith('/library/node/') ||
        location.startsWith('/library/note/');
    final isSettings = location == '/settings';
    final selectedIndex = isSettings ? 2 : (isLibrary ? 1 : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;

        if (isMobile) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    onHomeSelected();
                  case 1:
                    onLibrarySelected();
                  case 2:
                    onSettingsSelected();
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Library',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 220,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.md,
                            ),
                            child: Text(
                              'MedVault',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          NavigationRail(
                            selectedIndex: selectedIndex,
                            onDestinationSelected: (index) {
                              switch (index) {
                                case 0:
                                  onHomeSelected();
                                case 1:
                                  onLibrarySelected();
                                case 2:
                                  onSettingsSelected();
                              }
                            },
                            labelType: NavigationRailLabelType.all,
                            destinations: const [
                              NavigationRailDestination(
                                icon: Icon(Icons.home_outlined),
                                selectedIcon: Icon(Icons.home),
                                label: Text('Home'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.menu_book_outlined),
                                selectedIcon: Icon(Icons.menu_book),
                                label: Text('Library'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.settings_outlined),
                                selectedIcon: Icon(Icons.settings),
                                label: Text('Settings'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
