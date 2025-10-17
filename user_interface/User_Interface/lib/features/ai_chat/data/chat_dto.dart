import 'package:meta/meta.dart';

@immutable
class ChatRequestDto {
  const ChatRequestDto({
    required this.message,
    this.sessionId,
    this.toolCalls,
  });

  final String message;
  final String? sessionId;
  final List<dynamic>? toolCalls;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'message': message,
    };

    if (sessionId != null) {
      map['session_id'] = sessionId;
    }

    if (toolCalls != null && toolCalls!.isNotEmpty) {
      map['tool_calls'] = toolCalls;
    }

    return map;
  }

  factory ChatRequestDto.fromJson(Map<String, dynamic> json) {
    return ChatRequestDto(
      message: json['message']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? json['sessionId']?.toString(),
      toolCalls: json['tool_calls'] ?? json['toolCalls'],
    );
  }
}

@immutable
class ChatResponseDto {
  const ChatResponseDto({
    required this.message,
    required this.sessionId,
    this.toolCalls,
  });

  final String message;
  final String sessionId;
  final List<dynamic>? toolCalls;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'message': message,
      'session_id': sessionId,
    };

    if (toolCalls != null && toolCalls!.isNotEmpty) {
      map['tool_calls'] = toolCalls;
    }

    return map;
  }

  factory ChatResponseDto.fromJson(Map<String, dynamic> json) {
    return ChatResponseDto(
      message: json['message']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? json['sessionId']?.toString() ?? '',
      toolCalls: json['tool_calls'] ?? json['toolCalls'],
    );
  }
}

@immutable
class ChatSessionDto {
  const ChatSessionDto({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'message_count': messageCount,
    };
  }

  factory ChatSessionDto.fromJson(Map<String, dynamic> json) {
    return ChatSessionDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      createdAt: _tryParseDate(json['created_at'] ?? json['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: _tryParseDate(json['updated_at'] ?? json['updatedAt']) ?? DateTime.now().toUtc(),
      messageCount: json['message_count'] ?? json['messageCount'] ?? 0,
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
}
