import 'package:crypto_dash/core/errors/exception_mapping.dart';
import 'package:crypto_dash/core/errors/failure.dart';
import 'package:dio/dio.dart';

/// Minimal CoinMarketCap (CMC) API client for /cryptocurrency/listings/latest.
/// Uses a supplied API key (header: X-CMC_PRO_API_KEY).
class CmcApiClient {
  CmcApiClient(this._dio);
  final Dio _dio;

  static Dio buildDio({
    String baseUrl = 'https://pro-api.coinmarketcap.com',
    String? apiKey,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
      ),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (apiKey != null && apiKey.isNotEmpty) {
              options.headers['X-CMC_PRO_API_KEY'] = apiKey;
            }
            handler.next(options);
          },
        ),
      );
    return dio;
  }

  Future<List<Map<String, dynamic>>> fetchLatestListings({
    int limit = 50,
    String convert = 'USD',
  }) async {
    try {
      final res = await _dio.get(
        '/v1/cryptocurrency/listings/latest',
        queryParameters: {'limit': limit, 'convert': convert},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final list = data['data'];
        if (list is List) return list.cast<Map<String, dynamic>>();
      }
      throw const ParsingFailure(message: 'Unexpected CMC listings payload');
    } catch (e, st) {
      throw mapException(e, st);
    }
  }
}
