import '../ai_chat_repository.dart';
import '../chat_message_entity.dart';

class GetChatHistoryUseCase {
  const GetChatHistoryUseCase(this._repository);

  final AiChatRepository _repository;

  Future<List<ChatMessageEntity>> call(String sessionId) {
    return _repository.getChatHistory(sessionId);
  }
}
