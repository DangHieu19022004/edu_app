import 'package:edu_app_flutter/models/auth_tokens.dart';
import 'package:edu_app_flutter/services/auth_storage.dart';

class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  AuthStorage _storage = InMemoryAuthStorage();

  AuthTokens? _tokens;
  String? _uid;

  bool get isAuthenticated {
    final token = _tokens?.accessToken ?? '';
    final currentUid = _uid ?? '';
    return token.isNotEmpty && currentUid.isNotEmpty;
  }
  String? get accessToken => _tokens?.accessToken;
  String? get refreshToken => _tokens?.refreshToken;
  String? get uid => _uid;

  void configureStorage(AuthStorage storage) {
    _storage = storage;
  }

  Future<void> bootstrap() async {
    final snapshot = await _storage.loadSession();
    if (snapshot == null) {
      return;
    }

    _tokens = snapshot.tokens;
    _uid = snapshot.uid;
  }

  Future<void> saveJwtSession({
    required AuthTokens tokens,
    required String uid,
  }) async {
    _tokens = tokens;
    _uid = uid;
    await _storage.saveSession(AuthSnapshot(tokens: tokens, uid: uid));
  }

  Future<void> clear() async {
    _tokens = null;
    _uid = null;
    await _storage.clearSession();
  }

  Map<String, String> jwtAuthHeaders({
    Map<String, String>? additionalHeaders,
  }) {
    final token = accessToken;
    if (token == null || token.isEmpty) {
      return {
        ...?additionalHeaders,
      };
    }

    return {
      'Authorization': 'Bearer $token',
      ...?additionalHeaders,
    };
  }
}
