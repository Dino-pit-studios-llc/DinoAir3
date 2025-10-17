import 'package:crypto_dash/features/ai_chat/data/chat_dto.dart';
import 'package:crypto_dash/features/ai_chat/domain/chat_message_entity.dart';
import 'package:crypto_dash/features/ai_chat/domain/chat_session_entity.dart';

class ChatMessageMapper {
  const ChatMessageMapper._();

  static ChatMessageEntity toEntity(ChatResponseDto dto) {
    return ChatMessageEntity(
      id: _generateMessageId(dto.sessionId, dto.message.hashCode),
      sessionId: dto.sessionId,
      role: MessageRole.assistant,
      content: dto.message,
      timestamp: DateTime.now().toUtc(),
      toolCalls: dto.toolCalls,
    );
  }

  static ChatResponseDto fromEntity(ChatMessageEntity entity) {
    return ChatResponseDto(
      message: entity.content,
      sessionId: _extractSessionIdFromMessageId(entity.id),
      toolCalls: entity.toolCalls,
    );
  }

  static ChatMessageEntity fromUserMessage(String message, {String? sessionId}) {
    return ChatMessageEntity(
      id: _generateMessageId(sessionId ?? 'default', message.hashCode),
      sessionId: sessionId ?? 'default',
      role: MessageRole.user,
      content: message,
      timestamp: DateTime.now().toUtc(),
      toolCalls: null,
    );
  }

  static List<ChatMessageEntity> toEntities(List<ChatResponseDto> dtos) {
    return dtos.map(toEntity).toList(growable: false);
  }

  static List<ChatResponseDto> fromEntities(List<ChatMessageEntity> entities) {
    return entities.map(fromEntity).toList(growable: false);
  }

  static String _generateMessageId(String? sessionId, int hashCode) {
    return '${sessionId ?? 'default'}_msg_${hashCode}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _extractSessionIdFromMessageId(String messageId) {
    final parts = messageId.split('_msg_');
    return parts.isNotEmpty ? parts[0] : 'default';
  }
}

class ChatSessionMapper {
  const ChatSessionMapper._();

  static ChatSessionEntity toEntity(ChatSessionDto dto) {
    return ChatSessionEntity(
      id: dto.id,
      title: dto.title,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      messageCount: dto.messageCount,
    );
  }

  static ChatSessionDto fromEntity(ChatSessionEntity entity) {
    return ChatSessionDto(
      id: entity.id,
      title: entity.title,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      messageCount: entity.messageCount,
    );
  }

  static List<ChatSessionEntity> toEntities(List<ChatSessionDto> dtos) {
    return dtos.map(toEntity).toList(growable: false);
  }

  static List<ChatSessionDto> fromEntities(List<ChatSessionEntity> entities) {
    return entities.map(fromEntity).toList(growable: false);
  }
}
