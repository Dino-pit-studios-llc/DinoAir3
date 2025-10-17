// Shell scaffold with navigation drawer for primary app sections.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/app_drawer.dart';
import '../core/navigation/drawer_sections.dart';
import '../core/navigation/navigation_item.dart';
import 'app_routes.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final NavigationItem? activeItem = _findActiveItem(location);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            key: const Key('open_drawer_button'),
            icon: const Icon(Icons.menu),
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(activeItem?.title ?? 'DinoAir Control Center'),
      ),
      drawer: AppDrawer(currentLocation: location),
      body: SafeArea(child: child),
    );
  }

  NavigationItem? _findActiveItem(String location) {
    for (final section in drawerSections) {
      for (final item in section.items) {
        if (_matchesRoute(location, item.route)) {
          return item;
        }
      }
    }
    return null;
  }

  bool _matchesRoute(String location, String route) {
    if (route == AppRoutes.home) {
      return location == AppRoutes.home;
    }
    if (route == AppRoutes.cryptoDashboard) {
      return location.startsWith('/crypto');
    }
    return location == route || location.startsWith('$route/');
  }
}
