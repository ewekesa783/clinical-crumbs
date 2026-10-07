import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/spacing_tokens.dart';

class MedVaultShell extends StatelessWidget {
  const MedVaultShell({
    required this.child,
    required this.onHomeSelected,
    required this.onLibrarySelected,
    super.key,
  });

  final Widget child;
  final VoidCallback onHomeSelected;
  final VoidCallback onLibrarySelected;

  static const double _mobileBreakpoint = 720;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isLibrary = location == '/library';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;

        if (isMobile) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: isLibrary ? 1 : 0,
              onDestinationSelected: (index) {
                if (index == 0) {
                  onHomeSelected();
                } else {
                  onLibrarySelected();
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
                            selectedIndex: isLibrary ? 1 : 0,
                            onDestinationSelected: (index) {
                              if (index == 0) {
                                onHomeSelected();
                              } else {
                                onLibrarySelected();
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
