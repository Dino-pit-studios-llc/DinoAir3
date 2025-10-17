import 'package:flutter_riverpod/flutter_riverpod.dart';

// Loading state for different chat operations
enum ChatLoadingState {
  idle,
  sendingMessage,
  loadingHistory,
  creatingSession,
  deletingSession,
  refreshing,
}

// State class for chat loading
class ChatLoadingStateModel {
  const ChatLoadingStateModel({
    this.state = ChatLoadingState.idle,
    this.isLoading = false,
    this.error,
    this.progress,
  });

  final ChatLoadingState state;
  final bool isLoading;
  final String? error;
  final double? progress;

  ChatLoadingStateModel copyWith({
    ChatLoadingState? state,
    bool? isLoading,
    String? error,
    double? progress,
  }) {
    return ChatLoadingStateModel(
      state: state ?? this.state,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      progress: progress ?? this.progress,
    );
  }

  bool get hasError => error != null && error!.isNotEmpty;

  bool get isSendingMessage => state == ChatLoadingState.sendingMessage;

  bool get isLoadingHistory => state == ChatLoadingState.loadingHistory;

  bool get isCreatingSession => state == ChatLoadingState.creatingSession;

  bool get isDeletingSession => state == ChatLoadingState.deletingSession;

  bool get isRefreshing => state == ChatLoadingState.refreshing;
}

// State notifier for chat loading management
class ChatLoadingNotifier extends StateNotifier<ChatLoadingStateModel> {
  ChatLoadingNotifier() : super(const ChatLoadingStateModel());

  /// Set loading state for sending message
  void setSendingMessage({bool isLoading = true}) {
    state = state.copyWith(
      state: isLoading ? ChatLoadingState.sendingMessage : ChatLoadingState.idle,
      isLoading: isLoading,
      error: null,
    );
  }

  /// Set loading state for loading history
  void setLoadingHistory({bool isLoading = true}) {
    state = state.copyWith(
      state: isLoading ? ChatLoadingState.loadingHistory : ChatLoadingState.idle,
      isLoading: isLoading,
      error: null,
    );
  }

  /// Set loading state for creating session
  void setCreatingSession({bool isLoading = true}) {
    state = state.copyWith(
      state: isLoading ? ChatLoadingState.creatingSession : ChatLoadingState.idle,
      isLoading: isLoading,
      error: null,
    );
  }

  /// Set loading state for deleting session
  void setDeletingSession({bool isLoading = true}) {
    state = state.copyWith(
      state: isLoading ? ChatLoadingState.deletingSession : ChatLoadingState.idle,
      isLoading: isLoading,
      error: null,
    );
  }

  /// Set loading state for refreshing
  void setRefreshing({bool isLoading = true}) {
    state = state.copyWith(
      state: isLoading ? ChatLoadingState.refreshing : ChatLoadingState.idle,
      isLoading: isLoading,
      error: null,
    );
  }

  /// Set error state
  void setError(String? error) {
    state = state.copyWith(
      error: error,
      isLoading: false,
      state: ChatLoadingState.idle,
    );
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Set progress for long-running operations
  void setProgress(double? progress) {
    state = state.copyWith(progress: progress);
  }

  /// Set idle state
  void setIdle() {
    state = state.copyWith(
      state: ChatLoadingState.idle,
      isLoading: false,
      error: null,
      progress: null,
    );
  }

  /// Check if currently sending message
  bool get isSendingMessage => state.state == ChatLoadingState.sendingMessage;

  /// Check if currently loading history
  bool get isLoadingHistory => state.state == ChatLoadingState.loadingHistory;

  /// Check if currently creating session
  bool get isCreatingSession => state.state == ChatLoadingState.creatingSession;

  /// Check if currently deleting session
  bool get isDeletingSession => state.state == ChatLoadingState.deletingSession;

  /// Check if currently refreshing
  bool get isRefreshing => state.state == ChatLoadingState.refreshing;

  /// Check if any loading operation is in progress
  bool get isLoading => state.isLoading;

  /// Get current error message
  String? get error => state.error;

  /// Get current progress
  double? get progress => state.progress;
}

// Provider for chat loading state
final chatLoadingProvider =
    StateNotifierProvider<ChatLoadingNotifier, ChatLoadingStateModel>(
  (ref) => ChatLoadingNotifier(),
);

// Provider for loading state (computed)
final chatIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(chatLoadingProvider).isLoading;
});

// Provider for error state (computed)
final chatErrorProvider = Provider<String?>((ref) {
  return ref.watch(chatLoadingProvider).error;
});

// Provider for sending message state (computed)
final chatIsSendingMessageProvider = Provider<bool>((ref) {
  return ref.watch(chatLoadingProvider).isSendingMessage;
});

// Provider for loading history state (computed)
final chatIsLoadingHistoryProvider = Provider<bool>((ref) {
  return ref.watch(chatLoadingProvider).isLoadingHistory;
});

// Provider for creating session state (computed)
final chatIsCreatingSessionProvider = Provider<bool>((ref) {
  return ref.watch(chatLoadingProvider).isCreatingSession;
});

// Provider for deleting session state (computed)
final chatIsDeletingSessionProvider = Provider<bool>((ref) {
  return ref.watch(chatLoadingProvider).isDeletingSession;
});

// Provider for refreshing state (computed)
final chatIsRefreshingProvider = Provider<bool>((ref) {
  return ref.watch(chatLoadingProvider).isRefreshing;
});

// Provider for progress state (computed)
final chatProgressProvider = Provider<double?>((ref) {
  return ref.watch(chatLoadingProvider).progress;
});
