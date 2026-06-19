import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  ApiConfig._();

  static const String _buildBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _defaultBaseUrl = 'http://192.168.168.231:8000';

  static const String apiPrefix = '/api';

  static String get baseUrl {
    final runtimeBaseUrl = (dotenv.env['API_BASE_URL'] ?? '').trim();
    final selected = _buildBaseUrl.isNotEmpty
        ? _buildBaseUrl
        : runtimeBaseUrl.isNotEmpty
            ? runtimeBaseUrl
            : _defaultBaseUrl;

    return _normalizeBaseUrl(selected);
  }

  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  static String endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$apiBaseUrl$normalizedPath';
  }

  static String _normalizeBaseUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
