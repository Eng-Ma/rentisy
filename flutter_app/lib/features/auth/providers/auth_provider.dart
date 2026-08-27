import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _user;
  ThemeMode _themeMode = ThemeMode.light;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => ApiService.isAuthenticated;
  ThemeMode get themeMode => _themeMode;
  String get baseUrl => ApiEndpoints.baseUrl;

  AuthProvider() {
    _loadThemeMode();
    checkAuth();
  }

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    await ApiService.init();
    if (isAuthenticated) {
      await fetchCurrentUser();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode');
    if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      await prefs.setString('theme_mode', 'light');
    } else if (mode == ThemeMode.dark) {
      await prefs.setString('theme_mode', 'dark');
    } else {
      await prefs.setString('theme_mode', 'system');
    }
    notifyListeners();
  }

  Future<void> updateBaseUrl(String url) async {
    await ApiService.setBaseUrl(url);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(
      ApiEndpoints.login,
      body: {'email': email.trim(), 'password': password},
    );

    _isLoading = false;

    if (response.success && response.rawJson is Map) {
      final token = response.rawJson['token'];
      _user = response.rawJson['user'];
      await ApiService.setToken(token);
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل تسجيل الدخول';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(
      ApiEndpoints.register,
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      },
    );

    _isLoading = false;

    if (response.success && response.rawJson is Map) {
      final token = response.rawJson['token'];
      _user = response.rawJson['user'];
      await ApiService.setToken(token);
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'فشل إنشاء الحساب';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchCurrentUser() async {
    if (!isAuthenticated) return;
    final response = await ApiService.get(ApiEndpoints.user);
    if (response.success && response.rawJson is Map && response.rawJson['user'] != null) {
      _user = response.rawJson['user'];
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await ApiService.post(ApiEndpoints.logout);
    await ApiService.setToken(null);
    _user = null;
    _isLoading = false;
    notifyListeners();
  }
}
