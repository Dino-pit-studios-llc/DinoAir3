import '../note_entity.dart';
import '../note_repository.dart';

class SearchNotesUseCase {
  const SearchNotesUseCase(this._repository);

  final NoteRepository _repository;

  Future<List<NoteEntity>> call({String? query, List<String>? tags}) {
    return _repository.searchNotes(query: query, tags: tags);
  }
}
