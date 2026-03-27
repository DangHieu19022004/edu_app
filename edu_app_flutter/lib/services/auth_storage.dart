import 'package:edu_app_flutter/models/auth_tokens.dart';

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
