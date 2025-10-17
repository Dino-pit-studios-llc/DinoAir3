import '../ai_chat_repository.dart';

class ClearSessionUseCase {
  const ClearSessionUseCase(this._repository);

  final AiChatRepository _repository;

  Future<void> call(String sessionId) {
    return _repository.clearSession(sessionId);
  }
}
