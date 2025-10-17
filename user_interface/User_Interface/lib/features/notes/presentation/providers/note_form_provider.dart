import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/note_entity.dart';
import '../../domain/usecases/create_note_use_case.dart';
import '../../domain/usecases/update_note_use_case.dart';
import 'notes_list_provider.dart';

// Provider for create note use case
final createNoteUseCaseProvider = Provider<CreateNoteUseCase>((ref) {
  return CreateNoteUseCase(ref.watch(noteRepositoryProvider));
});

// Provider for update note use case (shared with detail provider)
final updateNoteFromFormUseCaseProvider = Provider<UpdateNoteUseCase>((ref) {
  return UpdateNoteUseCase(ref.watch(noteRepositoryProvider));
});

// Form state for creating/editing notes
class NoteFormState {
  const NoteFormState({
    this.editingNote,
    this.title = '',
    this.content = '',
    this.tags = const [],
    this.projectId,
    this.isSaving = false,
    this.error,
  });

  final NoteEntity? editingNote;
  final String title;
  final String content;
  final List<String> tags;
  final String? projectId;
  final bool isSaving;
  final String? error;

  bool get isEditing => editingNote != null;

  bool get isValid => title.trim().isNotEmpty && content.trim().isNotEmpty;

  NoteFormState copyWith({
    NoteEntity? editingNote,
    String? title,
    String? content,
    List<String>? tags,
    String? projectId,
    bool? isSaving,
    String? error,
  }) {
    return NoteFormState(
      editingNote: editingNote ?? this.editingNote,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      projectId: projectId ?? this.projectId,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

// State notifier for note form
class NoteFormNotifier extends Notifier<NoteFormState> {
  @override
  NoteFormState build() {
    return const NoteFormState();
  }

  /// Initialize form for creating a new note
  void initializeForCreate() {
    state = const NoteFormState();
  }

  /// Initialize form for editing an existing note
  void initializeForEdit(NoteEntity note) {
    state = NoteFormState(
      editingNote: note,
      title: note.title,
      content: note.content,
      tags: List.from(note.tags),
      projectId: note.projectId,
    );
  }

  /// Update title
  void updateTitle(String title) {
    state = state.copyWith(title: title, error: null);
  }

  /// Update content
  void updateContent(String content) {
    state = state.copyWith(content: content, error: null);
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

  /// Update project ID
  void updateProjectId(String? projectId) {
    state = state.copyWith(projectId: projectId, error: null);
  }

  /// Save the note (create or update)
  Future<bool> save() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Title and content are required');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      if (state.isEditing) {
        // Update existing note
        final updatedNote = state.editingNote!.copyWith(
          title: state.title.trim(),
          content: state.content.trim(),
          tags: state.tags,
          projectId: state.projectId,
        );

        final useCase = ref.read(updateNoteFromFormUseCaseProvider);
        await useCase(updatedNote);
      } else {
        // Create new note
        final newNote = NoteEntity(
          id: '', // Will be assigned by backend
          title: state.title.trim(),
          content: state.content.trim(),
          tags: state.tags,
          projectId: state.projectId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final useCase = ref.read(createNoteUseCaseProvider);
        await useCase(newNote);
      }

      // Refresh notes list
      await ref.read(notesListProvider.notifier).refresh();

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save note: ${e.toString()}',
      );
      return false;
    }
  }

  /// Reset form
  void reset() {
    state = const NoteFormState();
  }
}

// Provider for note form
final noteFormProvider = NotifierProvider<NoteFormNotifier, NoteFormState>(
  () => NoteFormNotifier(),
);
