import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity_service.dart';
import 'cmc_api_client.dart';
import 'coin_api_client.dart';
import 'dio_client.dart';

/// Attempts to read the CoinMarketCap API key from (priority order):
/// 1. --dart-define CMC_API_KEY
/// 2. .env file (loaded in bootstrap)
final coinMarketCapApiKeyProvider = Provider<String?>((ref) {
  const defineKey = String.fromEnvironment('CMC_API_KEY');
  if (defineKey.isNotEmpty) return defineKey;
  final envKey = dotenv.maybeGet('CMC_API_KEY');
  if (envKey != null && envKey.trim().isNotEmpty) return envKey.trim();
  return null; // indicates not configured
});

/// Provides the base URL for the DinoAir backend API.
final apiBaseUrlProvider = Provider<String>((ref) {
  const defineUrl = String.fromEnvironment('DINO_API_BASE_URL');
  if (defineUrl.isNotEmpty) return defineUrl;
  final envUrl = dotenv.maybeGet('DINO_API_BASE_URL');
  if (envUrl != null && envUrl.trim().isNotEmpty) {
    return envUrl.trim();
  }
  // Log a warning when falling back to localhost
  print(
      '[WARNING] DINO_API_BASE_URL is not configured. Falling back to default: http://localhost:24801. '
      'Please set DINO_API_BASE_URL in your environment or via --dart-define to avoid production misconfiguration.');
  return 'http://localhost:24801';
});

/// Configured Dio client for DinoAir backend requests.
final dioClientProvider = Provider<DioClient>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return DioClient(baseUrl: baseUrl);
});

/// Exposes the configured [Dio] instance for the DinoAir backend.
final backendDioProvider = Provider<Dio>((ref) {
  final client = ref.watch(dioClientProvider);
  return client.instance;
});

/// Shared connectivity service.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provides a configured Dio instance for the CoinGecko API.
final coinGeckoDioProvider = Provider<Dio>((ref) {
  return CoinApiClient.buildDio();
});

/// High-level CoinGecko API client provider.
final coinApiClientProvider = Provider<CoinApiClient>((ref) {
  final dio = ref.watch(coinGeckoDioProvider);
  return CoinApiClient(dio);
});

/// Provides a configured Dio instance for CoinMarketCap (adds API key header if present).
final cmcDioProvider = Provider<Dio>((ref) {
  final apiKey = ref.watch(coinMarketCapApiKeyProvider);
  return CmcApiClient.buildDio(apiKey: apiKey);
});

/// High-level CoinMarketCap API client provider.
final cmcApiClientProvider = Provider<CmcApiClient>((ref) {
  final dio = ref.watch(cmcDioProvider);
  return CmcApiClient(dio);
});
