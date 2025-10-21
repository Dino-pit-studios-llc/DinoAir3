import '../domain/project_entity.dart';
import 'project_dto.dart';

class ProjectMapper {
  static ProjectEntity toEntity(ProjectDto dto) {
    return ProjectEntity(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      status: dto.status,
      color: dto.color,
      icon: dto.icon,
      parentProjectId: dto.parentProjectId,
      tags: List<String>.from(dto.tags),
      metadata: dto.metadata != null
          ? Map<String, dynamic>.from(dto.metadata!)
          : null,
      createdAt: _parseDateTime(dto.createdAt) ?? DateTime.now(),
      updatedAt: _parseDateTime(dto.updatedAt) ?? DateTime.now(),
      completedAt: _parseDateTime(dto.completedAt),
      archivedAt: _parseDateTime(dto.archivedAt),
    );
  }

  static ProjectDto fromEntity(ProjectEntity entity) {
    return ProjectDto(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      status: entity.status,
      color: entity.color,
      icon: entity.icon,
      parentProjectId: entity.parentProjectId,
      tags: List<String>.from(entity.tags),
      metadata: entity.metadata != null
          ? Map<String, dynamic>.from(entity.metadata!)
          : null,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      completedAt: entity.completedAt?.toIso8601String(),
      archivedAt: entity.archivedAt?.toIso8601String(),
    );
  }

  static List<ProjectEntity> toEntities(List<ProjectDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  static DateTime? _parseDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      return null;
    }
  }
}
