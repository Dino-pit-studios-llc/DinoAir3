import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/datasources/calendar_remote_data_source.dart';
import '../../data/repositories/calendar_event_repository_impl.dart';
import '../../domain/calendar_event_repository.dart';

final calendarRepositoryProvider = Provider<CalendarEventRepository>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  final dataSource = CalendarRemoteDataSource(
    dio: dio,
    baseUrl: baseUrl,
  );

  return CalendarEventRepositoryImpl(remoteDataSource: dataSource);
});
