import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edu_app_flutter/constants/api_config.dart';
import 'package:edu_app_flutter/constants/api_endpoints.dart';
import 'package:edu_app_flutter/models/form_login_models.dart';
import 'package:edu_app_flutter/models/google_login_models.dart';
import 'package:edu_app_flutter/models/form_register_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<FormRegisterResponse> registerByForm(FormRegisterRequest request) async {
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
    );

    return registerResponse;
  }

  Future<FormLoginResponse> loginByForm(FormLoginRequest request) async {
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
    if(response.statusCode == 401){
      throw ApiException(
        message: 'Sai thong tin dang nhap. Vui long kiem tra lai email/so dien thoai va mat khau.',
        statusCode: response.statusCode,
      );
    }

    final loginResponse = FormLoginResponse.fromJson(bodyMap);

    await AuthSession.instance.saveJwtSession(
      tokens: loginResponse.tokens,
      uid: loginResponse.user.uid,
    );

    return loginResponse;
  }

  Future<GoogleLoginResponse> loginByGoogleToken(
    GoogleLoginRequest request,
  ) async {
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
    );

    return googleLoginResponse;
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
