import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/file_search_result.dart';

part 'file_search_result_dto.freezed.dart';
part 'file_search_result_dto.g.dart';

/// Data Transfer Object for FileSearchResult.
///
/// This DTO handles JSON serialization/deserialization for API communication
/// and provides conversion methods to/from domain entities.
@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class FileSearchResultDTO with _$FileSearchResultDTO {
  const factory FileSearchResultDTO({
    required String filePath,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String lastModified,
    required double relevanceScore,
    required List<String> matchedKeywords,
    String? fileContent,
    Map<String, dynamic>? metadata,
  }) = _FileSearchResultDTO;

  const FileSearchResultDTO._();

  factory FileSearchResultDTO.fromJson(Map<String, dynamic> json) =>
      _$FileSearchResultDTOFromJson(json);

  /// Convert DTO to domain entity
  FileSearchResult toEntity() {
    return FileSearchResult(
      filePath: filePath,
      fileName: fileName,
      fileType: fileType,
      fileSize: fileSize,
      lastModified: DateTime.parse(lastModified),
      relevanceScore: relevanceScore,
      matchedKeywords: matchedKeywords,
      fileContent: fileContent,
      metadata: metadata,
    );
  }

  /// Convert domain entity to DTO
  factory FileSearchResultDTO.fromEntity(FileSearchResult entity) {
    return FileSearchResultDTO(
      filePath: entity.filePath,
      fileName: entity.fileName,
      fileType: entity.fileType,
      fileSize: entity.fileSize,
      lastModified: entity.lastModified.toIso8601String(),
      relevanceScore: entity.relevanceScore,
      matchedKeywords: entity.matchedKeywords,
      fileContent: entity.fileContent,
      metadata: entity.metadata,
    );
  }
}
