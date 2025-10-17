import 'package:crypto_dash/core/errors/error_handler.dart';
import 'package:crypto_dash/features/notes/data/note_mapper.dart';
import 'package:crypto_dash/features/notes/data/note_remote_data_source.dart';
import 'package:crypto_dash/features/notes/domain/note_entity.dart';
import 'package:crypto_dash/features/notes/domain/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(this._remoteDataSource);

  final NoteRemoteDataSource _remoteDataSource;

  @override
  Future<NoteEntity> createNote(NoteEntity note) {
    return guardFuture(() async {
      final dto = NoteMapper.fromEntity(note);
      final created = await _remoteDataSource.createNote(dto);
      return NoteMapper.toEntity(created);
    });
  }

  @override
  Future<void> deleteNote(String id) {
    return guardFuture(() => _remoteDataSource.deleteNote(id));
  }

  @override
  Future<NoteEntity> getNote(String id) {
    return guardFuture(() async {
      final dto = await _remoteDataSource.fetchNote(id);
      return NoteMapper.toEntity(dto);
    });
  }

  @override
  Future<NoteEntity> getNoteById(String id) {
    return guardFuture(() async {
      final dto = await _remoteDataSource.fetchNote(id);
      return NoteMapper.toEntity(dto);
    });
  }

  @override
  Future<List<NoteEntity>> listNotes() {
    return guardFuture(() async {
      final dtos = await _remoteDataSource.fetchNotes();
      return NoteMapper.toEntities(dtos);
    });
  }

  @override
  Future<List<NoteEntity>> searchNotes({String? query, List<String>? tags}) {
    return guardFuture(() async {
      final dtos = await _remoteDataSource.searchNotes(
        query: query,
        tags: tags,
      );
      return NoteMapper.toEntities(dtos);
    });
  }

  @override
  Future<NoteEntity> updateNote(NoteEntity note) {
    return guardFuture(() async {
      final dto = NoteMapper.fromEntity(note);
      final updated = await _remoteDataSource.updateNote(dto);
      return NoteMapper.toEntity(updated);
    });
  }
}
