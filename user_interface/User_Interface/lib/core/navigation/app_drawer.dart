import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import 'drawer_sections.dart';
import 'navigation_item.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentLocation});

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildHeader(context),
            for (final section in drawerSections) ...[
              _DrawerSection(
                section: section,
                currentLocation: currentLocation,
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DrawerHeader(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DinoAir Control Center',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Headless services & crypto toolkit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.section,
    required this.currentLocation,
  });

  final NavigationSection section;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              section.title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ...section.items.map(
            (item) => _DrawerItem(
              item: item,
              selected: _isSelected(item),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSelected(NavigationItem item) {
    if (currentLocation == item.route) {
      return true;
    }
    if (item.route == AppRoutes.cryptoDashboard) {
      return currentLocation.startsWith('/crypto');
    }
    return currentLocation.startsWith('${item.route}/');
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.item, required this.selected});

  final NavigationItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.title),
      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
      selected: selected,
      onTap: () {
        Navigator.of(context).pop();
        // Use context.pushReplacement to avoid building navigation stack.
        context.go(item.route);
      },
    );
  }
}
