import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';
import '../../../services/api/api_endpoints.dart';
import 'project_dto.dart';

class ProjectRemoteDataSource {
  const ProjectRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ProjectDto>> fetchProjects({
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.projects,
        queryParameters: queryParameters,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiParsingException(message: 'Projects response was empty');
      }
      final projects = data['projects'] as List<dynamic>? ?? [];
      return projects
          .map((item) => _decodeProjectListItem(item))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to load projects');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse projects response',
        details: error,
      );
    }
  }

  Future<ProjectDto> fetchProject(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.project(id),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiParsingException(message: 'Project response was empty');
      }
      return ProjectDto.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error, fallbackMessage: 'Unable to load project');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse project response',
        details: error,
      );
    }
  }

  Future<ProjectDto> createProject(ProjectDto payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.projects,
        data: payload.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiParsingException(
          message: 'Create project response was empty',
        );
      }
      // Backend returns { id, message }, fetch the created project
      final projectId = data['id'] as String;
      return fetchProject(projectId);
    } on DioException catch (error) {
      throw _mapDioException(error,
          fallbackMessage: 'Unable to create project');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse create project response',
        details: error,
      );
    }
  }

  Future<ProjectDto> updateProject(ProjectDto payload) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.project(payload.id),
        data: payload.toJson(includeMetadata: true),
      );
      // Backend returns success message, fetch updated project
      return fetchProject(payload.id);
    } on DioException catch (error) {
      throw _mapDioException(error,
          fallbackMessage: 'Unable to update project');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse update project response',
        details: error,
      );
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.project(id));
    } on DioException catch (error) {
      throw _mapDioException(
        error,
        fallbackMessage: 'Unable to delete project',
      );
    }
  }

  Future<List<ProjectDto>> fetchChildProjects(String parentId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.project(parentId)}/children',
      );
      final data = response.data;
      if (data == null) {
        throw const ApiParsingException(
          message: 'Child projects response was empty',
        );
      }
      final projects = data['projects'] as List<dynamic>? ?? [];
      return projects
          .map((item) => _decodeProjectListItem(item))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioException(error,
          fallbackMessage: 'Unable to load child projects');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiParsingException(
        message: 'Failed to parse child projects response',
        details: error,
      );
    }
  }

  ProjectDto _decodeProjectListItem(Object? item) {
    if (item is Map<String, dynamic>) {
      return ProjectDto.fromJson(item);
    }
    if (item is Map) {
      return ProjectDto.fromJson(Map<String, dynamic>.from(item));
    }
    throw const ApiParsingException(message: 'Invalid project list item');
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
            ? (error.response?.data['detail']?.toString() ?? fallbackMessage)
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
          message: 'Request was cancelled',
          details: error,
        );
    }
  }
}
