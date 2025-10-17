import 'package:meta/meta.dart';

@immutable
class ProjectEntity {
  const ProjectEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.color,
    this.icon,
    this.parentProjectId,
    required this.tags,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.archivedAt,
  });

  final String id;
  final String name;
  final String description;
  final String status; // 'active', 'completed', 'archived'
  final String? color;
  final String? icon;
  final String? parentProjectId;
  final List<String> tags;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? archivedAt;

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isArchived => status == 'archived';
  bool get hasParent => parentProjectId != null && parentProjectId!.isNotEmpty;

  ProjectEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? status,
    String? color,
    String? icon,
    String? parentProjectId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? archivedAt,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      parentProjectId: parentProjectId ?? this.parentProjectId,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
