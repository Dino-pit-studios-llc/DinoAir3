import 'package:hive_flutter/hive_flutter.dart';

import 'package:crypto_dash/features/ai_chat/domain/chat_message_entity.dart';
import 'package:crypto_dash/features/ai_chat/domain/chat_session_entity.dart';

class ChatLocalDataSource {
  static const String _messagesBox = 'chat_messages';
  static const String _sessionsBox = 'chat_sessions';

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters for complex objects
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ChatSessionAdapter());
    }

    // Open boxes
    await Hive.openBox<ChatMessageEntity>(_messagesBox);
    await Hive.openBox<ChatSessionEntity>(_sessionsBox);
  }

  Future<void> saveMessage(ChatMessageEntity message) async {
    final box = Hive.box<ChatMessageEntity>(_messagesBox);

    // Save message by its ID
    await box.put(message.id, message);
  }

  Future<void> saveSession(ChatSessionEntity session) async {
    final box = Hive.box<ChatSessionEntity>(_sessionsBox);
    await box.put(session.id, session);
  }

  Future<List<ChatMessageEntity>> getCachedHistory(String sessionId) async {
    final box = Hive.box<ChatMessageEntity>(_messagesBox);

    // Filter messages by sessionId
    final sessionMessages = box.values
        .where((message) => message.sessionId == sessionId)
        .toList();

    // Sort by timestamp
    sessionMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sessionMessages;
  }

  Future<List<ChatSessionEntity>> getCachedSessions() async {
    final box = Hive.box<ChatSessionEntity>(_sessionsBox);
    return box.values.toList();
  }

  Future<void> clearCachedSession(String sessionId) async {
    final messageBox = Hive.box<ChatMessageEntity>(_messagesBox);
    final sessionBox = Hive.box<ChatSessionEntity>(_sessionsBox);

    // Delete messages for this session
    final keysToDelete = <dynamic>[];
    for (var key in messageBox.keys) {
      final message = messageBox.get(key);
      if (message != null && message.sessionId == sessionId) {
        keysToDelete.add(key);
      }
    }
    for (var key in keysToDelete) {
      await messageBox.delete(key);
    }

    // Remove the session itself
    await sessionBox.delete(sessionId);
  }

  Future<void> clearAllCache() async {
    final messageBox = Hive.box<ChatMessageEntity>(_messagesBox);
    final sessionBox = Hive.box<ChatSessionEntity>(_sessionsBox);

    await messageBox.clear();
    await sessionBox.clear();
  }

  Future<void> updateSessionMessageCount(String sessionId, int messageCount) async {
    final box = Hive.box<ChatSessionEntity>(_sessionsBox);
    final session = box.get(sessionId);

    if (session != null) {
      final updatedSession = ChatSessionEntity(
        id: session.id,
        title: session.title,
        createdAt: session.createdAt,
        updatedAt: DateTime.now().toUtc(),
        messageCount: messageCount,
      );
      await box.put(sessionId, updatedSession);
    }
  }

}

// Hive adapters for complex objects
class ChatMessageAdapter extends TypeAdapter<ChatMessageEntity> {
  @override
  final int typeId = 0;

  @override
  ChatMessageEntity read(BinaryReader reader) {
    return ChatMessageEntity(
      id: reader.readString(),
      sessionId: reader.readString(),
      role: MessageRole.values[reader.readInt()],
      content: reader.readString(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      toolCalls: reader.read() as List<dynamic>?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessageEntity obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.sessionId);
    writer.writeInt(obj.role.index);
    writer.writeString(obj.content);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.write(obj.toolCalls);
  }
}

class ChatSessionAdapter extends TypeAdapter<ChatSessionEntity> {
  @override
  final int typeId = 1;

  @override
  ChatSessionEntity read(BinaryReader reader) {
    return ChatSessionEntity(
      id: reader.readString(),
      title: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      messageCount: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatSessionEntity obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    writer.writeInt(obj.messageCount);
  }
}
