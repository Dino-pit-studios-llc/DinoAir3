import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/search_statistics.dart';

part 'search_statistics_dto.freezed.dart';
part 'search_statistics_dto.g.dart';

/// Data Transfer Object for SearchStatistics.
///
/// This DTO handles JSON serialization/deserialization for API communication
/// and provides conversion methods to/from domain entities.
@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SearchStatisticsDTO with _$SearchStatisticsDTO {
  const factory SearchStatisticsDTO({
    required int totalFiles,
    required int indexedFiles,
    required int totalDirectories,
    required String lastIndexTime,
    required Map<String, int> fileTypeDistribution,
  }) = _SearchStatisticsDTO;

  const SearchStatisticsDTO._();

  factory SearchStatisticsDTO.fromJson(Map<String, dynamic> json) =>
      _$SearchStatisticsDTOFromJson(json);

  /// Convert DTO to domain entity
  SearchStatistics toEntity() {
    return SearchStatistics(
      totalFiles: totalFiles,
      indexedFiles: indexedFiles,
      totalDirectories: totalDirectories,
      lastIndexTime: DateTime.parse(lastIndexTime),
      fileTypeDistribution: fileTypeDistribution,
    );
  }

  /// Convert domain entity to DTO
  factory SearchStatisticsDTO.fromEntity(SearchStatistics entity) {
    return SearchStatisticsDTO(
      totalFiles: entity.totalFiles,
      indexedFiles: entity.indexedFiles,
      totalDirectories: entity.totalDirectories,
      lastIndexTime: entity.lastIndexTime.toIso8601String(),
      fileTypeDistribution: entity.fileTypeDistribution,
    );
  }
}
