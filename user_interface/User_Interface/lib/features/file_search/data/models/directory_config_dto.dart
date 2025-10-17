import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/directory_config.dart';

part 'directory_config_dto.freezed.dart';
part 'directory_config_dto.g.dart';

/// Data Transfer Object for DirectoryConfig.
///
/// This DTO handles JSON serialization/deserialization for API communication
/// and provides conversion methods to/from domain entities.
@JsonSerializable(fieldRename: FieldRename.snake)
@freezed
class DirectoryConfigDTO with _$DirectoryConfigDTO {
  const factory DirectoryConfigDTO({
    required String path,
    required bool isWatched,
    required bool includeSubdirectories,
    required List<String> fileExtensions,
    String? lastIndexed,
    int? indexedFileCount,
  }) = _DirectoryConfigDTO;

  const DirectoryConfigDTO._();

  factory DirectoryConfigDTO.fromJson(Map<String, dynamic> json) =>
      _$DirectoryConfigDTOFromJson(json);

  /// Convert DTO to domain entity
  DirectoryConfig toEntity() {
    return DirectoryConfig(
      path: path,
      isWatched: isWatched,
      includeSubdirectories: includeSubdirectories,
      fileExtensions: fileExtensions,
      lastIndexed: lastIndexed != null ? DateTime.tryParse(lastIndexed!) : null,
      indexedFileCount: indexedFileCount,
    );
  }

  /// Convert domain entity to DTO
  factory DirectoryConfigDTO.fromEntity(DirectoryConfig entity) {
    return DirectoryConfigDTO(
      path: entity.path,
      isWatched: entity.isWatched,
      includeSubdirectories: entity.includeSubdirectories,
      fileExtensions: entity.fileExtensions,
      lastIndexed: entity.lastIndexed?.toIso8601String(),
      indexedFileCount: entity.indexedFileCount,
    );
  }
}
