import '../note_entity.dart';
import '../note_repository.dart';

class ListNotesUseCase {
  const ListNotesUseCase(this._repository);

  final NoteRepository _repository;

  Future<List<NoteEntity>> call() {
    return _repository.listNotes();
  }
}
