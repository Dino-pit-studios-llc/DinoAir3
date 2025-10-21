import 'package:crypto_dash/features/ai_chat/data/chat_dto.dart';
import 'package:crypto_dash/features/ai_chat/data/chat_local_data_source.dart';
import 'package:crypto_dash/features/ai_chat/data/chat_remote_data_source.dart';
import 'package:crypto_dash/features/ai_chat/data/chat_repository_impl.dart';
import 'package:crypto_dash/features/ai_chat/domain/chat_message_entity.dart';
import 'package:crypto_dash/features/ai_chat/domain/chat_session_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_repository_impl_test.mocks.dart';

@GenerateMocks([ChatRemoteDataSource, ChatLocalDataSource])
void main() {
  late ChatRepositoryImpl repository;
  late MockChatRemoteDataSource mockRemoteDataSource;
  late MockChatLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockChatRemoteDataSource();
    mockLocalDataSource = MockChatLocalDataSource();
    repository = ChatRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('ChatRepositoryImpl', () {
    group('sendMessage', () {
      const testMessage = 'Hello, AI!';
      const testSessionId = 'session123';
      final testResponseDto = ChatResponseDto(
        message: 'Hello! How can I help you?',
        sessionId: testSessionId,
      );
      final testTimestamp = DateTime.now();

      test('should send message and return ChatMessageEntity on success',
          () async {
        // Arrange
        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => testResponseDto);
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => Future.value());
        when(mockLocalDataSource.getCachedHistory(testSessionId))
            .thenAnswer((_) async => []);
        when(mockLocalDataSource.updateSessionMessageCount(any, any))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.sendMessage(
          testMessage,
          sessionId: testSessionId,
        );

        // Assert
        expect(result, isA<ChatMessageEntity>());
        expect(result.content, testResponseDto.message);
        expect(result.sessionId, testSessionId);
        expect(result.role, MessageRole.assistant);

        verify(mockRemoteDataSource.sendMessage(any)).called(1);
        verify(mockLocalDataSource.saveMessage(any)).called(1);
        verify(mockLocalDataSource.getCachedHistory(testSessionId)).called(1);
      });

      test('should cache message locally after sending', () async {
        // Arrange
        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => testResponseDto);
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => Future.value());
        when(mockLocalDataSource.getCachedHistory(testSessionId))
            .thenAnswer((_) async => []);
        when(mockLocalDataSource.updateSessionMessageCount(any, any))
            .thenAnswer((_) async => Future.value());

        // Act
        await repository.sendMessage(testMessage, sessionId: testSessionId);

        // Assert
        verify(mockLocalDataSource.saveMessage(
          argThat(predicate<ChatMessageEntity>((msg) =>
              msg.content == testResponseDto.message &&
              msg.sessionId == testSessionId)),
        )).called(1);
      });

      test('should update session message count after sending', () async {
        // Arrange
        final cachedMessages = [
          ChatMessageEntity(
            id: '1',
            sessionId: testSessionId,
            role: MessageRole.user,
            content: 'Previous message',
            timestamp: testTimestamp,
          ),
        ];

        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => testResponseDto);
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => Future.value());
        when(mockLocalDataSource.getCachedHistory(testSessionId))
            .thenAnswer((_) async => cachedMessages);
        when(mockLocalDataSource.updateSessionMessageCount(any, any))
            .thenAnswer((_) async => Future.value());

        // Act
        await repository.sendMessage(testMessage, sessionId: testSessionId);

        // Assert
        verify(mockLocalDataSource.updateSessionMessageCount(
          testSessionId,
          cachedMessages.length,
        )).called(1);
      });

      test('should work without session ID', () async {
        // Arrange
        final responseDto = ChatResponseDto(
          message: 'Hello! How can I help you?',
          sessionId: 'default',
        );

        when(mockRemoteDataSource.sendMessage(any))
            .thenAnswer((_) async => responseDto);
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.sendMessage(testMessage);

        // Assert
        expect(result, isA<ChatMessageEntity>());
        expect(result.content, responseDto.message);
        verify(mockRemoteDataSource.sendMessage(any)).called(1);
      });
    });

    group('getChatHistory', () {
      const testSessionId = 'session123';
      final testTimestamp = DateTime.now();
      final testResponseDtos = [
        ChatResponseDto(
          message: 'First message',
          sessionId: testSessionId,
        ),
        ChatResponseDto(
          message: 'Second message',
          sessionId: testSessionId,
        ),
      ];

      test('should fetch history from remote and cache it', () async {
        // Arrange
        when(mockRemoteDataSource.getChatHistory(testSessionId))
            .thenAnswer((_) async => testResponseDtos);
        when(mockLocalDataSource.saveMessage(any))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.getChatHistory(testSessionId);

        // Assert
        expect(result, isA<List<ChatMessageEntity>>());
        expect(result.length, testResponseDtos.length);
        verify(mockRemoteDataSource.getChatHistory(testSessionId)).called(1);
        verify(mockLocalDataSource.saveMessage(any))
            .called(testResponseDtos.length);
      });

      test('should return cached history when remote fails', () async {
        // Arrange
        final cachedMessages = [
          ChatMessageEntity(
            id: '1',
            sessionId: testSessionId,
            role: MessageRole.user,
            content: 'Cached message',
            timestamp: testTimestamp,
          ),
        ];

        when(mockRemoteDataSource.getChatHistory(testSessionId))
            .thenThrow(Exception('Network error'));
        when(mockLocalDataSource.getCachedHistory(testSessionId))
            .thenAnswer((_) async => cachedMessages);

        // Act
        final result = await repository.getChatHistory(testSessionId);

        // Assert
        expect(result, equals(cachedMessages));
        verify(mockLocalDataSource.getCachedHistory(testSessionId)).called(1);
      });
    });

    group('clearSession', () {
      const testSessionId = 'session123';

      test('should clear both remote and local session', () async {
        // Arrange
        when(mockRemoteDataSource.clearSession(testSessionId))
            .thenAnswer((_) async => Future.value());
        when(mockLocalDataSource.clearCachedSession(testSessionId))
            .thenAnswer((_) async => Future.value());

        // Act
        await repository.clearSession(testSessionId);

        // Assert
        verify(mockRemoteDataSource.clearSession(testSessionId)).called(1);
        verify(mockLocalDataSource.clearCachedSession(testSessionId))
            .called(1);
      });

      test('should clear local cache even if remote fails', () async {
        // Arrange
        when(mockRemoteDataSource.clearSession(testSessionId))
            .thenThrow(Exception('Network error'));
        when(mockLocalDataSource.clearCachedSession(testSessionId))
            .thenAnswer((_) async => Future.value());

        // Act
        await repository.clearSession(testSessionId);

        // Assert
        verify(mockLocalDataSource.clearCachedSession(testSessionId))
            .called(1);
      });
    });

    group('getChatSessions', () {
      final testSessionDtos = [
        ChatSessionDto(
          id: 'session1',
          title: 'First Session',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          messageCount: 5,
        ),
        ChatSessionDto(
          id: 'session2',
          title: 'Second Session',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          messageCount: 3,
        ),
      ];

      test('should fetch sessions from remote and cache them', () async {
        // Arrange
        when(mockRemoteDataSource.getChatSessions())
            .thenAnswer((_) async => testSessionDtos);
        when(mockLocalDataSource.saveSession(any))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.getChatSessions();

        // Assert
        expect(result, isA<List<ChatSessionEntity>>());
        expect(result.length, testSessionDtos.length);
        verify(mockRemoteDataSource.getChatSessions()).called(1);
        verify(mockLocalDataSource.saveSession(any))
            .called(testSessionDtos.length);
      });

      test('should return cached sessions when remote fails', () async {
        // Arrange
        final cachedSessions = [
          ChatSessionEntity(
            id: 'session1',
            title: 'Cached Session',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            messageCount: 2,
          ),
        ];

        when(mockRemoteDataSource.getChatSessions())
            .thenThrow(Exception('Network error'));
        when(mockLocalDataSource.getCachedSessions())
            .thenAnswer((_) async => cachedSessions);

        // Act
        final result = await repository.getChatSessions();

        // Assert
        expect(result, equals(cachedSessions));
        verify(mockLocalDataSource.getCachedSessions()).called(1);
      });
    });

    group('createSession', () {
      const testTitle = 'New Chat Session';
      const testSessionId = 'new_session_123';

      test('should create session remotely and cache it locally', () async {
        // Arrange
        when(mockRemoteDataSource.createSession(title: testTitle))
            .thenAnswer((_) async => testSessionId);
        when(mockLocalDataSource.saveSession(any))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.createSession(title: testTitle);

        // Assert
        expect(result, testSessionId);
        verify(mockRemoteDataSource.createSession(title: testTitle)).called(1);
        verify(mockLocalDataSource.saveSession(
          argThat(predicate<ChatSessionEntity>((session) =>
              session.id == testSessionId && session.title == testTitle)),
        )).called(1);
      });

      test('should use default title when none provided', () async {
        // Arrange
        when(mockRemoteDataSource.createSession(title: null))
            .thenAnswer((_) async => testSessionId);
        when(mockLocalDataSource.saveSession(any))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.createSession();

        // Assert
        expect(result, testSessionId);
        verify(mockLocalDataSource.saveSession(
          argThat(predicate<ChatSessionEntity>(
              (session) => session.title == 'New Chat Session')),
        )).called(1);
      });
    });

    group('clearAllCache', () {
      test('should clear all cached data', () async {
        // Arrange
        when(mockLocalDataSource.clearAllCache())
            .thenAnswer((_) async => Future.value());

        // Act
        await repository.clearAllCache();

        // Assert
        verify(mockLocalDataSource.clearAllCache()).called(1);
      });
    });

    group('initialize', () {
      test('should initialize local storage', () async {
        // Arrange
        when(mockLocalDataSource.init())
            .thenAnswer((_) async => Future.value());

        // Act
        await repository.initialize();

        // Assert
        verify(mockLocalDataSource.init()).called(1);
      });
    });
  });
}
