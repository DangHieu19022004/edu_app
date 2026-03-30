import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edu_app_flutter/constants/api_config.dart';
import 'package:edu_app_flutter/constants/api_endpoints.dart';
import 'package:edu_app_flutter/models/auth_tokens.dart';
import 'package:edu_app_flutter/models/app_loading_model.dart';
import 'package:edu_app_flutter/models/facebook_login_models.dart';
import 'package:edu_app_flutter/models/form_login_models.dart';
import 'package:edu_app_flutter/models/google_login_models.dart';
import 'package:edu_app_flutter/models/form_register_models.dart';
import 'package:edu_app_flutter/models/session_user.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<FormRegisterResponse> registerByForm(FormRegisterRequest request) async {
    return AppLoadingModel.instance.track(() async {
      final uri = Uri.parse(ApiConfig.endpoint(ApiEndpoints.usersFormRegister));

      late final http.Response response;
      try {
        response = await _client
            .post(
              uri,
              headers: const {
                'Content-Type': 'application/json',
              },
              body: jsonEncode(request.toJson()),
            )
            .timeout(const Duration(seconds: 15));
      } on SocketException {
        throw ApiException(
          message:
              'Khong the ket noi toi server ($uri). Neu ban dang dung dien thoai that, hay chay app voi --dart-define=API_BASE_URL=http://<IP-may-tinh>:8000',
        );
      } on TimeoutException {
        throw ApiException(
          message: 'Ket noi server bi timeout. Vui long kiem tra backend va mang.',
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: 'Loi ket noi: ${e.message}');
      }

      final bodyMap = _decodeJsonMap(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _extractErrorMessage(bodyMap),
          statusCode: response.statusCode,
        );
      }

      final registerResponse = FormRegisterResponse.fromJson(bodyMap);

      await AuthSession.instance.saveJwtSession(
        tokens: registerResponse.tokens,
        uid: registerResponse.user.uid,
        user: _toSessionUser(registerResponse.user),
      );

      return registerResponse;
    });
  }

  Future<FormLoginResponse> loginByForm(FormLoginRequest request) async {
    return AppLoadingModel.instance.track(() async {
      final uri = Uri.parse(ApiConfig.endpoint(ApiEndpoints.usersFormLogin));

      late final http.Response response;
      try {
        response = await _client
            .post(
              uri,
              headers: const {
                'Content-Type': 'application/json',
              },
              body: jsonEncode(request.toJson()),
            )
            .timeout(const Duration(seconds: 15));
      } on SocketException {
        throw ApiException(
          message:
              'Khong the ket noi toi server ($uri). Neu ban dang dung dien thoai that, hay chay app voi --dart-define=API_BASE_URL=http://<IP-may-tinh>:8000',
        );
      } on TimeoutException {
        throw ApiException(
          message: 'Ket noi server bi timeout. Vui long kiem tra backend va mang.',
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: 'Loi ket noi: ${e.message}');
      }

      final bodyMap = _decodeJsonMap(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _extractErrorMessage(bodyMap),
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode == 401) {
        throw ApiException(
          message: 'Sai thong tin dang nhap. Vui long kiem tra lai email/so dien thoai va mat khau.',
          statusCode: response.statusCode,
        );
      }

      final loginResponse = FormLoginResponse.fromJson(bodyMap);

      await AuthSession.instance.saveJwtSession(
        tokens: loginResponse.tokens,
        uid: loginResponse.user.uid,
        user: _toSessionUser(loginResponse.user),
      );

      return loginResponse;
    });
  }

  Future<GoogleLoginResponse> loginByGoogleToken(
    GoogleLoginRequest request,
  ) async {
    return AppLoadingModel.instance.track(() async {
      final uri = Uri.parse(ApiConfig.endpoint(ApiEndpoints.usersGoogleLogin));

      late final http.Response response;
      try {
        response = await _client
            .post(
              uri,
              headers: const {
                'Content-Type': 'application/json',
              },
              body: jsonEncode(request.toJson()),
            )
            .timeout(const Duration(seconds: 15));
      } on SocketException {
        throw ApiException(
          message:
              'Khong the ket noi toi server ($uri). Neu ban dang dung dien thoai that, hay chay app voi --dart-define=API_BASE_URL=http://<IP-may-tinh>:8000',
        );
      } on TimeoutException {
        throw ApiException(
          message: 'Ket noi server bi timeout. Vui long kiem tra backend va mang.',
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: 'Loi ket noi: ${e.message}');
      }

      final bodyMap = _decodeJsonMap(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _extractErrorMessage(bodyMap),
          statusCode: response.statusCode,
        );
      }

      final googleLoginResponse = GoogleLoginResponse.fromJson(bodyMap);

      await AuthSession.instance.saveJwtSession(
        tokens: googleLoginResponse.tokens,
        uid: googleLoginResponse.user.uid,
        user: _toSessionUser(googleLoginResponse.user),
      );

      return googleLoginResponse;
    });
  }

  Future<FacebookLoginResponse> loginByFacebookProfile(
    FacebookLoginRequest request,
  ) async {
    return AppLoadingModel.instance.track(() async {
      final uri = Uri.parse(ApiConfig.endpoint(ApiEndpoints.usersFacebookLogin));

      late final http.Response response;
      try {
        response = await _client
            .post(
              uri,
              headers: const {
                'Content-Type': 'application/json',
              },
              body: jsonEncode(request.toJson()),
            )
            .timeout(const Duration(seconds: 15));
      } on SocketException {
        throw ApiException(
          message:
              'Khong the ket noi toi server ($uri). Neu ban dang dung dien thoai that, hay chay app voi --dart-define=API_BASE_URL=http://<IP-may-tinh>:8000',
        );
      } on TimeoutException {
        throw ApiException(
          message: 'Ket noi server bi timeout. Vui long kiem tra backend va mang.',
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: 'Loi ket noi: ${e.message}');
      }

      final bodyMap = _decodeJsonMap(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _extractErrorMessage(bodyMap),
          statusCode: response.statusCode,
        );
      }

      final facebookLoginResponse = FacebookLoginResponse.fromJson(bodyMap);

      await AuthSession.instance.saveJwtSession(
        tokens: facebookLoginResponse.tokens,
        uid: facebookLoginResponse.user.uid,
        user: _toSessionUser(facebookLoginResponse.user),
      );

      return facebookLoginResponse;
    });
  }

  Future<bool> verifyToken({bool allowRefresh = true}) async {
    return AppLoadingModel.instance.track(() async {
      final token = AuthSession.instance.accessToken;
      if (token == null || token.isEmpty) {
        debugPrint('[AuthStartup] verifyToken skipped: no access token');
        return false;
      }

      final uri = Uri.parse(ApiConfig.endpoint(ApiEndpoints.usersVerifyToken));

      late final http.Response response;
      try {
        response = await _client
            .post(
              uri,
              headers: {
                ...AuthSession.instance.jwtAuthHeaders(),
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 15));
      } on SocketException {
        // Keep local session on transient network failures.
        debugPrint('[AuthStartup] verifyToken socket error -> keep local session');
        return true;
      } on TimeoutException {
        debugPrint('[AuthStartup] verifyToken timeout -> keep local session');
        return true;
      } on http.ClientException {
        debugPrint('[AuthStartup] verifyToken client error -> keep local session');
        return true;
      }

      debugPrint('[AuthStartup] verifyToken status=${response.statusCode}');

      if (response.statusCode == 401 && allowRefresh) {
        debugPrint('[AuthStartup] verifyToken got 401 -> try refresh');
        final refreshed = await _refreshSessionTokens();
        if (!refreshed) {
          debugPrint('[AuthStartup] refresh failed -> clear session');
          await AuthSession.instance.clear();
          return false;
        }
        debugPrint('[AuthStartup] refresh success -> verify again');
        return verifyToken(allowRefresh: false);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[AuthStartup] verifyToken non-2xx -> clear session');
        await AuthSession.instance.clear();
        return false;
      }

      final bodyMap = _decodeJsonMap(response.body);
      final userMap = (bodyMap['user'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      final verifiedUid = (userMap['uid'] ?? '').toString().trim();

      if (verifiedUid.isNotEmpty) {
        final refreshToken = AuthSession.instance.refreshToken ?? '';
        await AuthSession.instance.saveJwtSession(
          tokens: AuthTokens(accessToken: token, refreshToken: refreshToken),
          uid: verifiedUid,
          user: SessionUser.fromJson(userMap),
        );
      }

      return true;
    });
  }

  Future<bool> _refreshSessionTokens() async {
    final refreshToken = AuthSession.instance.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint('[AuthStartup] refresh skipped: no refresh token');
      return false;
    }

    final uri = Uri.parse(ApiConfig.endpoint(ApiEndpoints.usersRefreshToken));

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      debugPrint('[AuthStartup] refresh socket error');
      return false;
    } on TimeoutException {
      debugPrint('[AuthStartup] refresh timeout');
      return false;
    } on http.ClientException {
      debugPrint('[AuthStartup] refresh client error');
      return false;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[AuthStartup] refresh non-2xx status=${response.statusCode}');
      return false;
    }

    final bodyMap = _decodeJsonMap(response.body);
    final newTokens = AuthTokens.fromJson(bodyMap);
    if (!newTokens.isValid) {
      debugPrint('[AuthStartup] refresh invalid token payload');
      return false;
    }

    final userMap = (bodyMap['user'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final refreshedUid = (userMap['uid'] ?? '').toString().trim();
    final currentUid = AuthSession.instance.uid ?? '';
    final uidToStore = refreshedUid.isNotEmpty ? refreshedUid : currentUid;

    if (uidToStore.isEmpty) {
      debugPrint('[AuthStartup] refresh missing uid');
      return false;
    }

    final mergedUserMap = userMap.isNotEmpty
        ? userMap
        : (AuthSession.instance.user?.toJson() ?? <String, dynamic>{'uid': uidToStore});

    await AuthSession.instance.saveJwtSession(
      tokens: newTokens,
      uid: uidToStore,
      user: SessionUser.fromJson(mergedUserMap),
    );
    return true;
  }

  SessionUser _toSessionUser(AuthUser user) {
    return SessionUser(
      uid: user.uid,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      avatar: user.avatar,
    );
  }

  Map<String, dynamic> _decodeJsonMap(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(message: 'Invalid response format from server');
  }

  String _extractErrorMessage(Map<String, dynamic> bodyMap) {
    final error = bodyMap['error'];
    if (error is String && error.isNotEmpty) {
      return error;
    }

    final detail = bodyMap['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }

    final message = bodyMap['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    return 'Request failed';
  }
}
