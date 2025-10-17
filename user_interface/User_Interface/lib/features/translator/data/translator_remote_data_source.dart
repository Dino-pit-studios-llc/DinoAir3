import 'package:dio/dio.dart';

import 'package:crypto_dash/core/errors/api_exception.dart';
import 'package:crypto_dash/services/api/api_endpoints.dart';

import 'translator_dto.dart';

class TranslatorRemoteDataSource {
  const TranslatorRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TranslationResponseDto> translatePseudocode(TranslationRequestDto request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.translator,
        data: request.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiParsingException(message: 'Translation response was empty');
      }
      return TranslationResponseDto.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to translate pseudocode');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse translation response',
        details: error,
      );
    }
  }

  Future<List<String>> getSupportedLanguages() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiEndpoints.translator}/languages',
      );
      final data = response.data ?? const [];
      return data
          .map((item) => _decodeLanguageListItem(item))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to load supported languages');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse supported languages response',
        details: error,
      );
    }
  }

  Future<TranslatorConfigDto> getTranslatorConfig() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.translator}/config',
      );
      final data = response.data;
      if (data == null) {
        throw const ApiParsingException(message: 'Translator config response was empty');
      }
      return TranslatorConfigDto.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to load translator config');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse translator config response',
        details: error,
      );
    }
  }

  Future<void> updateTranslatorConfig(TranslatorConfigDto config) async {
    try {
      await _dio.put<void>(
        '${ApiEndpoints.translator}/config',
        data: config.toJson(),
      );
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to update translator config');
    }
  }

  Stream<TranslationResponseDto>? translateWithStreaming(TranslationRequestDto request) {
    // TODO: Implement streaming support when backend provides it
    // For now, return null to indicate streaming is not supported
    return null;
  }

  String _decodeLanguageListItem(Object? item) {
    if (item is String) {
      return item;
    }
    if (item is Map<String, dynamic>) {
      return item['code']?.toString() ?? item['name']?.toString() ?? item.toString();
    }
    if (item is Map) {
      return (item)['code']?.toString() ?? (item)['name']?.toString() ?? item.toString();
    }
    return item.toString();
  }

  ApiException _mapDioException(
    DioException error, {
    required String fallbackMessage,
  }) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiTimeoutException(message: fallbackMessage, details: error);
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data is Map<String, dynamic>
            ? (error.response?.data['message']?.toString() ?? fallbackMessage)
            : fallbackMessage;
        return ApiResponseException(
          message: message,
          statusCode: statusCode,
          details: error.response?.data,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return ApiNetworkException(message: fallbackMessage, details: error);
      case DioExceptionType.cancel:
        return ApiNetworkException(
            message: 'Request was cancelled', details: error);
    }
  }
}
