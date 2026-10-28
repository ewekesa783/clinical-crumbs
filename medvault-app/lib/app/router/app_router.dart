import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../debug/component_gallery_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/recent_history_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/library/presentation/screens/learning_resource_reader_screen.dart';
import '../../features/library/presentation/screens/note_reader_screen.dart';
import '../../features/library/presentation/screens/note_edit_screen.dart';
import '../../features/library/presentation/screens/taxonomy_browser_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../shell/medvault_shell.dart';

part 'app_router.g.dart';

@TypedGoRoute<LibraryRoute>(path: '/library')
class LibraryRoute extends GoRouteData {
  const LibraryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LibraryScreen();
  }
}

@TypedGoRoute<TaxonomyBrowserRoute>(path: '/library/node/:nodeUuid')
class TaxonomyBrowserRoute extends GoRouteData {
  const TaxonomyBrowserRoute({required this.nodeUuid});

  final String nodeUuid;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return TaxonomyBrowserScreen(nodeUuid: nodeUuid);
  }
}

@TypedGoRoute<LearningResourceReaderRoute>(
  path: '/library/resource/:resourceUuid',
)
class LearningResourceReaderRoute extends GoRouteData {
  const LearningResourceReaderRoute({required this.resourceUuid});

  final String resourceUuid;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return LearningResourceReaderScreen(resourceUuid: resourceUuid);
  }
}

@TypedGoRoute<NoteReaderRoute>(path: '/library/note/:noteUuid')
class NoteReaderRoute extends GoRouteData {
  const NoteReaderRoute({required this.noteUuid});

  final String noteUuid;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return NoteReaderScreen(noteUuid: noteUuid);
  }
}

@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsScreen();
  }
}

@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

@TypedGoRoute<ComponentGalleryRoute>(path: '/debug/component-gallery')
class ComponentGalleryRoute extends GoRouteData {
  const ComponentGalleryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ComponentGalleryScreen();
  }

  /// Guards the debug component gallery so it is unreachable outside
  /// debug builds.
  @override
  String? redirect(BuildContext context, GoRouterState state) {
    if (!kDebugMode) {
      return const HomeRoute().location;
    }
    return null;
  }
}

final GoRouter appRouter = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        final location = state.uri.path;
        final isLibraryRoot = location == '/library';
        final isSettingsRoot = location == '/settings';
        final shouldReturnToHome = isLibraryRoot || isSettingsRoot;

        return PopScope<Object?>(
          canPop: !shouldReturnToHome,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && shouldReturnToHome) {
              FocusManager.instance.primaryFocus?.unfocus();
              navigationShell.goBranch(0, initialLocation: true);
            }
          },
          child: MedVaultShell(
            onHomeSelected: () {
              if (navigationShell.currentIndex != 0) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
              navigationShell.goBranch(0, initialLocation: true);
            },
            onLibrarySelected: () {
              if (navigationShell.currentIndex != 1) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
              navigationShell.goBranch(1, initialLocation: false);
            },
            onSettingsSelected: () {
              if (navigationShell.currentIndex != 2) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
              navigationShell.goBranch(2, initialLocation: false);
            },
            child: navigationShell,
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'history',
                  builder: (context, state) => const RecentHistoryScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => LibraryScreen(
                focusSearchRequest: state.uri.queryParameters['focusSearch'],
              ),
              routes: [
                GoRoute(
                  path: 'node/:nodeUuid',
                  builder: (context, state) => TaxonomyBrowserScreen(
                    nodeUuid: state.pathParameters['nodeUuid']!,
                  ),
                ),
                GoRoute(
                  path: 'resource/:resourceUuid',
                  builder: (context, state) => LearningResourceReaderScreen(
                    resourceUuid: state.pathParameters['resourceUuid']!,
                  ),
                ),
                GoRoute(
                  path: 'note/:noteUuid',
                  builder: (context, state) => NoteReaderScreen(
                    noteUuid: state.pathParameters['noteUuid']!,
                  ),
                  routes: [
                    if (kDebugMode)
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => NoteEditScreen(
                          noteUuid: state.pathParameters['noteUuid']!,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    $componentGalleryRoute,
  ],
);
