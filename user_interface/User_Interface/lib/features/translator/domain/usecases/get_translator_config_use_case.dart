import '../translator_config_entity.dart';
import '../translator_repository.dart';

class GetTranslatorConfigUseCase {
  const GetTranslatorConfigUseCase(this._repository);

  final TranslatorRepository _repository;

  Future<TranslatorConfigEntity> call() {
    return _repository.getTranslatorConfig();
  }
}
