import 'dart:async';

import '../translation_request_entity.dart';
import '../translation_result_entity.dart';
import '../translator_repository.dart';

class TranslateWithStreamingUseCase {
  const TranslateWithStreamingUseCase(this._repository);

  final TranslatorRepository _repository;

  Stream<TranslationResultEntity>? call(TranslationRequestEntity request) {
    return _repository.translateWithStreaming(request);
  }
}
