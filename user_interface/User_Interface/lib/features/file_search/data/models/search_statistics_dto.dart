import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/search_statistics.dart';

part 'search_statistics_dto.freezed.dart';
part 'search_statistics_dto.g.dart';

/// Data Transfer Object for SearchStatistics.
///
/// This DTO handles JSON serialization/deserialization for API communication
/// and provides conversion methods to/from domain entities.
@freezed
class SearchStatisticsDTO with _$SearchStatisticsDTO {
  const factory SearchStatisticsDTO({
    @JsonKey(name: 'total_files') required int totalFiles,
    @JsonKey(name: 'indexed_files') required int indexedFiles,
    @JsonKey(name: 'total_directories') required int totalDirectories,
    @JsonKey(name: 'last_index_time') required String lastIndexTime,
    @JsonKey(name: 'file_type_distribution')
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
