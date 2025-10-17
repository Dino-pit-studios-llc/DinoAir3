import 'package:meta/meta.dart';

@immutable
class NoteEntity {
  const NoteEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final String? projectId;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteEntity copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    String? projectId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
