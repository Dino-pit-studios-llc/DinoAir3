import 'package:dio/dio.dart';

import 'package:crypto_dash/core/errors/api_exception.dart';
import 'package:crypto_dash/services/api/api_endpoints.dart';

import 'note_dto.dart';

class NoteRemoteDataSource {
  const NoteRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<NoteDto>> fetchNotes(
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.notes,
        queryParameters: queryParameters,
      );
      final data = response.data ?? const [];
      return data
          .map((item) => _decodeNoteListItem(item))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to load notes');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse notes response',
        details: error,
      );
    }
  }

  Future<NoteDto> fetchNote(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.note(id),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiParsingException(message: 'Note response was empty');
      }
      return NoteDto.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to load note');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse note response',
        details: error,
      );
    }
  }

  Future<NoteDto> createNote(NoteDto payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.notes,
        data: payload.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiParsingException(
            message: 'Create note response was empty');
      }
      return NoteDto.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to create note');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse create note response',
        details: error,
      );
    }
  }

  Future<NoteDto> updateNote(NoteDto payload) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.note(payload.id),
        data: payload.toJson(includeMetadata: true),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiParsingException(
            message: 'Update note response was empty');
      }
      return NoteDto.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to update note');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse update note response',
        details: error,
      );
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.note(id));
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to delete note');
    }
  }

  Future<List<NoteDto>> searchNotes({String? query, List<String>? tags}) {
    final params = <String, dynamic>{};
    if (query != null && query.trim().isNotEmpty) {
      params['query'] = query.trim();
    }
    if (tags != null && tags.isNotEmpty) {
      params['tags'] = tags.join(',');
    }
    return fetchNotes(queryParameters: params.isEmpty ? null : params);
  }

  NoteDto _decodeNoteListItem(Object? item) {
    if (item is Map<String, dynamic>) {
      return NoteDto.fromJson(item);
    }
    if (item is Map) {
      return NoteDto.fromJson(Map<String, dynamic>.from(item));
    }
    throw const ApiParsingException(message: 'Invalid note list item');
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
