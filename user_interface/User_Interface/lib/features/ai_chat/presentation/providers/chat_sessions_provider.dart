import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/chat_session_entity.dart';
import '../../domain/usecases/get_chat_sessions_use_case.dart';
import '../../domain/usecases/create_session_use_case.dart';
import 'chat_messages_provider.dart';

// Provider for get chat sessions use case
final getChatSessionsUseCaseProvider = Provider<GetChatSessionsUseCase>((ref) {
  return GetChatSessionsUseCase(ref.watch(aiChatRepositoryProvider));
});

// Provider for create session use case
final createSessionUseCaseProvider = Provider<CreateSessionUseCase>((ref) {
  return CreateSessionUseCase(ref.watch(aiChatRepositoryProvider));
});

// State notifier for chat sessions management
class ChatSessionsNotifier extends AsyncNotifier<List<ChatSessionEntity>> {
  ChatSessionEntity? _currentSession;

  @override
  Future<List<ChatSessionEntity>> build() async {
    return _fetchSessions();
  }

  Future<List<ChatSessionEntity>> _fetchSessions() async {
    final useCase = ref.read(getChatSessionsUseCaseProvider);
    return useCase();
  }

  /// Refresh the sessions list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSessions());
  }

  /// Create a new chat session
  Future<ChatSessionEntity?> createSession({String? title}) async {
    try {
      state = const AsyncValue.loading();
      final useCase = ref.read(createSessionUseCaseProvider);
      final sessionId = await useCase(title: title);

      // Create session entity for the new session
      final newSession = ChatSessionEntity(
        id: sessionId,
        title: title ?? 'New Chat Session',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messageCount: 0,
      );

      // Add to current sessions list
      state = await AsyncValue.guard(() async {
        final currentSessions = await _fetchSessions();
        return [...currentSessions, newSession];
      });

      return newSession;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      return null;
    }
  }

  /// Delete a chat session
  Future<void> deleteSession(String sessionId) async {
    try {
      state = const AsyncValue.loading();

      // Clear session from repository if needed
      // You might want to add a delete session use case here

      // Remove from current sessions list
      state = await AsyncValue.guard(() async {
        final currentSessions = await _fetchSessions();
        return currentSessions
            .where((session) => session.id != sessionId)
            .toList();
      });

      // If the deleted session was current, clear current session
      if (_currentSession?.id == sessionId) {
        _currentSession = null;
        // Clear messages for the deleted session
        ref.read(chatMessagesProvider.notifier).setCurrentSession(null);
      }
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Set current active session
  void setCurrentSession(ChatSessionEntity? session) {
    _currentSession = session;
    // Update the messages provider with the new current session
    ref.read(chatMessagesProvider.notifier).setCurrentSession(session);
  }

  /// Get current active session
  ChatSessionEntity? get currentSession => _currentSession;

  /// Update session title
  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    state = await AsyncValue.guard(() async {
      final currentSessions = await _fetchSessions();
      return currentSessions.map((session) {
        if (session.id == sessionId) {
          return session.copyWith(title: newTitle);
        }
        return session;
      }).toList();
    });
  }

  /// Get session by ID
  Future<ChatSessionEntity?> getSessionById(String sessionId) async {
    final sessions = await future;
    try {
      return sessions.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      return null;
    }
  }
}

// Provider for chat sessions
final chatSessionsProvider =
    AsyncNotifierProvider<ChatSessionsNotifier, List<ChatSessionEntity>>(
  () => ChatSessionsNotifier(),
);

// Provider for current session
final currentSessionProvider = Provider<ChatSessionEntity?>((ref) {
  return ref.watch(chatSessionsProvider.notifier).currentSession;
});

// Provider for sessions count
final chatSessionsCountProvider = Provider<int>((ref) {
  final sessionsAsync = ref.watch(chatSessionsProvider);
  return sessionsAsync.maybeWhen(
    data: (sessions) => sessions.length,
    orElse: () => 0,
  );
});
