import '../note_repository.dart';

class DeleteNoteUseCase {
  const DeleteNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteNote(id);
  }
}
