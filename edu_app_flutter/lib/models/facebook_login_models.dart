import 'package:edu_app_flutter/models/auth_tokens.dart';
import 'package:edu_app_flutter/models/form_register_models.dart';

class FacebookLoginRequest {
  const FacebookLoginRequest({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String photoUrl;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoURL': photoUrl,
    };
  }
}

class FacebookLoginResponse {
  const FacebookLoginResponse({
    required this.message,
    required this.tokens,
    required this.user,
  });

  final String message;
  final AuthTokens tokens;
  final AuthUser user;

  factory FacebookLoginResponse.fromJson(Map<String, dynamic> json) {
    return FacebookLoginResponse(
      message: (json['message'] ?? '') as String,
      tokens: AuthTokens.fromJson(json),
      user: AuthUser.fromJson(
        (json['user'] ?? <String, dynamic>{}) as Map<String, dynamic>,
      ),
    );
  }
}
