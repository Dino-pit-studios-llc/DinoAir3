import 'package:crypto_dash/core/errors/exception_mapping.dart';
import 'package:crypto_dash/core/errors/failure.dart';
import 'package:dio/dio.dart';

/// Lightweight API client targeting CoinGecko endpoints used by the app.
/// Only implements the subset needed for the current feature scope.
class CoinApiClient {
  CoinApiClient(this._dio);
  final Dio _dio;

  static Dio buildDio({String baseUrl = 'https://api.coingecko.com/api/v3'}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchTopMarkets({
    String vsCurrency = 'usd',
    int perPage = 50,
    int page = 1,
    bool sparkline = true,
    String order = 'market_cap_desc',
  }) async {
    try {
      final res = await _dio.get(
        '/coins/markets',
        queryParameters: {
          'vs_currency': vsCurrency,
          'order': order,
          'per_page': perPage,
          'page': page,
          'sparkline': sparkline,
          'price_change_percentage': '24h',
        },
      );
      final data = res.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      throw const ParsingFailure(message: 'Unexpected markets payload shape');
    } catch (e, st) {
      throw mapException(e, st);
    }
  }

  Future<Map<String, dynamic>> fetchCoinDetail(
    String id, {
    String vsCurrency = 'usd',
  }) async {
    try {
      final res = await _dio.get(
        '/coins/$id',
        queryParameters: {
          'localization': false,
          'tickers': false,
          'market_data': true,
          'community_data': false,
          'developer_data': false,
          'sparkline': true,
        },
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      throw const ParsingFailure(
        message: 'Unexpected coin detail payload shape',
      );
    } catch (e, st) {
      throw mapException(e, st);
    }
  }

  Future<List<List<num>>> fetchMarketChart(
    String id, {
    String vsCurrency = 'usd',
    required int days,
    String interval = 'hourly',
  }) async {
    try {
      final res = await _dio.get(
        '/coins/$id/market_chart',
        queryParameters: {
          'vs_currency': vsCurrency,
          'days': days,
          'interval': interval,
        },
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final prices = data['prices'];
        if (prices is List) {
          return prices.cast<List>().map((e) => e.cast<num>()).toList();
        }
      }
      throw const ParsingFailure(message: 'Unexpected market chart payload');
    } catch (e, st) {
      throw mapException(e, st);
    }
  }
}
