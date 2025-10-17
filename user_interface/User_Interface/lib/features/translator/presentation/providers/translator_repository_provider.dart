import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/api/api_providers.dart';
import '../../data/translator_local_data_source.dart';
import '../../data/translator_remote_data_source.dart';
import '../../data/translator_repository_impl.dart';
import '../../domain/translator_repository.dart';

// Provider for the translator repository
final translatorRepositoryProvider = Provider<TranslatorRepository>((ref) {
  final dio = ref.watch(backendDioProvider);
  final remoteDataSource = TranslatorRemoteDataSource(dio);
  final localDataSource = TranslatorLocalDataSource();
  return TranslatorRepositoryImpl(remoteDataSource, localDataSource);
});
