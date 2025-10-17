import '../translator_config_entity.dart';
import '../translator_repository.dart';

class UpdateTranslatorConfigUseCase {
  const UpdateTranslatorConfigUseCase(this._repository);

  final TranslatorRepository _repository;

  Future<void> call(TranslatorConfigEntity config) {
    return _repository.updateTranslatorConfig(config);
  }
}
