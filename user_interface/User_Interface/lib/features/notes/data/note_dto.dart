import 'package:meta/meta.dart';

@immutable
class NoteDto {
  const NoteDto({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
    this.contentHtml,
  });

  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final String? projectId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? contentHtml;

  factory NoteDto.fromJson(Map<String, dynamic> json) {
    return NoteDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      tags: _normalizeTags(json['tags']),
      projectId: _readProjectId(json),
      createdAt: _tryParseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _tryParseDate(json['updated_at'] ?? json['updatedAt']),
      contentHtml:
          json['content_html']?.toString() ?? json['contentHtml']?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool includeMetadata = false}) {
    final map = <String, dynamic>{
      'title': title,
      'content': content,
      'tags': tags,
      'project_id': projectId,
    };

    if (includeMetadata) {
      map['id'] = id;
      if (createdAt != null) {
        map['created_at'] = createdAt!.toIso8601String();
      }
      if (updatedAt != null) {
        map['updated_at'] = updatedAt!.toIso8601String();
      }
      if (contentHtml != null) {
        map['content_html'] = contentHtml;
      }
    }

    return map;
  }

  NoteDto copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    String? projectId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contentHtml,
  }) {
    return NoteDto(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contentHtml: contentHtml ?? this.contentHtml,
    );
  }

  static DateTime? _tryParseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final raw = value.toString();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      return null;
    }
  }

  static List<String> _normalizeTags(Object? raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((value) => value == null ? '' : value.toString())
          .where((value) => value.isNotEmpty)
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  static String? _readProjectId(Map<String, dynamic> json) {
    final dynamic snake = json['project_id'];
    final dynamic camel = json['projectId'];
    final dynamic value = snake ?? camel;
    if (value == null) {
      return null;
    }
    final asString = value.toString().trim();
    return asString.isEmpty ? null : asString;
  }
}
