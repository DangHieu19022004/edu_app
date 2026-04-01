class ApiConfig {
  ApiConfig._();

  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.50.31:8000',
  );

  static const String apiPrefix = '/api';

  static String get baseUrl => _normalizeBaseUrl(_rawBaseUrl);

  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  static String endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$apiBaseUrl$normalizedPath';
  }

  static String _normalizeBaseUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
