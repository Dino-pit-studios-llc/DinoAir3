import '../ai_chat_repository.dart';

class CreateSessionUseCase {
  const CreateSessionUseCase(this._repository);

  final AiChatRepository _repository;

  Future<String> call({String? title}) {
    return _repository.createSession(title: title);
  }
}
