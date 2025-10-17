import '../ai_chat_repository.dart';
import '../chat_session_entity.dart';

class GetChatSessionsUseCase {
  const GetChatSessionsUseCase(this._repository);

  final AiChatRepository _repository;

  Future<List<ChatSessionEntity>> call() {
    return _repository.getChatSessions();
  }
}
