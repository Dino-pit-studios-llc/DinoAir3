import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/api/api_providers.dart';
import '../../data/chat_local_data_source.dart';
import '../../data/chat_remote_data_source.dart';
import '../../data/chat_repository_impl.dart';
import '../../domain/chat_message_entity.dart';
import '../../domain/chat_session_entity.dart';
import '../../domain/ai_chat_repository.dart';
import '../../domain/usecases/send_message_use_case.dart';
import '../../domain/usecases/get_chat_history_use_case.dart';

// Provider for the AI chat repository
final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  final dio = ref.watch(backendDioProvider);
  final remoteDataSource = ChatRemoteDataSource(dio);
  final localDataSource = ChatLocalDataSource();
  return ChatRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

// Provider for send message use case
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(aiChatRepositoryProvider));
});

// Provider for get chat history use case
final getChatHistoryUseCaseProvider = Provider<GetChatHistoryUseCase>((ref) {
  return GetChatHistoryUseCase(ref.watch(aiChatRepositoryProvider));
});

// State notifier for chat messages with session management
class ChatMessagesNotifier extends AsyncNotifier<List<ChatMessageEntity>> {
  ChatSessionEntity? _currentSession;
  final ScrollController _scrollController = ScrollController();

  ScrollController get scrollController => _scrollController;

  @override
  Future<List<ChatMessageEntity>> build() async {
    return [];
  }

  /// Set the current session and load its messages
  Future<void> setCurrentSession(ChatSessionEntity? session) async {
    _currentSession = session;
    if (session != null) {
      await loadMessagesForSession(session.id);
    } else {
      state = const AsyncValue.data([]);
    }
  }

  /// Load messages for a specific session
  Future<void> loadMessagesForSession(String sessionId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(getChatHistoryUseCaseProvider);
      return useCase(sessionId);
    });
  }

  /// Send a new message and add it to the current session
  Future<void> sendMessage(String content) async {
    if (_currentSession == null || content.trim().isEmpty) return;

    // Add user message immediately
    final userMessage = ChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: _currentSession!.id,
      role: MessageRole.user,
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    state = state.maybeWhen(
      data: (messages) => AsyncValue.data([...messages, userMessage]),
      orElse: () => AsyncValue.data([userMessage]),
    );

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      // Send message through use case
      final useCase = ref.read(sendMessageUseCaseProvider);
      final response = await useCase(
        content.trim(),
        sessionId: _currentSession!.id,
      );

      // Add assistant response
      state = state.maybeWhen(
        data: (messages) => AsyncValue.data([...messages, response]),
        orElse: () => AsyncValue.data([response]),
      );

      // Auto-scroll to bottom again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (error, stack) {
      // Handle error - you might want to show an error message in the UI
      state = AsyncValue.error(error, stack);
    }
  }

  /// Refresh messages for current session
  Future<void> refresh() async {
    if (_currentSession != null) {
      await loadMessagesForSession(_currentSession!.id);
    }
  }

  /// Clear messages for current session
  Future<void> clearMessages() async {
    state = const AsyncValue.data([]);
  }

  /// Auto-scroll to bottom of message list
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Get current session
  ChatSessionEntity? get currentSession => _currentSession;
}

// Provider for chat messages
final chatMessagesProvider =
    AsyncNotifierProvider<ChatMessagesNotifier, List<ChatMessageEntity>>(
  () => ChatMessagesNotifier(),
);

// Provider for current session
final currentChatSessionProvider = Provider<ChatSessionEntity?>((ref) {
  return ref.watch(chatMessagesProvider.notifier).currentSession;
});

// Provider for scroll controller
final chatScrollControllerProvider = Provider<ScrollController>((ref) {
  return ref.watch(chatMessagesProvider.notifier).scrollController;
});
