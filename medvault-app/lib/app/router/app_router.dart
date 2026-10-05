import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../debug/component_gallery_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

part 'app_router.g.dart';

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
  routes: $appRoutes,
);
