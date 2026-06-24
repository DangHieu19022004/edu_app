import 'package:edu_app_flutter/models/auth_tokens.dart';

class FormRegisterRequest {
  const FormRegisterRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    };
  }
}

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatar,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String avatar;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      uid: (json['uid'] ?? '') as String,
      fullName: (json['full_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      avatar: (json['avatar'] ?? '') as String,
    );
  }
}

class FormRegisterResponse {
  const FormRegisterResponse({
    required this.message,
    required this.tokens,
    required this.user,
  });

  final String message;
  final AuthTokens tokens;
  final AuthUser user;

  factory FormRegisterResponse.fromJson(Map<String, dynamic> json) {
    return FormRegisterResponse(
      message: (json['message'] ?? '') as String,
      tokens: AuthTokens.fromJson(json),
      user: AuthUser.fromJson((json['user'] ?? <String, dynamic>{}) as Map<String, dynamic>),
    );
  }
}
