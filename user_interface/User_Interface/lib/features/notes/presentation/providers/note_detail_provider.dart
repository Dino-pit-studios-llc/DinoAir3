import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/note_entity.dart';
import '../../domain/usecases/delete_note_use_case.dart';
import '../../domain/usecases/update_note_use_case.dart';
import 'notes_list_provider.dart';

// Provider for delete note use case
final deleteNoteUseCaseProvider = Provider<DeleteNoteUseCase>((ref) {
  return DeleteNoteUseCase(ref.watch(noteRepositoryProvider));
});

// Provider for update note use case
final updateNoteUseCaseProvider = Provider<UpdateNoteUseCase>((ref) {
  return UpdateNoteUseCase(ref.watch(noteRepositoryProvider));
});

// Family provider for fetching a single note by ID
final noteDetailProvider =
    FutureProvider.family<NoteEntity, String>((ref, noteId) async {
  final notes = await ref.watch(notesListProvider.future);
  try {
    return notes.firstWhere((note) => note.id == noteId);
  } catch (e) {
    // If not in list, fetch from repository directly
    final repository = ref.watch(noteRepositoryProvider);
    return await repository.getNoteById(noteId);
  }
});

// State notifier for note operations (update, delete)
class NoteOperationsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Update a note
  Future<void> updateNote(NoteEntity note) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(updateNoteUseCaseProvider);
      await useCase(note);
      // Refresh the notes list
      await ref.read(notesListProvider.notifier).refresh();
    });
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(deleteNoteUseCaseProvider);
      await useCase(noteId);
      // Refresh the notes list
      await ref.read(notesListProvider.notifier).refresh();
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

// Provider for note operations
final noteOperationsProvider =
    NotifierProvider<NoteOperationsNotifier, AsyncValue<void>>(
  () => NoteOperationsNotifier(),
);
