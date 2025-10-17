import 'dart:async';

import 'chat_message_entity.dart';
import 'chat_session_entity.dart';

abstract class AiChatRepository {
  Future<ChatMessageEntity> sendMessage(String message, {String? sessionId});

  Future<List<ChatMessageEntity>> getChatHistory(String sessionId);

  Future<void> clearSession(String sessionId);

  Future<List<ChatSessionEntity>> getChatSessions();

  Future<String> createSession({String? title});

  Stream<ChatMessageEntity>? getMessageStream(String sessionId);
}
