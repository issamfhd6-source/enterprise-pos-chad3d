import 'package:flutter/foundation.dart';

enum UserRole { manager, branchManager, cashier }

class ExchangeRateController extends ChangeNotifier {
  double _usdToNewSyp = 135.0;
  final double oldToNewSypRatio = 100.0;
  UserRole _role = UserRole.manager;
  bool _dark = true;

  double get usdToNewSyp => _usdToNewSyp;
  UserRole get role => _role;
  bool get isDark => _dark;
  bool get canEditRate => _role == UserRole.manager;

  double toNewSyp(double usd) => usd * _usdToNewSyp;
  double toOldSyp(double usd) => toNewSyp(usd) * oldToNewSypRatio;

  void setRole(UserRole r) {
    if (_role == r) return;
    _role = r;
    notifyListeners();
  }

  void toggleDark() {
    _dark = !_dark;
    notifyListeners();
  }

  bool updateRate(double val) {
    if (!canEditRate || val.isNaN || val.isInfinite || val <= 0) return false;
    _usdToNewSyp = val;
    notifyListeners();
    return true;
  }
}
