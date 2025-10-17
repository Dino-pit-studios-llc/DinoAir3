import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/api/api_providers.dart';
import '../../data/project_remote_data_source.dart';
import '../../data/project_repository_impl.dart';
import '../../domain/project_entity.dart';
import '../../domain/project_repository.dart';
import '../../domain/usecases/get_child_projects_use_case.dart';
import '../../domain/usecases/list_projects_use_case.dart';

// Provider for the projects repository
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final dio = ref.watch(backendDioProvider);
  final dataSource = ProjectRemoteDataSource(dio);
  return ProjectRepositoryImpl(dataSource);
});

// Provider for list projects use case
final listProjectsUseCaseProvider = Provider<ListProjectsUseCase>((ref) {
  return ListProjectsUseCase(ref.watch(projectRepositoryProvider));
});

// Provider for get child projects use case
final getChildProjectsUseCaseProvider =
    Provider<GetChildProjectsUseCase>((ref) {
  return GetChildProjectsUseCase(ref.watch(projectRepositoryProvider));
});

// State notifier for projects list with filtering
class ProjectsListNotifier extends AsyncNotifier<List<ProjectEntity>> {
  String? _statusFilter;
  String? _parentIdFilter;

  @override
  Future<List<ProjectEntity>> build() async {
    return _fetchProjects();
  }

  Future<List<ProjectEntity>> _fetchProjects() async {
    final useCase = ref.read(listProjectsUseCaseProvider);
    return useCase(statusFilter: _statusFilter, parentId: _parentIdFilter);
  }

  /// Refresh the projects list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProjects());
  }

  /// Filter projects by status
  Future<void> filterByStatus(String? status) async {
    _statusFilter = status;
    await refresh();
  }

  /// Filter projects by parent ID
  Future<void> filterByParent(String? parentId) async {
    _parentIdFilter = parentId;
    await refresh();
  }

  /// Clear all filters and reload
  Future<void> clearFilters() async {
    _statusFilter = null;
    _parentIdFilter = null;
    await refresh();
  }

  /// Get root projects (no parent)
  Future<void> showRootProjects() async {
    _parentIdFilter = '';
    await refresh();
  }
}

// Provider for the projects list
final projectsListProvider =
    AsyncNotifierProvider<ProjectsListNotifier, List<ProjectEntity>>(
  () => ProjectsListNotifier(),
);

// Computed provider for projects count
final projectsCountProvider = Provider<int>((ref) {
  final projectsAsync = ref.watch(projectsListProvider);
  return projectsAsync.maybeWhen(
    data: (projects) => projects.length,
    orElse: () => 0,
  );
});

// Provider for child projects of a specific parent
final childProjectsProvider =
    FutureProvider.family<List<ProjectEntity>, String>((ref, parentId) async {
  final useCase = ref.watch(getChildProjectsUseCaseProvider);
  return useCase(parentId);
});
