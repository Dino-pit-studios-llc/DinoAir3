import 'dart:async';

import 'note_entity.dart';

abstract class NoteRepository {
  Future<List<NoteEntity>> listNotes();
  Future<List<NoteEntity>> searchNotes({String? query, List<String>? tags});
  Future<NoteEntity> getNote(String id);
  Future<NoteEntity> createNote(NoteEntity note);
  Future<NoteEntity> updateNote(NoteEntity note);
  Future<void> deleteNote(String id);

  Future<NoteEntity> getNoteById(String noteId);
}
