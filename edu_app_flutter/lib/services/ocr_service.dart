import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edu_app_flutter/constants/api_config.dart';
import 'package:edu_app_flutter/constants/api_endpoints.dart';
import 'package:edu_app_flutter/models/app_loading_model.dart';
import 'package:edu_app_flutter/models/ocr_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:http/http.dart' as http;

class OcrService {
  OcrService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _detectTimeout = Duration(seconds: 360);

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
          final response = await http.Response.fromStream(streamed).timeout(
            _detectTimeout,
          );

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
                'Khong the ket noi toi server ($uri). Hay kiem tra backend va mang.',
          );
        } on TimeoutException {
          throw const ApiException(
            message:
                'OCR dang xu ly anh lon nen can nhieu thoi gian. Da timeout sau 360 giay, vui long thu lai voi mang on dinh.',
          );
        } on http.ClientException catch (e) {
          throw ApiException(message: 'Loi ket noi: ${e.message}');
        }
      }

      return allResults;
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

    return 'Quet hoc ba that bai';
  }
}
