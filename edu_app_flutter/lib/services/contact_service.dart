import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edu_app_flutter/constants/api_config.dart';
import 'package:edu_app_flutter/constants/api_endpoints.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/models/app_loading_model.dart';
import 'package:edu_app_flutter/models/contact_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:http/http.dart' as http;

class ContactService {
  ContactService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 20);

  Map<String, String> _requireUidAuthHeaders({
    Map<String, String>? additionalHeaders,
  }) {
    final uid = (AuthSession.instance.uid ?? '').trim();
    if (uid.isEmpty) {
      throw const ApiException(
        message: AppTexts.ErrorAuth,
      );
    }

    return {
      'Authorization': 'Bearer $uid',
      ...?additionalHeaders,
    };
  }

  Future<ContactActionResponse> saveParent({
    required SaveParentRequest request,
  }) async {
    return AppLoadingModel.instance.track(() async {
      final uri = Uri.parse(ApiConfig.endpoint(ApiEndpoints.contactSaveParent));
      final bodyMap = await _postJson(uri: uri, body: request.toJson());
      return ContactActionResponse.fromJson(bodyMap);
    });
  }

  Future<ContactActionResponse> scheduleEmail({
    required ScheduleEmailRequest request,
  }) async {
    return AppLoadingModel.instance.track(() async {
      final uri = Uri.parse(ApiConfig.endpoint(ApiEndpoints.contactScheduleEmail));
      final bodyMap = await _postJson(uri: uri, body: request.toJson());
      return ContactActionResponse.fromJson(bodyMap);
    });
  }

  Future<ContactActionResponse> sendEmailNow({
    required SendEmailNowRequest request,
  }) async {
    return AppLoadingModel.instance.track(() async {
      final uri = Uri.parse(ApiConfig.endpoint(ApiEndpoints.contactSendEmailNow));
      final bodyMap = await _postJson(uri: uri, body: request.toJson());
      return ContactActionResponse.fromJson(bodyMap);
    });
  }

  Future<List<ParentItem>> getParents() async {
    return AppLoadingModel.instance.track(() async {
      final teacherId = (AuthSession.instance.uid ?? '').trim();
      if (teacherId.isEmpty) {
        throw const ApiException(
          message: AppTexts.ErrorAuth,
        );
      }

      final base = Uri.parse(ApiConfig.endpoint(ApiEndpoints.contactGetParents));
      final uri = base.replace(
        queryParameters: {
          ...base.queryParameters,
          'teacher_id': teacherId,
        },
      );

      late final http.Response response;
      try {
        response = await _client
            .get(
              uri,
              headers: _requireUidAuthHeaders(),
            )
            .timeout(_timeout);
      } on SocketException {
        throw ApiException(
          message:
              AppTexts.ErrorAuth,
        );
      } on TimeoutException {
        throw const ApiException(
          message: AppTexts.ErrorAuth,
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: AppTexts.ErrorAuth);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final bodyMap = _decodeJsonMap(response.body);
        throw ApiException(
          message: _extractErrorMessage(bodyMap),
          statusCode: response.statusCode,
        );
      }

      final decoded = response.body.trim().isEmpty ? const [] : jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(ParentItem.fromJson)
            .toList();
      }

      if (decoded is Map<String, dynamic>) {
        final candidate = decoded['parents'] ?? decoded['results'];
        if (candidate is List) {
          return candidate
              .whereType<Map<String, dynamic>>()
              .map(ParentItem.fromJson)
              .toList();
        }
      }

      return const <ParentItem>[];
    });
  }

  Future<List<ScheduledEmailItem>> getScheduledEmails() async {
    return AppLoadingModel.instance.track(() async {
      final teacherId = (AuthSession.instance.uid ?? '').trim();
      if (teacherId.isEmpty) {
        throw const ApiException(
          message: AppTexts.ErrorAuth
        );
      }

      final base = Uri.parse(ApiConfig.endpoint(ApiEndpoints.contactGetScheduledEmails));
      final uri = base.replace(
        queryParameters: {
          ...base.queryParameters,
          'teacher_id': teacherId,
        },
      );

      late final http.Response response;
      try {
        response = await _client
            .get(
              uri,
              headers: _requireUidAuthHeaders(),
            )
            .timeout(_timeout);
      } on SocketException {
        throw ApiException(
          message:AppTexts.ErrorAuth
        );
      } on TimeoutException {
        throw const ApiException(
          message: AppTexts.ErrorAuth,
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: AppTexts.ErrorAuth);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final bodyMap = _decodeJsonMap(response.body);
        throw ApiException(
          message: _extractErrorMessage(bodyMap),
          statusCode: response.statusCode,
        );
      }

      final decoded = response.body.trim().isEmpty ? const [] : jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(ScheduledEmailItem.fromJson)
            .toList();
      }

      if (decoded is Map<String, dynamic>) {
        final candidate = decoded['emails'] ?? decoded['results'];
        if (candidate is List) {
          return candidate
              .whereType<Map<String, dynamic>>()
              .map(ScheduledEmailItem.fromJson)
              .toList();
        }
      }

      return const <ScheduledEmailItem>[];
    });
  }

  Future<ContactActionResponse> deleteEmailSchedule({
    required String id,
  }) async {
    return AppLoadingModel.instance.track(() async {
      final emailId = id.trim();
      if (emailId.isEmpty) {
        throw const ApiException(message: AppTexts.emailIdUnknown);
      }

      final uri = Uri.parse(
        ApiConfig.endpoint(ApiEndpoints.contactDeleteEmailSchedule),
      );
      final bodyMap = await _postJson(
        uri: uri,
        body: {
          'id': emailId,
        },
      );
      return ContactActionResponse.fromJson(bodyMap);
    });
  }

  Future<Map<String, dynamic>> _postJson({
    required Uri uri,
    required Map<String, dynamic> body,
  }) async {
    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: _requireUidAuthHeaders(
              additionalHeaders: const {
                'Content-Type': 'application/json',
              },
            ),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on SocketException {
      throw ApiException(
        message: AppTexts.ErrorAuth,
      );
    } on TimeoutException {
      throw const ApiException(message: AppTexts.ErrorAuth);
    } on http.ClientException catch (e) {
      throw ApiException(message: AppTexts.ErrorAuth);
    }

    final bodyMap = _decodeJsonMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: _extractErrorMessage(bodyMap),
        statusCode: response.statusCode,
      );
    }

    return bodyMap;
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

    return AppTexts.ErrorAuth;
  }
}
