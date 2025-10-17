import '../note_entity.dart';
import '../note_repository.dart';

class CreateNoteUseCase {
  const CreateNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<NoteEntity> call(NoteEntity note) {
    return _repository.createNote(note);
  }
}
