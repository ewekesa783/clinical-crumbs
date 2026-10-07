import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../debug/component_gallery_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/library/presentation/screens/taxonomy_browser_screen.dart';
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
    ShellRoute(
      builder: (context, state, child) {
        return MedVaultShell(
          onHomeSelected: () => const HomeRoute().go(context),
          onLibrarySelected: () => const LibraryRoute().go(context),
          child: child,
        );
      },
      routes: [
        $homeRoute,
        $libraryRoute,
        $taxonomyBrowserRoute,
      ],
    ),
    $componentGalleryRoute,
  ],
);
