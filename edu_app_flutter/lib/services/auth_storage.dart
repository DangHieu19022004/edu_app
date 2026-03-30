import 'package:edu_app_flutter/models/auth_tokens.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSnapshot {
  const AuthSnapshot({
    required this.tokens,
    required this.uid,
  });

  final AuthTokens tokens;
  final String uid;
}

abstract class AuthStorage {
  Future<void> saveSession(AuthSnapshot snapshot);
  Future<AuthSnapshot?> loadSession();
  Future<void> clearSession();
}

class InMemoryAuthStorage implements AuthStorage {
  AuthSnapshot? _snapshot;

  @override
  Future<void> saveSession(AuthSnapshot snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<AuthSnapshot?> loadSession() async {
    return _snapshot;
  }

  @override
  Future<void> clearSession() async {
    _snapshot = null;
  }
}

class SecureAuthStorage implements AuthStorage {
  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUid = 'auth_uid';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<void> saveSession(AuthSnapshot snapshot) async {
    await _storage.write(key: _keyAccessToken, value: snapshot.tokens.accessToken);
    await _storage.write(key: _keyRefreshToken, value: snapshot.tokens.refreshToken);
    await _storage.write(key: _keyUid, value: snapshot.uid);
  }

  @override
  Future<AuthSnapshot?> loadSession() async {
    final accessToken = await _storage.read(key: _keyAccessToken);
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    final uid = await _storage.read(key: _keyUid);

    if (accessToken == null || uid == null) {
      return null;
    }

    if (accessToken.isEmpty || uid.isEmpty) {
      return null;
    }

    return AuthSnapshot(
      tokens: AuthTokens(accessToken: accessToken, refreshToken: refreshToken ?? ''),
      uid: uid,
    );
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUid);
  }
}
