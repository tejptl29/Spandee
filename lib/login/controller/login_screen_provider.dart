import 'package:flutter/material.dart';

class LoginScreenProvider with ChangeNotifier {
  bool _isPasswordHidden = true;

  bool get isPasswordHidden => _isPasswordHidden;

  void togglePasswordVisibility() {
    _isPasswordHidden = !_isPasswordHidden;
    notifyListeners();
  }
}
