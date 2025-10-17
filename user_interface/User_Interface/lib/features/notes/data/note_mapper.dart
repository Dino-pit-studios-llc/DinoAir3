import 'package:crypto_dash/features/notes/data/note_dto.dart';
import 'package:crypto_dash/features/notes/domain/note_entity.dart';

class NoteMapper {
  const NoteMapper._();

  static NoteEntity toEntity(NoteDto dto) {
    return NoteEntity(
      id: dto.id,
      title: dto.title,
      content: dto.content,
      tags: List<String>.from(dto.tags),
      projectId: dto.projectId,
      createdAt: dto.createdAt ?? DateTime.now().toUtc(),
      updatedAt: dto.updatedAt ?? DateTime.now().toUtc(),
    );
  }

  static NoteDto fromEntity(NoteEntity entity) {
    return NoteDto(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      tags: List<String>.from(entity.tags),
      projectId: entity.projectId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static List<NoteEntity> toEntities(List<NoteDto> dtos) {
    return dtos.map(toEntity).toList(growable: false);
  }

  static List<NoteDto> fromEntities(List<NoteEntity> entities) {
    return entities.map(fromEntity).toList(growable: false);
  }
}
