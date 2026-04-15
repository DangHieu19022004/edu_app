import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/models/form_register_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_service.dart';
import 'package:flutter/foundation.dart';

enum RegisterStatus {
  idle,
  loading,
  success,
  error,
}

class RegisterController extends ChangeNotifier {
  RegisterController({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  RegisterStatus _status = RegisterStatus.idle;
  String? _errorMessage;
  FormRegisterResponse? _response;

  RegisterStatus get status => _status;
  bool get isLoading => _status == RegisterStatus.loading;
  String? get errorMessage => _errorMessage;
  FormRegisterResponse? get response => _response;

  Future<FormRegisterResponse?> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _status = RegisterStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = FormRegisterRequest(
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
      );

      final registerResponse = await _authService.registerByForm(request);

      _response = registerResponse;
      _status = RegisterStatus.success;
      notifyListeners();
      return registerResponse;
    } on ApiException catch (e) {
      _status = RegisterStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _status = RegisterStatus.error;
      _errorMessage = AppTexts.loginError;
      notifyListeners();
      return null;
    }
  }

  void resetState() {
    _status = RegisterStatus.idle;
    _errorMessage = null;
    _response = null;
    notifyListeners();
  }
}
