import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/api/api_providers.dart';
import '../../data/note_remote_data_source.dart';
import '../../data/note_repository_impl.dart';
import '../../domain/note_entity.dart';
import '../../domain/note_repository.dart';
import '../../domain/usecases/list_notes_use_case.dart';
import '../../domain/usecases/search_notes_use_case.dart';

// Provider for the notes repository
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final dio = ref.watch(backendDioProvider);
  final dataSource = NoteRemoteDataSource(dio);
  return NoteRepositoryImpl(dataSource);
});

// Provider for list notes use case
final listNotesUseCaseProvider = Provider<ListNotesUseCase>((ref) {
  return ListNotesUseCase(ref.watch(noteRepositoryProvider));
});

// Provider for search notes use case
final searchNotesUseCaseProvider = Provider<SearchNotesUseCase>((ref) {
  return SearchNotesUseCase(ref.watch(noteRepositoryProvider));
});

// State notifier for notes list with search capability
class NotesListNotifier extends AsyncNotifier<List<NoteEntity>> {
  String _searchQuery = '';
  List<String> _filterTags = [];

  @override
  Future<List<NoteEntity>> build() async {
    return _fetchNotes();
  }

  Future<List<NoteEntity>> _fetchNotes() async {
    if (_searchQuery.isNotEmpty || _filterTags.isNotEmpty) {
      final useCase = ref.read(searchNotesUseCaseProvider);
      return useCase(query: _searchQuery, tags: _filterTags);
    } else {
      final useCase = ref.read(listNotesUseCaseProvider);
      return useCase();
    }
  }

  /// Refresh the notes list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchNotes());
  }

  /// Search notes with optional query and tags
  Future<void> search({String? query, List<String>? tags}) async {
    _searchQuery = query?.trim() ?? '';
    _filterTags = tags ?? [];
    await refresh();
  }

  /// Clear search filters and reload all notes
  Future<void> clearSearch() async {
    _searchQuery = '';
    _filterTags = [];
    await refresh();
  }
}

// Provider for the notes list
final notesListProvider =
    AsyncNotifierProvider<NotesListNotifier, List<NoteEntity>>(
  () => NotesListNotifier(),
);

// Computed provider for filtered notes count
final notesCountProvider = Provider<int>((ref) {
  final notesAsync = ref.watch(notesListProvider);
  return notesAsync.maybeWhen(
    data: (notes) => notes.length,
    orElse: () => 0,
  );
});
