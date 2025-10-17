import '../note_entity.dart';
import '../note_repository.dart';

class UpdateNoteUseCase {
  const UpdateNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<NoteEntity> call(NoteEntity note) {
    return _repository.updateNote(note);
  }
}
