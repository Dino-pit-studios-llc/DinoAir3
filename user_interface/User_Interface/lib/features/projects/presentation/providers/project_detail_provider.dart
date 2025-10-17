import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/project_entity.dart';
import '../../domain/usecases/delete_project_use_case.dart';
import '../../domain/usecases/update_project_use_case.dart';
import 'projects_list_provider.dart';

// Provider for delete project use case
final deleteProjectUseCaseProvider = Provider<DeleteProjectUseCase>((ref) {
  return DeleteProjectUseCase(ref.watch(projectRepositoryProvider));
});

// Provider for update project use case
final updateProjectUseCaseProvider = Provider<UpdateProjectUseCase>((ref) {
  return UpdateProjectUseCase(ref.watch(projectRepositoryProvider));
});

// Family provider for fetching a single project by ID
final projectDetailProvider =
    FutureProvider.family<ProjectEntity, String>((ref, projectId) async {
  final projects = await ref.watch(projectsListProvider.future);
  try {
    return projects.firstWhere((project) => project.id == projectId);
  } catch (e) {
    // If not in list, could fetch from repository directly
    throw Exception('Project not found');
  }
});

// State notifier for project operations (update, delete)
class ProjectOperationsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Update a project
  Future<void> updateProject(ProjectEntity project) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(updateProjectUseCaseProvider);
      await useCase(project);
      // Refresh the projects list
      await ref.read(projectsListProvider.notifier).refresh();
    });
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(deleteProjectUseCaseProvider);
      await useCase(projectId);
      // Refresh the projects list
      await ref.read(projectsListProvider.notifier).refresh();
    });
  }

  /// Update project status
  Future<void> updateStatus(String projectId, String newStatus) async {
    final projects = await ref.read(projectsListProvider.future);
    final project = projects.firstWhere((p) => p.id == projectId);
    final updated = project.copyWith(status: newStatus);
    await updateProject(updated);
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

// Provider for project operations
final projectOperationsProvider =
    NotifierProvider<ProjectOperationsNotifier, AsyncValue<void>>(
  () => ProjectOperationsNotifier(),
);
