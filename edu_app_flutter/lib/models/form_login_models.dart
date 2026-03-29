import 'package:edu_app_flutter/models/auth_tokens.dart';
import 'package:edu_app_flutter/models/form_register_models.dart';

class FormLoginRequest {
  const FormLoginRequest({
    required this.emailOrPhone,
    required this.password,
    this.legacyId,
  });

  final String emailOrPhone;
  final String password;
  final String? legacyId;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'email_or_phone': emailOrPhone,
      'password': password,
    };

    if (legacyId != null && legacyId!.isNotEmpty) {
      data['id'] = legacyId;
    }

    return data;
  }
}

class FormLoginResponse {
  const FormLoginResponse({
    required this.message,
    required this.tokens,
    required this.user,
  });

  final String message;
  final AuthTokens tokens;
  final AuthUser user;

  factory FormLoginResponse.fromJson(Map<String, dynamic> json) {
    return FormLoginResponse(
      message: (json['message'] ?? '') as String,
      tokens: AuthTokens.fromJson(json),
      user: AuthUser.fromJson(
        (json['user'] ?? <String, dynamic>{}) as Map<String, dynamic>,
      ),
    );
  }
}
