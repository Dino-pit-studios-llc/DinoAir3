import 'dart:async';

import 'package:dio/dio.dart';

import 'package:crypto_dash/core/errors/api_exception.dart';
import 'package:crypto_dash/services/api/api_endpoints.dart';

import 'chat_dto.dart';

class ChatRemoteDataSource {
  const ChatRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ChatResponseDto> sendMessage(ChatRequestDto request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.aiChat,
        data: request.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiParsingException(message: 'Chat response was empty');
      }
      return ChatResponseDto.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to send message');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse chat response',
        details: error,
      );
    }
  }

  Future<List<ChatResponseDto>> getChatHistory(String sessionId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiEndpoints.aiChat}/history',
        queryParameters: {'session_id': sessionId},
      );
      final data = response.data ?? const [];
      return data
          .map((item) => _decodeChatResponse(item))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to load chat history');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse chat history response',
        details: error,
      );
    }
  }

  Future<void> clearSession(String sessionId) async {
    try {
      await _dio.delete<void>(
        '${ApiEndpoints.aiChat}/session',
        queryParameters: {'session_id': sessionId},
      );
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to clear session');
    }
  }

  Future<List<ChatSessionDto>> getChatSessions() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiEndpoints.aiChat}/sessions',
      );
      final data = response.data ?? const [];
      return data
          .map((item) => _decodeChatSession(item))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to load chat sessions');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse chat sessions response',
        details: error,
      );
    }
  }

  Future<String> createSession({String? title}) async {
    try {
      final requestData = <String, dynamic>{};
      if (title != null && title.trim().isNotEmpty) {
        requestData['title'] = title.trim();
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.aiChat}/session',
        data: requestData.isEmpty ? null : requestData,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiParsingException(message: 'Create session response was empty');
      }

      final sessionId = data['session_id'] ?? data['sessionId'];
      if (sessionId == null || sessionId.toString().isEmpty) {
        throw const ApiParsingException(message: 'Invalid session ID in response');
      }

      return sessionId.toString();
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to create session');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse create session response',
        details: error,
      );
    }
  }

  Stream<ChatResponseDto>? getMessageStream(String sessionId) {
    // TODO: Implement streaming for future SSE support
    // For now, return null as streaming is not yet implemented
    return null;
  }

  ChatResponseDto _decodeChatResponse(Object? item) {
    if (item is Map<String, dynamic>) {
      return ChatResponseDto.fromJson(item);
    }
    if (item is Map) {
      return ChatResponseDto.fromJson(Map<String, dynamic>.from(item));
    }
    throw const ApiParsingException(message: 'Invalid chat response item');
  }

  ChatSessionDto _decodeChatSession(Object? item) {
    if (item is Map<String, dynamic>) {
      return ChatSessionDto.fromJson(item);
    }
    if (item is Map) {
      return ChatSessionDto.fromJson(Map<String, dynamic>.from(item));
    }
    throw const ApiParsingException(message: 'Invalid chat session item');
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
