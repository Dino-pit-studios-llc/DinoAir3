import 'dart:async';

import 'package:crypto_dash/core/errors/error_handler.dart';
import 'package:crypto_dash/features/ai_chat/data/chat_dto.dart';
import 'package:crypto_dash/features/ai_chat/data/chat_local_data_source.dart';
import 'package:crypto_dash/features/ai_chat/data/chat_mapper.dart';
import 'package:crypto_dash/features/ai_chat/data/chat_remote_data_source.dart';
import 'package:crypto_dash/features/ai_chat/domain/ai_chat_repository.dart';
import 'package:crypto_dash/features/ai_chat/domain/chat_message_entity.dart';
import 'package:crypto_dash/features/ai_chat/domain/chat_session_entity.dart';

class ChatRepositoryImpl implements AiChatRepository {
  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    required ChatLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final ChatRemoteDataSource _remoteDataSource;
  final ChatLocalDataSource _localDataSource;

  @override
  Future<ChatMessageEntity> sendMessage(String message, {String? sessionId}) async {
    return guardFuture(() async {
      // Create request DTO
      final requestDto = ChatRequestDto(
        message: message,
        sessionId: sessionId,
      );

      // Send message to remote
      final responseDto = await _remoteDataSource.sendMessage(requestDto);

      // Convert to entity
      final messageEntity = ChatMessageMapper.toEntity(responseDto);

      // Cache the response locally
      await _localDataSource.saveMessage(messageEntity);

      // Update session message count if we have a session
      if (sessionId != null) {
        await _updateSessionMessageCount(sessionId);
      }

      return messageEntity;
    });
  }

  @override
  Future<List<ChatMessageEntity>> getChatHistory(String sessionId) async {
    return guardFuture(() async {
      try {
        // Try remote first
        final responseDtos = await _remoteDataSource.getChatHistory(sessionId);
        final messages = ChatMessageMapper.toEntities(responseDtos);

        // Cache the retrieved messages
        for (final message in messages) {
          await _localDataSource.saveMessage(message);
        }

        return messages;
      } catch (error) {
        // If remote fails, try local cache as fallback
        return _localDataSource.getCachedHistory(sessionId);
      }
    });
  }

  @override
  Future<void> clearSession(String sessionId) async {
    return guardFuture(() async {
      try {
        // Clear remote session
        await _remoteDataSource.clearSession(sessionId);
      } catch (error) {
        // Continue even if remote fails
      }

      // Always clear local cache
      await _localDataSource.clearCachedSession(sessionId);
    });
  }

  @override
  Future<List<ChatSessionEntity>> getChatSessions() async {
    return guardFuture(() async {
      try {
        // Try remote first
        final sessionDtos = await _remoteDataSource.getChatSessions();
        final sessions = ChatSessionMapper.toEntities(sessionDtos);

        // Cache the retrieved sessions
        for (final session in sessions) {
          await _localDataSource.saveSession(session);
        }

        return sessions;
      } catch (error) {
        // If remote fails, return local cache as fallback
        return _localDataSource.getCachedSessions();
      }
    });
  }

  @override
  Future<String> createSession({String? title}) async {
    return guardFuture(() async {
      // Create session on remote
      final sessionId = await _remoteDataSource.createSession(title: title);

      // Create local session entity for caching
      final sessionEntity = ChatSessionEntity(
        id: sessionId,
        title: title ?? 'New Chat Session',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        messageCount: 0,
      );

      // Cache the session locally
      await _localDataSource.saveSession(sessionEntity);

      return sessionId;
    });
  }

  @override
  Stream<ChatMessageEntity>? getMessageStream(String sessionId) {
    // For now, return null as streaming is not implemented
    // This can be enhanced in the future when backend supports SSE
    final remoteStream = _remoteDataSource.getMessageStream(sessionId);
    if (remoteStream == null) return null;

    return remoteStream.map((dto) => ChatMessageMapper.toEntity(dto));
  }

  Future<void> _updateSessionMessageCount(String sessionId) async {
    try {
      final cachedMessages = await _localDataSource.getCachedHistory(sessionId);
      await _localDataSource.updateSessionMessageCount(sessionId, cachedMessages.length);
    } catch (error) {
      // Ignore errors when updating message count
    }
  }

  /// Initialize local storage (call this once during app startup)
  Future<void> initialize() async {
    await _localDataSource.init();
  }

  /// Clear all cached data (useful for logout)
  Future<void> clearAllCache() async {
    await _localDataSource.clearAllCache();
  }
}
