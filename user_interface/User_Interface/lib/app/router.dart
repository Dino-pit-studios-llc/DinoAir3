// Central router configuration for the app using go_router.
// Defines routes for main navigation and detail pages.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/ai_chat/presentation/screens/ai_chat_screen.dart';
import '../features/calendar/presentation/screens/calendar_detail_screen.dart';
import '../features/calendar/presentation/screens/calendar_form_screen.dart';
import '../features/calendar/presentation/screens/calendar_list_screen.dart';
import '../features/file_search/presentation/screens/directory_management_screen.dart';
import '../features/file_search/presentation/screens/file_search_screen.dart';
import '../features/market/domain/coin_entity.dart';
import '../features/market/presentation/screens/coin_detail_screen.dart';
import '../features/market/presentation/screens/market_screen.dart';
import '../features/notes/domain/note_entity.dart';
import '../features/notes/presentation/screens/note_create_screen.dart';
import '../features/notes/presentation/screens/note_detail_screen.dart';
import '../features/notes/presentation/screens/notes_list_screen.dart';
import '../features/portfolio/presentation/screens/portfolio_screen.dart';
import '../features/projects/domain/project_entity.dart';
import '../features/projects/presentation/screens/project_detail_screen.dart';
import '../features/projects/presentation/screens/project_form_screen.dart';
import '../features/projects/presentation/screens/projects_list_screen.dart';
import '../features/translator/presentation/screens/translator_screen.dart';
import '../features/watchlist/presentation/screens/watchlist_screen.dart';
import '../features/health/presentation/screens/health_screen.dart';
import '../features/crypto/presentation/screens/crypto_dashboard_screen.dart';
import 'app_routes.dart';
import 'shell_scaffold.dart';

/// Build the GoRouter instance
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderScreen(
                icon: Icons.dashboard_outlined,
                message: 'Welcome to DinoAir Control Center',
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.notes,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const NotesListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.projects,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProjectsListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const CalendarListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.fileSearch,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const FileSearchScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.aiChat,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AiChatScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.translator,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const TranslatorScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.cryptoDashboard,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const CryptoDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.cryptoMarket,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const MarketScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.cryptoWatchlist,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const WatchlistScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.cryptoPortfolio,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const PortfolioScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.health,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HealthScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsPlaceholder(),
            ),
          ),
        ],
      ),
      // Coin detail as a full-screen route (outside shell)
      GoRoute(
        path: AppRoutes.coinDetail,
        builder: (context, state) {
          final coinId = state.pathParameters['id']!;
          final extra = state.extra;
          final coin = extra is CoinEntity ? extra : null;
          return CoinDetailScreen(coinId: coinId, coin: coin);
        },
      ),
      // Note detail as a full-screen route (outside shell)
      GoRoute(
        path: AppRoutes.noteDetail,
        builder: (context, state) {
          final noteId = state.pathParameters['id']!;
          final extra = state.extra;
          final note = extra is NoteEntity ? extra : null;
          return NoteDetailScreen(noteId: noteId, note: note);
        },
      ),
      // Note create as a full-screen route
      GoRoute(
        path: AppRoutes.noteCreate,
        builder: (context, state) {
          return const NoteCreateScreen();
        },
      ),
      // Note edit as a full-screen route
      GoRoute(
        path: '/notes/edit/:id',
        builder: (context, state) {
          final extra = state.extra;
          final note = extra is NoteEntity ? extra : null;
          return NoteCreateScreen(existingNote: note);
        },
      ),
      // Project detail as a full-screen route (outside shell)
      GoRoute(
        path: AppRoutes.projectDetail,
        builder: (context, state) {
          final extra = state.extra;
          final project = extra is ProjectEntity ? extra : null;
          if (project == null) {
            // If no project passed, show error or redirect
            return const _PlaceholderScreen(
              icon: Icons.error_outline,
              message: 'Project not found',
            );
          }
          return ProjectDetailScreen(project: project);
        },
      ),
      // Project create as a full-screen route
      GoRoute(
        path: AppRoutes.projectCreate,
        builder: (context, state) {
          return const ProjectFormScreen();
        },
      ),
      // Project edit as a full-screen route
      GoRoute(
        path: '/projects/edit/:id',
        builder: (context, state) {
          final extra = state.extra;
          final project = extra is ProjectEntity ? extra : null;
          return ProjectFormScreen(project: project);
        },
      ),
      // Calendar detail as a full-screen route
      GoRoute(
        path: AppRoutes.calendarDetail,
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return CalendarDetailScreen(eventId: eventId);
        },
      ),
      // Calendar create as a full-screen route
      GoRoute(
        path: AppRoutes.calendarCreate,
        builder: (context, state) {
          return const CalendarFormScreen();
        },
      ),
      // Calendar edit as a full-screen route
      GoRoute(
        path: '/calendar/:id/edit',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return CalendarFormScreen(eventId: eventId);
        },
      ),
      // File search directory management as a full-screen route
      GoRoute(
        path: AppRoutes.fileSearchDirectories,
        builder: (context, state) {
          return const DirectoryManagementScreen();
        },
      ),
    ],
  );
}

class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      icon: Icons.settings_outlined,
      message: 'Settings panel coming soon.',
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
