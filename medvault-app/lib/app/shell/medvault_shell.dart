import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  int _selectedIndex(String location) {
    if (location == '/settings') return 2;

    if (location == '/library' || location.startsWith('/library/')) {
      return 1;
    }

    return 0;
  }

  void _selectDestination(int index) {
    switch (index) {
      case 0:
        onHomeSelected();
      case 1:
        onLibrarySelected();
      case 2:
        onSettingsSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _selectedIndex(location);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (scaffoldContext) => IconButton(
            tooltip: 'Open navigation menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
          ),
        ),
        title: Text(
          'Clinical Crumbs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: (theme.textTheme.titleLarge?.fontSize ?? 22) + 1,
          ),
        ),
        actions: [
          if (selectedIndex == 0)
            IconButton(
              tooltip: 'Search notes',
              onPressed: () => context.go(
                '/library?focusSearch=${DateTime.now().microsecondsSinceEpoch}',
              ),
              icon: const Icon(Icons.search),
            ),
          if (selectedIndex == 0) const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/branding/clinical_crumbs_logo.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Clinical Crumbs',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              _NavigationDrawerItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                selected: selectedIndex == 0,
                onTap: () => _selectDestination(0),
              ),
              _NavigationDrawerItem(
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book,
                label: 'Library',
                selected: selectedIndex == 1,
                customIcon: true,
                onTap: () => _selectDestination(1),
              ),
              _NavigationDrawerItem(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Settings',
                selected: selectedIndex == 2,
                onTap: () => _selectDestination(2),
              ),
              const Expanded(child: SizedBox()),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Clinical Crumbs',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          version == null ? '' : 'v$version',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}


class _NavigationDrawerItem extends StatelessWidget {
  const _NavigationDrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.customIcon = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool customIcon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final highlight = colors.secondaryContainer;
    final foreground = selected ? colors.primary : colors.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? highlight : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: customIcon
                  ? _ThreeBooksIcon(color: foreground)
                  : Icon(selected ? selectedIcon : icon, color: foreground),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 48,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: AppSpacing.md),
                decoration: BoxDecoration(
                  color: selected ? highlight : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(label, style: TextStyle(color: foreground)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreeBooksIcon extends StatelessWidget {
  const _ThreeBooksIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.collections_bookmark,
      color: color,
      size: 32,
    );
  }
}
