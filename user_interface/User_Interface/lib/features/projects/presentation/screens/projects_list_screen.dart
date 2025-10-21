import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../providers/projects_list_provider.dart';
import '../widgets/project_card_widget.dart';

class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> {
  String? _statusFilter;

  void _showFilterMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.filter_list_off),
              title: const Text('All Projects'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _statusFilter = null);
                ref.read(projectsListProvider.notifier).clearFilters();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.play_circle_outline, color: Colors.green),
              title: const Text('Active'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _statusFilter = 'active');
                ref
                    .read(projectsListProvider.notifier)
                    .filterByStatus('active');
              },
            ),
            ListTile(
              leading: const Icon(Icons.done_all, color: Colors.blue),
              title: const Text('Completed'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _statusFilter = 'completed');
                ref
                    .read(projectsListProvider.notifier)
                    .filterByStatus('completed');
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.grey),
              title: const Text('Archived'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _statusFilter = 'archived');
                ref
                    .read(projectsListProvider.notifier)
                    .filterByStatus('archived');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _statusFilter != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterMenu,
            tooltip: 'Filter projects',
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusFilter != null
                        ? 'No ${_statusFilter} projects found'
                        : 'No projects yet.\nTap + to create your first project.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(projectsListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return ProjectCardWidget(
                  project: project,
                  onTap: () {
                    context.push(
                      AppRoutes.projectDetailPath(project.id),
                      extra: project,
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load projects',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(projectsListProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.projectCreate);
        },
        tooltip: 'Create new project',
        child: const Icon(Icons.add),
      ),
    );
  }
}
