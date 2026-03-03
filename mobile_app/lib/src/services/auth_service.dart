// =============================================================================
// PetCam 인증 서비스
// =============================================================================
//
// 이 파일이 하는 일:
//   1. 로그인/회원가입 처리
//   2. JWT 토큰 관리 (Access Token + Refresh Token)
//   3. 토큰 자동 갱신
//   4. 카카오 소셜 로그인
//
// 토큰 설명:
//   - Access Token: API 요청에 사용, 30분 후 만료
//   - Refresh Token: Access Token 갱신에 사용, 7일 후 만료
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 인증 관련 서비스 (로그인, 회원가입, 토큰 관리)
class AuthService {
  // =========================================================================
  // 싱글톤 패턴 (앱 전체에서 하나의 인스턴스만 사용)
  // =========================================================================
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // =========================================================================
  // 저장소 키 상수
  // =========================================================================
  // FlutterSecureStorage: 암호화된 안전한 저장소 (키체인/키스토어 사용)
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _accessTokenKey = 'access_token';     // Access Token 저장 키
  static const String _refreshTokenKey = 'refresh_token';   // Refresh Token 저장 키
  static const String _usernameKey = 'username';            // 사용자명 저장 키
  static const String _tokenExpiryKey = 'token_expiry';     // 토큰 만료 시간 저장 키

  // 하위 호환성을 위한 기존 키 (마이그레이션용)
  static const String _legacyTokenKey = 'jwt_token';

  // =========================================================================
  // 설정
  // =========================================================================
  // 타임아웃 설정 (서버 응답 대기 시간)
  static const Duration _timeout = Duration(seconds: 10);

  // 서버 URL (.env 파일에서 읽어옴)
  static String get baseUrl =>
      dotenv.env['API_URL'] ?? "http://172.24.112.37:8000";

  // =========================================================================
  // 캐시 (빠른 접근을 위해 메모리에 저장)
  // =========================================================================
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  DateTime? _cachedTokenExpiry;

  // =========================================================================
  // Access Token 관리
  // =========================================================================

  /// Access Token 가져오기 (캐시 우선)
  Future<String?> getToken() async {
    // 1. 캐시에 있으면 바로 반환
    if (_cachedAccessToken != null) {
      return _cachedAccessToken;
    }
    
    // 2. 저장소에서 읽기
    _cachedAccessToken = await _storage.read(key: _accessTokenKey);
    
    // 3. 기존 키에서 마이그레이션 (하위 호환성)
    if (_cachedAccessToken == null) {
      _cachedAccessToken = await _storage.read(key: _legacyTokenKey);
      if (_cachedAccessToken != null) {
        // 새 키로 저장
        await _storage.write(key: _accessTokenKey, value: _cachedAccessToken);
        await _storage.delete(key: _legacyTokenKey);
      }
    }
    
    return _cachedAccessToken;
  }

  /// Refresh Token 가져오기
  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) {
      return _cachedRefreshToken;
    }
    _cachedRefreshToken = await _storage.read(key: _refreshTokenKey);
    return _cachedRefreshToken;
  }

  /// 토큰 저장 (Access Token + Refresh Token)
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresIn, // 만료 시간 (초)
  }) async {
    // 캐시 업데이트
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    
    // 만료 시간 계산 (현재 시간 + expiresIn)
    if (expiresIn != null) {
      _cachedTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
      await _storage.write(
        key: _tokenExpiryKey, 
        value: _cachedTokenExpiry!.toIso8601String()
      );
    }
    
    // 저장소에 저장
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    
    debugPrint("✅ 토큰 저장 완료");
  }

  /// 모든 토큰 삭제 (로그아웃)
  Future<void> clearTokens() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedTokenExpiry = null;
    
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _tokenExpiryKey);
    await _storage.delete(key: _legacyTokenKey);  // 기존 키도 삭제
  }

  // =========================================================================
  // 토큰 만료 확인 및 자동 갱신
  // =========================================================================

  /// Access Token이 만료되었거나 곧 만료되는지 확인
  Future<bool> isTokenExpired() async {
    // 만료 시간 가져오기
    if (_cachedTokenExpiry == null) {
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr != null) {
        _cachedTokenExpiry = DateTime.parse(expiryStr);
      } else {
        return true;  // 만료 시간 정보 없으면 만료된 것으로 간주
      }
    }
    
    // 5분 전에 미리 갱신 (여유 시간)
    final expiryWithBuffer = _cachedTokenExpiry!.subtract(const Duration(minutes: 5));
    return DateTime.now().isAfter(expiryWithBuffer);
  }

  /// Access Token 갱신 (Refresh Token 사용)
  Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    
    if (refreshToken == null) {
      debugPrint("❌ Refresh Token 없음 - 재로그인 필요");
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/token/refresh"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'] as String;
        
        // 새 Access Token 저장 (Refresh Token은 그대로)
        _cachedAccessToken = newAccessToken;
        await _storage.write(key: _accessTokenKey, value: newAccessToken);
        
        // 만료 시간 업데이트 (30분 후)
        _cachedTokenExpiry = DateTime.now().add(const Duration(minutes: 30));
        await _storage.write(
          key: _tokenExpiryKey, 
          value: _cachedTokenExpiry!.toIso8601String()
        );
        
        debugPrint("✅ Access Token 갱신 성공");
        return true;
      } else {
        debugPrint("❌ Token 갱신 실패: ${response.statusCode}");
        return false;
      }
    } on TimeoutException {
      debugPrint("❌ Token 갱신 타임아웃");
      return false;
    } catch (e) {
      debugPrint("❌ Token 갱신 에러: $e");
      return false;
    }
  }

  /// 유효한 Access Token 가져오기 (필요시 자동 갱신)
  Future<String?> getValidToken() async {
    // 1. 현재 토큰 가져오기
    final token = await getToken();
    if (token == null) return null;
    
    // 2. 만료 확인
    final expired = await isTokenExpired();
    if (!expired) {
      return token;  // 아직 유효함
    }
    
    // 3. 갱신 시도
    final refreshed = await refreshAccessToken();
    if (refreshed) {
      return _cachedAccessToken;  // 갱신된 토큰 반환
    }
    
    // 4. 갱신 실패 - 재로그인 필요
    return null;
  }

  // =========================================================================
  // 로그인/로그아웃
  // =========================================================================

  /// 로그인 여부 확인
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// 로그인 (토큰 발급)
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/token"),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Access Token + Refresh Token 저장
        await saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
          expiresIn: data['expires_in'] as int?,
        );
        
        // 사용자명 저장
        await _storage.write(key: _usernameKey, value: username);
        
        debugPrint("✅ 로그인 성공!");
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

  /// 로그아웃 (서버에 Refresh Token 무효화 요청)
  Future<void> logout() async {
    try {
      final refreshToken = await getRefreshToken();
      
      if (refreshToken != null) {
        // 서버에 로그아웃 요청 (Refresh Token 무효화)
        await http.post(
          Uri.parse("$baseUrl/logout"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        ).timeout(_timeout);
      }
    } catch (e) {
      // 로그아웃 요청 실패해도 로컬 토큰은 삭제
      debugPrint("⚠️ 서버 로그아웃 요청 실패 (무시): $e");
    }
    
    // 로컬 토큰 삭제
    await clearTokens();
    debugPrint("✅ 로그아웃 완료");
  }

  // =========================================================================
  // 회원가입
  // =========================================================================

  /// 회원가입
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

  // =========================================================================
  // 카카오 소셜 로그인
  // =========================================================================

  /// 카카오 로그인 (카카오 토큰으로 우리 서버 토큰 발급)
  Future<bool> loginWithKakao(String kakaoAccessToken) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/oauth/kakao"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'kakao_access_token': kakaoAccessToken}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Access Token + Refresh Token 저장
        await saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
          expiresIn: data['expires_in'] as int?,
        );
        
        debugPrint("✅ 카카오 로그인 성공!");
        return true;
      } else {
        debugPrint("❌ 카카오 로그인 실패: ${response.statusCode}");
        return false;
      }
    } on TimeoutException {
      debugPrint("❌ 카카오 로그인 타임아웃");
      return false;
    } catch (e) {
      debugPrint("❌ 카카오 로그인 에러: $e");
      return false;
    }
  }

  // =========================================================================
  // 유틸리티
  // =========================================================================

  /// 저장된 사용자명 가져오기
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  /// Authorization 헤더 생성 (API 호출 시 사용)
  Future<Map<String, String>> getAuthHeaders() async {
    // 유효한 토큰 가져오기 (필요시 자동 갱신)
    final token = await getValidToken();
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  // =========================================================================
  // 하위 호환성 (기존 코드와 호환)
  // =========================================================================

  /// 토큰 저장 (기존 메서드 - 하위 호환성)
  @Deprecated('Use saveTokens() instead')
  Future<void> saveToken(String token) async {
    _cachedAccessToken = token;
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// 토큰 삭제 (기존 메서드 - 하위 호환성)
  @Deprecated('Use clearTokens() instead')
  Future<void> clearToken() async {
    await clearTokens();
  }
}
