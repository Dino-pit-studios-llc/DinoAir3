import 'package:flutter/material.dart';

/// Simple navigation item representation for the application drawer.
class NavigationItem {
  const NavigationItem({
    required this.title,
    required this.route,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final String route;
  final IconData icon;
  final String? subtitle;
}

/// Navigation section to group related navigation items.
class NavigationSection {
  const NavigationSection({
    required this.title,
    required this.items,
    this.icon,
  });

  final String title;
  final List<NavigationItem> items;
  final IconData? icon;
}
