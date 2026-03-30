import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edu_app_flutter/constants/api_config.dart';
import 'package:edu_app_flutter/constants/api_endpoints.dart';
import 'package:edu_app_flutter/models/app_loading_model.dart';
import 'package:edu_app_flutter/models/classroom_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:http/http.dart' as http;

class ClassroomService {
  ClassroomService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<SaveClassroomResponse> saveClassroom(SaveClassroomRequest request) async {
    return AppLoadingModel.instance.track(() async {
      final uid = (AuthSession.instance.uid ?? '').trim();
      if (uid.isEmpty) {
        throw const ApiException(
          message: 'Phien dang nhap khong hop le. Vui long dang nhap lai.',
        );
      }

      final uri = Uri.parse(ApiConfig.endpoint(ApiEndpoints.classroomSaveClassroom));

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
            .timeout(const Duration(seconds: 15));
      } on SocketException {
        throw ApiException(
          message:
              'Khong the ket noi toi server ($uri). Hay kiem tra backend va mang.',
        );
      } on TimeoutException {
        throw const ApiException(
          message: 'Ket noi server bi timeout. Vui long thu lai.',
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

      return SaveClassroomResponse.fromJson(bodyMap);
    });
  }

  Future<List<ClassroomItem>> getClassrooms() async {
    return AppLoadingModel.instance.track(() async {
      final uid = (AuthSession.instance.uid ?? '').trim();
      if (uid.isEmpty) {
        throw const ApiException(
          message: 'Phien dang nhap khong hop le. Vui long dang nhap lai.',
        );
      }

      final base = Uri.parse(ApiConfig.endpoint(ApiEndpoints.classroomGetClassrooms));
      final uri = base.replace(
        queryParameters: {
          ...base.queryParameters,
          'teacher_id': uid,
        },
      );

      late final http.Response response;
      try {
        response = await _client.get(uri).timeout(const Duration(seconds: 15));
      } on SocketException {
        throw ApiException(
          message:
              'Khong the ket noi toi server ($uri). Hay kiem tra backend va mang.',
        );
      } on TimeoutException {
        throw const ApiException(
          message: 'Ket noi server bi timeout. Vui long thu lai.',
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: 'Loi ket noi: ${e.message}');
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
            .map(ClassroomItem.fromJson)
            .toList();
      }

      if (decoded is Map<String, dynamic>) {
        final candidate = decoded['classrooms'];
        if (candidate is List) {
          return candidate
              .whereType<Map<String, dynamic>>()
              .map(ClassroomItem.fromJson)
              .toList();
        }
        return const <ClassroomItem>[];
      }

      throw const ApiException(message: 'Invalid response format from server');
    });
  }

  Future<List<StudentInClassItem>> getStudentsByClass({required String classId}) async {
    return AppLoadingModel.instance.track(() async {
      final trimmedClassId = classId.trim();
      if (trimmedClassId.isEmpty) {
        return const <StudentInClassItem>[];
      }

      final base = Uri.parse(
        ApiConfig.endpoint(ApiEndpoints.classroomGetStudentsByClass),
      );
      final uri = base.replace(
        queryParameters: {
          ...base.queryParameters,
          'class_id': trimmedClassId,
        },
      );

      late final http.Response response;
      try {
        response = await _client.get(uri).timeout(const Duration(seconds: 15));
      } on SocketException {
        throw ApiException(
          message:
              'Khong the ket noi toi server ($uri). Hay kiem tra backend va mang.',
        );
      } on TimeoutException {
        throw const ApiException(
          message: 'Ket noi server bi timeout. Vui long thu lai.',
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: 'Loi ket noi: ${e.message}');
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
            .map(StudentInClassItem.fromJson)
            .toList();
      }

      if (decoded is Map<String, dynamic>) {
        final candidate = decoded['students'];
        if (candidate is List) {
          return candidate
              .whereType<Map<String, dynamic>>()
              .map(StudentInClassItem.fromJson)
              .toList();
        }
        return const <StudentInClassItem>[];
      }

      throw const ApiException(message: 'Invalid response format from server');
    });
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

    return 'Luu lop that bai';
  }
}
