import 'package:flutter/foundation.dart';

class AppLoadingModel extends ChangeNotifier {
  AppLoadingModel._();

  static final AppLoadingModel instance = AppLoadingModel._();

  int _activeRequests = 0;

  bool get isLoading => _activeRequests > 0;

  void begin() {
    _activeRequests += 1;
    if (_activeRequests == 1) {
      notifyListeners();
    }
  }

  void end() {
    if (_activeRequests <= 0) {
      _activeRequests = 0;
      return;
    }

    _activeRequests -= 1;
    if (_activeRequests == 0) {
      notifyListeners();
    }
  }

  Future<T> track<T>(Future<T> Function() action) async {
    begin();
    try {
      return await action();
    } finally {
      end();
    }
  }
}
