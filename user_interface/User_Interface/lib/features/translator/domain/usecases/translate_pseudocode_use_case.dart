import '../translation_request_entity.dart';
import '../translation_result_entity.dart';
import '../translator_repository.dart';

class TranslatePseudocodeUseCase {
  const TranslatePseudocodeUseCase(this._repository);

  final TranslatorRepository _repository;

  Future<TranslationResultEntity> call(TranslationRequestEntity request) {
    return _repository.translatePseudocode(request);
  }
}
