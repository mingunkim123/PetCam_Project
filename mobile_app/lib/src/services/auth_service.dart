import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 인증 관련 서비스 (로그인, 회원가입, 토큰 관리)
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 안전한 저장소 (암호화됨)
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';
  static const String _usernameKey = 'username';

  // 타임아웃 설정 (5초)
  static const Duration _timeout = Duration(seconds: 5);

  // 서버 URL
  static String get baseUrl =>
      dotenv.env['API_URL'] ?? "http://172.24.112.37:8000";

  // 현재 저장된 토큰
  String? _cachedToken;

  /// 저장된 토큰 가져오기
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  /// 토큰 저장
  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  /// 토큰 삭제 (로그아웃)
  Future<void> clearToken() async {
    _cachedToken = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
  }

  /// 로그아웃
  Future<void> logout() async {
    await clearToken();
    debugPrint("✅ 로그아웃 완료");
  }

  /// 로그인 여부 확인
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// 로그인 (토큰 발급) - 5초 타임아웃
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/token"),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;
        await saveToken(token);
        await _storage.write(key: _usernameKey, value: username);
        debugPrint("✅ 로그인 성공! 토큰 저장됨.");
        return true;
      } else {
        debugPrint("❌ 로그인 실패: ${response.statusCode} - ${response.body}");
        return false;
      }
    } on TimeoutException {
      debugPrint("❌ 로그인 타임아웃: 서버 응답 없음");
      return false;
    } catch (e) {
      debugPrint("❌ 로그인 에러: $e");
      return false;
    }
  }

  /// 회원가입 - 5초 타임아웃
  Future<Map<String, dynamic>> register(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        debugPrint("✅ 회원가입 성공!");
        return {'success': true, 'message': '회원가입 성공!'};
      } else {
        final error = jsonDecode(response.body)['detail'] ?? '알 수 없는 오류';
        debugPrint("❌ 회원가입 실패: $error");
        return {'success': false, 'message': error};
      }
    } on TimeoutException {
      debugPrint("❌ 회원가입 타임아웃: 서버 응답 없음");
      return {'success': false, 'message': '서버 응답 시간 초과'};
    } catch (e) {
      debugPrint("❌ 회원가입 에러: $e");
      return {'success': false, 'message': '서버 연결 실패'};
    }
  }

  /// 저장된 사용자명 가져오기
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  /// Authorization 헤더 생성 (API 호출 시 사용)
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }
}
