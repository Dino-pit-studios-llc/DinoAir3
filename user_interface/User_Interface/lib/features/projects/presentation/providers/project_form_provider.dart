import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/project_entity.dart';
import '../../domain/usecases/create_project_use_case.dart';
import '../../domain/usecases/update_project_use_case.dart';
import 'projects_list_provider.dart';

// Provider for create project use case
final createProjectUseCaseProvider = Provider<CreateProjectUseCase>((ref) {
  return CreateProjectUseCase(ref.watch(projectRepositoryProvider));
});

// Provider for update project use case (shared with detail provider)
final updateProjectFromFormUseCaseProvider =
    Provider<UpdateProjectUseCase>((ref) {
  return UpdateProjectUseCase(ref.watch(projectRepositoryProvider));
});

// Form state for creating/editing projects
class ProjectFormState {
  const ProjectFormState({
    this.editingProject,
    this.name = '',
    this.description = '',
    this.status = 'active',
    this.color,
    this.icon,
    this.parentProjectId,
    this.tags = const [],
    this.metadata,
    this.isSaving = false,
    this.error,
  });

  final ProjectEntity? editingProject;
  final String name;
  final String description;
  final String status; // 'active', 'completed', 'archived'
  final String? color;
  final String? icon;
  final String? parentProjectId;
  final List<String> tags;
  final Map<String, dynamic>? metadata;
  final bool isSaving;
  final String? error;

  bool get isEditing => editingProject != null;

  bool get isValid => name.trim().isNotEmpty;

  ProjectFormState copyWith({
    ProjectEntity? editingProject,
    String? name,
    String? description,
    String? status,
    String? color,
    String? icon,
    String? parentProjectId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool? isSaving,
    String? error,
  }) {
    return ProjectFormState(
      editingProject: editingProject ?? this.editingProject,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      parentProjectId: parentProjectId ?? this.parentProjectId,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

// State notifier for project form
class ProjectFormNotifier extends Notifier<ProjectFormState> {
  @override
  ProjectFormState build() {
    return const ProjectFormState();
  }

  /// Initialize form for creating a new project
  void initializeForCreate({String? parentProjectId}) {
    state = ProjectFormState(parentProjectId: parentProjectId);
  }

  /// Initialize form for editing an existing project
  void initializeForEdit(ProjectEntity project) {
    state = ProjectFormState(
      editingProject: project,
      name: project.name,
      description: project.description,
      status: project.status,
      color: project.color,
      icon: project.icon,
      parentProjectId: project.parentProjectId,
      tags: List.from(project.tags),
      metadata: project.metadata != null
          ? Map<String, dynamic>.from(project.metadata!)
          : null,
    );
  }

  /// Update name
  void updateName(String name) {
    state = state.copyWith(name: name, error: null);
  }

  /// Update description
  void updateDescription(String description) {
    state = state.copyWith(description: description, error: null);
  }

  /// Update status
  void updateStatus(String status) {
    state = state.copyWith(status: status, error: null);
  }

  /// Update color
  void updateColor(String? color) {
    state = state.copyWith(color: color, error: null);
  }

  /// Update icon
  void updateIcon(String? icon) {
    state = state.copyWith(icon: icon, error: null);
  }

  /// Update parent project ID
  void updateParentProjectId(String? parentProjectId) {
    state = state.copyWith(parentProjectId: parentProjectId, error: null);
  }

  /// Update tags
  void updateTags(List<String> tags) {
    state = state.copyWith(tags: tags, error: null);
  }

  /// Add a tag
  void addTag(String tag) {
    if (tag.trim().isEmpty) return;
    final trimmedTag = tag.trim();
    if (state.tags.contains(trimmedTag)) return;
    state = state.copyWith(tags: [...state.tags, trimmedTag], error: null);
  }

  /// Remove a tag
  void removeTag(String tag) {
    state = state.copyWith(
      tags: state.tags.where((t) => t != tag).toList(),
      error: null,
    );
  }

  /// Save the project (create or update)
  Future<bool> save() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Project name is required');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      if (state.isEditing) {
        // Update existing project
        final updatedProject = state.editingProject!.copyWith(
          name: state.name.trim(),
          description: state.description.trim(),
          status: state.status,
          color: state.color,
          icon: state.icon,
          parentProjectId: state.parentProjectId,
          tags: state.tags,
          metadata: state.metadata,
        );

        final useCase = ref.read(updateProjectFromFormUseCaseProvider);
        await useCase(updatedProject);
      } else {
        // Create new project
        final newProject = ProjectEntity(
          id: '', // Will be assigned by backend
          name: state.name.trim(),
          description: state.description.trim(),
          status: state.status,
          color: state.color,
          icon: state.icon,
          parentProjectId: state.parentProjectId,
          tags: state.tags,
          metadata: state.metadata,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final useCase = ref.read(createProjectUseCaseProvider);
        await useCase(newProject);
      }

      // Refresh projects list
      await ref.read(projectsListProvider.notifier).refresh();

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save project: ${e.toString()}',
      );
      return false;
    }
  }

  /// Reset form
  void reset() {
    state = const ProjectFormState();
  }
}

// Provider for project form
final projectFormProvider =
    NotifierProvider<ProjectFormNotifier, ProjectFormState>(
  () => ProjectFormNotifier(),
);
