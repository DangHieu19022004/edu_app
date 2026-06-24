import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edu_app_flutter/constants/api_config.dart';
import 'package:edu_app_flutter/constants/api_endpoints.dart';
import 'package:edu_app_flutter/models/app_loading_model.dart';
import 'package:edu_app_flutter/models/ocr_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:http/http.dart' as http;

class OcrService {
  OcrService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _detectTimeout = Duration(seconds: 360);
  static const Duration _saveTimeout = Duration(seconds: 30);

  Future<List<OcrDetectResult>> detectReportCard({
    required List<OcrDetectImageInput> images,
  }) async {
    return AppLoadingModel.instance.track(() async {
      if (images.isEmpty) {
        return const <OcrDetectResult>[];
      }

      final uri = Uri.parse(ApiConfig.endpoint(ApiEndpoints.ocrDetect));
      final List<OcrDetectResult> allResults = <OcrDetectResult>[];

      for (final input in images) {
        final file = File(input.path);
        if (!file.existsSync()) {
          continue;
        }

        final request = http.MultipartRequest('POST', uri)
          ..files.add(await http.MultipartFile.fromPath('image', input.path));

        final imageType = input.imageType;
        if (imageType != null && imageType.isNotEmpty) {
          request.fields['image_type'] = imageType;
        }

        late final http.StreamedResponse streamed;
        try {
          streamed = await _client.send(request).timeout(_detectTimeout);
          final response = await http.Response.fromStream(
            streamed,
          ).timeout(_detectTimeout);

          Map<String, dynamic> bodyMap;
          try {
            bodyMap = _decodeJsonMap(response.body);
          } on ApiException {
            bodyMap = <String, dynamic>{};
          }

          if (response.statusCode < 200 || response.statusCode >= 300) {
            throw ApiException(
              message: _extractErrorMessage(bodyMap),
              statusCode: response.statusCode,
            );
          }

          final dynamic rawResults = bodyMap['results'];
          if (rawResults is List) {
            allResults.addAll(
              rawResults
                  .whereType<Map<String, dynamic>>()
                  .map(OcrDetectResult.fromJson)
                  .map((item) => item.copyWith(role: input.role)),
            );
          }
        } on SocketException {
          throw ApiException(
            message:
                'Không thể kết nối tới server ($uri). Hãy kiểm tra lại mạng.',
          );
        } on TimeoutException {
          throw const ApiException(
            message:
                'OCR đang xử lý ảnh lớn nên cần nhiều thời gian. Đã timeout sau 360 giây, vui lòng thử lại với mạng ổn định.',
          );
        } on http.ClientException catch (e) {
          throw ApiException(message: 'Lỗi kết nối: ${e.message}');
        }
      }

      return allResults;
    });
  }

  Future<OcrSaveFullReportCardResponse> saveFullReportCard({
    required OcrSaveFullReportCardRequest request,
  }) async {
    return AppLoadingModel.instance.track(() async {
      final uid = (AuthSession.instance.uid ?? '').trim();
      if (uid.isEmpty) {
        throw const ApiException(
          message: 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
        );
      }

      final uri = Uri.parse(
        ApiConfig.endpoint(ApiEndpoints.ocrSaveFullReportCard),
      );

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
            .timeout(_saveTimeout);
      } on SocketException {
        throw ApiException(
          message:
              'Không thể kết nối tới server ($uri). Hãy kiểm tra lại mạng.',
        );
      } on TimeoutException {
        throw const ApiException(
          message: 'Kết nối server bị timeout. Vui lòng thử lại.',
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: 'Lỗi kết nối: ${e.message}');
      }

      final bodyMap = _decodeJsonMap(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _extractErrorMessage(bodyMap),
          statusCode: response.statusCode,
        );
      }

      return OcrSaveFullReportCardResponse.fromJson(bodyMap);
    });
  }

  Future<OcrFullReportCardResponse> getFullReportCard({
    required String studentId,
  }) async {
    return AppLoadingModel.instance.track(() async {
      final uid = (AuthSession.instance.uid ?? '').trim();
      if (uid.isEmpty) {
        throw const ApiException(
          message: 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
        );
      }

      final trimmedStudentId = studentId.trim();
      if (trimmedStudentId.isEmpty) {
        throw const ApiException(message: 'Không tìm thấy student_id.');
      }

      final base = Uri.parse(
        ApiConfig.endpoint(ApiEndpoints.ocrGetFullReportCard),
      );
      final uri = base.replace(
        queryParameters: {
          ...base.queryParameters,
          'student_id': trimmedStudentId,
        },
      );

      late final http.Response response;
      try {
        response = await _client
            .get(uri, headers: {'Authorization': 'Bearer $uid'})
            .timeout(_saveTimeout);
      } on SocketException {
        throw ApiException(
          message:
              'Không thể kết nối tới server ($uri). Hãy kiểm tra lại mạng.',
        );
      } on TimeoutException {
        throw const ApiException(
          message: 'Kết nối server bị timeout. Vui lòng thử lại.',
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: 'Lỗi kết nối: ${e.message}');
      }

      final bodyMap = _decodeJsonMap(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _extractErrorMessage(bodyMap),
          statusCode: response.statusCode,
        );
      }

      return OcrFullReportCardResponse.fromJson(bodyMap);
    });
  }

  Future<OcrAllStudentDataResponse> getAllStudentData() async {
    return AppLoadingModel.instance.track(() async {
      final uid = (AuthSession.instance.uid ?? '').trim();
      if (uid.isEmpty) {
        throw const ApiException(
          message: 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
        );
      }

      final uri = Uri.parse(
        ApiConfig.endpoint(ApiEndpoints.ocrGetAllStudentData),
      );

      late final http.Response response;
      try {
        response = await _client
            .get(uri, headers: {'Authorization': 'Bearer $uid'})
            .timeout(_saveTimeout);
      } on SocketException {
        throw ApiException(
          message:
              'Không thể kết nối tới server ($uri). Hãy kiểm tra lại mạng.',
        );
      } on TimeoutException {
        throw const ApiException(
          message: 'Kết nối server bị timeout. Vui lòng thử lại.',
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: 'Lỗi kết nối: ${e.message}');
      }

      final bodyMap = _decodeJsonMap(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _extractErrorMessage(bodyMap),
          statusCode: response.statusCode,
        );
      }

      return OcrAllStudentDataResponse.fromJson(bodyMap);
    });
  }

  Future<OcrAllStudentDataResponse> getAllStudentDataSilently() async {
    final uid = (AuthSession.instance.uid ?? '').trim();
    if (uid.isEmpty) {
      throw const ApiException(
        message: 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }

    final uri = Uri.parse(
      ApiConfig.endpoint(ApiEndpoints.ocrGetAllStudentData),
    );

    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'Authorization': 'Bearer $uid'})
          .timeout(_saveTimeout);
    } on SocketException {
      throw ApiException(
        message:
            'Không thể kết nối tới server ($uri). Hãy kiểm tra lại mạng.',
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'Kết nối server bị timeout. Vui lòng thử lại.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Lỗi kết nối: ${e.message}');
    }

    final bodyMap = _decodeJsonMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: _extractErrorMessage(bodyMap),
        statusCode: response.statusCode,
      );
    }

    return OcrAllStudentDataResponse.fromJson(bodyMap);
  }

  Future<OcrUpdateReportCardResponse> updateReportCard({
    required String reportCardId,
    required OcrUpdateReportCardRequest request,
  }) async {
    return AppLoadingModel.instance.track(() async {
      final uid = (AuthSession.instance.uid ?? '').trim();
      if (uid.isEmpty) {
        throw const ApiException(
          message: 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
        );
      }

      final trimmedReportCardId = reportCardId.trim();
      if (trimmedReportCardId.isEmpty) {
        throw const ApiException(
          message: 'Không tìm thấy id học ba cần cập nhật.',
        );
      }

      final base = Uri.parse(
        ApiConfig.endpoint(ApiEndpoints.ocrUpdateReportCard),
      );
      final uri = base.replace(
        queryParameters: {...base.queryParameters, 'id': trimmedReportCardId},
      );

      late final http.Response response;
      try {
        response = await _client
            .put(
              uri,
              headers: {
                'Authorization': 'Bearer $uid',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(request.toJson()),
            )
            .timeout(_saveTimeout);
      } on SocketException {
        throw ApiException(
          message:
              'Không thể kết nối tới server ($uri). Hãy kiểm tra lại mạng.',
        );
      } on TimeoutException {
        throw const ApiException(
          message: 'Kết nối server bị timeout. Vui lòng thử lại.',
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: 'Lỗi kết nối: ${e.message}');
      }

      final bodyMap = _decodeJsonMap(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _extractErrorMessage(bodyMap),
          statusCode: response.statusCode,
        );
      }

      return OcrUpdateReportCardResponse.fromJson(bodyMap);
    });
  }

  Future<String> deleteFullReportCard({required String reportCardId}) async {
    return AppLoadingModel.instance.track(() async {
      final uid = (AuthSession.instance.uid ?? '').trim();
      if (uid.isEmpty) {
        throw const ApiException(
          message: 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
        );
      }

      final trimmedReportCardId = reportCardId.trim();
      if (trimmedReportCardId.isEmpty) {
        throw const ApiException(message: 'Không tìm thấy report_card_id.');
      }

      final base = Uri.parse(
        ApiConfig.endpoint(ApiEndpoints.ocrDeleteFullReportCard),
      );
      final uri = base.replace(
        queryParameters: {...base.queryParameters, 'id': trimmedReportCardId},
      );

      late final http.Response response;
      try {
        response = await _client
            .delete(uri, headers: {'Authorization': 'Bearer $uid'})
            .timeout(_saveTimeout);
      } on SocketException {
        throw ApiException(
          message:
              'Không thể kết nối tới server ($uri). Hãy kiểm tra lại mạng.',
        );
      } on TimeoutException {
        throw const ApiException(
          message: 'Kết nối server bị timeout. Vui lòng thử lại.',
        );
      } on http.ClientException catch (e) {
        throw ApiException(message: 'Lỗi kết nối: ${e.message}');
      }

      final bodyMap = _decodeJsonMap(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _extractErrorMessage(bodyMap),
          statusCode: response.statusCode,
        );
      }

      final message = bodyMap['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      return 'Xóa học ba thành công';
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

    return 'Quét học ba thất bại. Vui lòng thử lại.';
  }
}
