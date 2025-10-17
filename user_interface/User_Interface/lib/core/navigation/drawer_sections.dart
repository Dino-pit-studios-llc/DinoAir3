import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import 'navigation_item.dart';

/// Defines the sections and items shown in the application drawer.
final List<NavigationSection> drawerSections = [
  const NavigationSection(
    title: 'Home',
    items: [
      NavigationItem(
        title: 'Overview',
        route: AppRoutes.home,
        icon: Icons.dashboard_outlined,
      ),
    ],
  ),
  const NavigationSection(
    title: 'Productivity',
    items: [
      NavigationItem(
        title: 'Notes',
        route: AppRoutes.notes,
        icon: Icons.note_outlined,
      ),
      NavigationItem(
        title: 'Projects',
        route: AppRoutes.projects,
        icon: Icons.work_outline,
      ),
      NavigationItem(
        title: 'Calendar',
        route: AppRoutes.calendar,
        icon: Icons.calendar_today_outlined,
      ),
      NavigationItem(
        title: 'File Search',
        route: AppRoutes.fileSearch,
        icon: Icons.folder_open,
      ),
    ],
  ),
  const NavigationSection(
    title: 'AI Tools',
    items: [
      NavigationItem(
        title: 'Chat Assistant',
        route: AppRoutes.aiChat,
        icon: Icons.chat_bubble_outline,
      ),
      NavigationItem(
        title: 'Pseudocode Translator',
        route: AppRoutes.translator,
        icon: Icons.code,
      ),
    ],
  ),
  const NavigationSection(
    title: 'Crypto',
    items: [
      NavigationItem(
        title: 'Dashboard',
        route: AppRoutes.cryptoDashboard,
        icon: Icons.assessment_outlined,
      ),
      NavigationItem(
        title: 'Market',
        route: AppRoutes.cryptoMarket,
        icon: Icons.trending_up,
      ),
      NavigationItem(
        title: 'Watchlist',
        route: AppRoutes.cryptoWatchlist,
        icon: Icons.star_border,
      ),
      NavigationItem(
        title: 'Portfolio',
        route: AppRoutes.cryptoPortfolio,
        icon: Icons.account_balance_wallet_outlined,
      ),
    ],
  ),
  const NavigationSection(
    title: 'System',
    items: [
      NavigationItem(
        title: 'Health Monitor',
        route: AppRoutes.health,
        icon: Icons.health_and_safety_outlined,
      ),
      NavigationItem(
        title: 'Settings',
        route: AppRoutes.settings,
        icon: Icons.settings_outlined,
      ),
    ],
  ),
];
