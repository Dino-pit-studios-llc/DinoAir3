class ProjectDto {
  const ProjectDto({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.color,
    this.icon,
    this.parentProjectId,
    required this.tags,
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.archivedAt,
  });

  final String id;
  final String name;
  final String description;
  final String status;
  final String? color;
  final String? icon;
  final String? parentProjectId;
  final List<String> tags;
  final Map<String, dynamic>? metadata;
  final String? createdAt;
  final String? updatedAt;
  final String? completedAt;
  final String? archivedAt;

  factory ProjectDto.fromJson(Map<String, dynamic> json) {
    return ProjectDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      parentProjectId: json['parent_project_id'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      completedAt: json['completed_at'] as String?,
      archivedAt: json['archived_at'] as String?,
    );
  }

  Map<String, dynamic> toJson({bool includeMetadata = false}) {
    final json = <String, dynamic>{
      'name': name,
      'description': description,
      'status': status,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (parentProjectId != null) 'parent_project_id': parentProjectId,
      'tags': tags,
      if (metadata != null) 'metadata': metadata,
    };

    if (includeMetadata) {
      json['id'] = id;
      if (createdAt != null) json['created_at'] = createdAt;
      if (updatedAt != null) json['updated_at'] = updatedAt;
      if (completedAt != null) json['completed_at'] = completedAt;
      if (archivedAt != null) json['archived_at'] = archivedAt;
    }

    return json;
  }
}
