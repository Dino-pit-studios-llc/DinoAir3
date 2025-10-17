import '../ai_chat_repository.dart';
import '../chat_message_entity.dart';

class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final AiChatRepository _repository;

  Future<ChatMessageEntity> call(String message, {String? sessionId}) {
    return _repository.sendMessage(message, sessionId: sessionId);
  }
}
