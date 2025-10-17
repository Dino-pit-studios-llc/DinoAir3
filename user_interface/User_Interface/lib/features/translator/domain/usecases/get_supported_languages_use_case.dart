import '../translator_repository.dart';

class GetSupportedLanguagesUseCase {
  const GetSupportedLanguagesUseCase(this._repository);

  final TranslatorRepository _repository;

  Future<List<String>> call() {
    return _repository.getSupportedLanguages();
  }
}
