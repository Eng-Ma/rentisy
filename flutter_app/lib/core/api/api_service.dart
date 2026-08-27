import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic rawJson;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.rawJson,
    required this.statusCode,
  });
}

class ApiService {
  static const String _tokenKey = 'auth_token';
  static const String _baseUrlKey = 'custom_base_url';

  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final savedBaseUrl = prefs.getString(_baseUrlKey);
    if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
      ApiEndpoints.baseUrl = savedBaseUrl;
    } else {
      // Auto detect emulator vs desktop/iOS
      if (!kIsWeb && Platform.isAndroid) {
        ApiEndpoints.baseUrl = ApiEndpoints.defaultAndroidEmulatorUrl;
      } else {
        ApiEndpoints.baseUrl = ApiEndpoints.defaultLocalUrl;
      }
    }
  }

  static String? get token => _token;
  static bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  static Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  static Future<void> setBaseUrl(String url) async {
    ApiEndpoints.baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, ApiEndpoints.baseUrl);
  }

  static Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<ApiResponse<dynamic>> get(String url, {Map<String, dynamic>? queryParams}) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        final stringParams = queryParams.map((k, v) => MapEntry(k, v.toString()));
        uri = uri.replace(queryParameters: stringParams);
      }

      final response = await http.get(uri, headers: _getHeaders()).timeout(
        const Duration(seconds: 15),
      );

      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'فشل الاتصال بالخادم: $e',
        statusCode: 0,
      );
    }
  }

  static Future<ApiResponse<dynamic>> post(String url, {dynamic body}) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .post(
            uri,
            headers: _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'فشل الاتصال بالخادم: $e',
        statusCode: 0,
      );
    }
  }

  static Future<ApiResponse<dynamic>> put(String url, {dynamic body}) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .put(
            uri,
            headers: _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'فشل الاتصال بالخادم: $e',
        statusCode: 0,
      );
    }
  }

  static Future<ApiResponse<dynamic>> delete(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .delete(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 15));

      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'فشل الاتصال بالخادم: $e',
        statusCode: 0,
      );
    }
  }

  static ApiResponse<dynamic> _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decoded = null;
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    String? message;

    if (decoded is Map<String, dynamic>) {
      message = decoded['message'] ?? decoded['error'];
    }

    if (!isSuccess && message == null) {
      message = 'حدث خطأ في الخادم (رمز ${response.statusCode})';
    }

    return ApiResponse(
      success: isSuccess,
      message: message,
      data: decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded,
      rawJson: decoded,
      statusCode: response.statusCode,
    );
  }
}
