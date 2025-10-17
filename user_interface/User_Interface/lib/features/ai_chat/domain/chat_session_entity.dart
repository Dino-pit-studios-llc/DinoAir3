import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_session_entity.freezed.dart';
part 'chat_session_entity.g.dart';

@freezed
class ChatSessionEntity with _$ChatSessionEntity {
  const factory ChatSessionEntity({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int messageCount,
  }) = _ChatSessionEntity;

  factory ChatSessionEntity.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionEntityFromJson(json);
}
