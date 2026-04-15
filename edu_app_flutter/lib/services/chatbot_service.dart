import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edu_app_flutter/constants/api_config.dart';
import 'package:edu_app_flutter/constants/api_endpoints.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/models/chatbot_models.dart';
import 'package:edu_app_flutter/models/ocr_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:http/http.dart' as http;

class ChatbotService {
  ChatbotService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _askTimeout = Duration(seconds: 60);

  Future<ChatbotAskResponse> askChatbot({
    required String question,
    List<OcrAllStudentDataItem> students = const <OcrAllStudentDataItem>[],
    String? conversationId,
  }) async {
    final uid = (AuthSession.instance.uid ?? '').trim();
    if (uid.isEmpty) {
      throw const ApiException(
        message: AppTexts.loginError,
      );
    }

    final normalizedQuestion = question.trim();
    if (normalizedQuestion.isEmpty) {
      throw const ApiException(message: AppTexts.chatbotInputHint);
    }

    final request = ChatbotAskRequest(
      question: normalizedQuestion,
      students: students.map(ChatbotStudentPayload.fromOcrItem).toList(),
      conversationId: conversationId,
    );

    final uri = Uri.parse(ApiConfig.endpoint(ApiEndpoints.chatbotAskChatbot));

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $uid',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(_askTimeout);
    } on SocketException {
      throw ApiException(
        message:
            AppTexts.ErrorAuth,
      );
    } on TimeoutException {
      throw const ApiException(
        message: AppTexts.chatbotTimeout,
      );
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

    return ChatbotAskResponse.fromJson(bodyMap);
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

    return AppTexts.ErrorAuth;
  }
}
