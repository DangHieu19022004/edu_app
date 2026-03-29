import 'package:edu_app_flutter/models/auth_tokens.dart';
import 'package:edu_app_flutter/models/form_register_models.dart';

class GoogleLoginRequest {
  const GoogleLoginRequest({
    required this.token,
  });

  final String token;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }
}

class GoogleLoginResponse {
  const GoogleLoginResponse({
    required this.message,
    required this.tokens,
    required this.user,
  });

  final String message;
  final AuthTokens tokens;
  final AuthUser user;

  factory GoogleLoginResponse.fromJson(Map<String, dynamic> json) {
    return GoogleLoginResponse(
      message: (json['message'] ?? '') as String,
      tokens: AuthTokens.fromJson(json),
      user: AuthUser.fromJson(
        (json['user'] ?? <String, dynamic>{}) as Map<String, dynamic>,
      ),
    );
  }
}
