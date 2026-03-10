import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple role-based provider — no login needed.
/// The user picks "kitchen" or "salesperson" on the onboard screen.
class RoleProvider extends ChangeNotifier {
  String? _role; // 'salesperson' or 'kitchen'
  bool _isLoading = true;

  String? get role => _role;
  bool get isLoading => _isLoading;
  bool get hasRole => _role != null;
  bool get isSalesperson => _role == 'salesperson';
  bool get isKitchen => _role == 'kitchen';

  static const String _roleStorageKey = 'order_app_role';

  RoleProvider() {
    _loadSavedRole();
  }

  Future<void> _loadSavedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _role = prefs.getString(_roleStorageKey);
    } catch (e) {
      debugPrint('Error loading saved role: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectRole(String role) async {
    _role = role;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roleStorageKey, role);
    } catch (e) {
      debugPrint('Error saving role: $e');
    }
  }

  Future<void> clearRole() async {
    _role = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_roleStorageKey);
    } catch (e) {
      debugPrint('Error clearing role: $e');
    }
  }
}
