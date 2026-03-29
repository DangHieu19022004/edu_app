import 'package:edu_app_flutter/models/form_login_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_service.dart';
import 'package:flutter/foundation.dart';

enum LoginStatus {
  idle,
  loading,
  success,
  error,
}

class LoginController extends ChangeNotifier {
  LoginController({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  LoginStatus _status = LoginStatus.idle;
  String? _errorMessage;
  FormLoginResponse? _response;

  LoginStatus get status => _status;
  bool get isLoading => _status == LoginStatus.loading;
  String? get errorMessage => _errorMessage;
  FormLoginResponse? get response => _response;

  Future<FormLoginResponse?> login({
    required String emailOrPhone,
    required String password,
  }) async {
    _status = LoginStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = FormLoginRequest(
        emailOrPhone: emailOrPhone.trim(),
        password: password,
      );

      final loginResponse = await _authService.loginByForm(request);

      _response = loginResponse;
      _status = LoginStatus.success;
      notifyListeners();
      return loginResponse;
    } on ApiException catch (e) {
      _status = LoginStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _status = LoginStatus.error;
      _errorMessage = 'Unexpected error. Please try again.';
      notifyListeners();
      return null;
    }
  }

  void resetState() {
    _status = LoginStatus.idle;
    _errorMessage = null;
    _response = null;
    notifyListeners();
  }
}
