import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class AiService {
  final AuthService _authService = AuthService();

  // 환경 변수에서 API URL 로드 (없으면 기본값 사용 - 개발 편의성)
  static String get baseUrl =>
      dotenv.env['API_URL'] ?? "http://172.24.112.37:8000";

  /// 인증 헤더 포함한 HTTP 헤더 생성
  Future<Map<String, String>> _getHeaders() async {
    return await _authService.getAuthHeaders();
  }

  Future<Uint8List?> upscaleImage(Uint8List imageBytes) async {
    try {
      // 인증 헤더 추가
      final headers = await _getHeaders();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/upscale"),
      );
      request.headers.addAll(headers);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'capture.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // 1. 업로드 요청
      var response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        // 2. JSON 파싱 (ID 추출)
        var jsonResponse = jsonDecode(response.body);
        String photoId = jsonResponse['id'];
        debugPrint("✅ 업로드 성공! ID: $photoId");

        // 3. 이미지 다운로드 (바로 요청하면 원본이 오고, 나중에 변환됨)
        return await downloadPhoto(getPhotoUrl(photoId));
      } else {
        debugPrint("❌ 서버 응답 오류: ${response.statusCode}");
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ AI 업스케일링 에러: $e");
      if (e.toString().contains("Connection refused")) {
        debugPrint("💡 서버가 켜져 있는지 확인해주세요.");
        throw Exception("Connection refused. Please check the server.");
      }
      rethrow; // UI에서 처리할 수 있도록 에러 전파
    }
  }

  // 3장 중 베스트 컷 선별 + 업스케일링
  Future<Uint8List?> getBestCut(List<Uint8List> images) async {
    try {
      // 인증 헤더 추가
      final headers = await _getHeaders();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/bestcut"),
      );
      request.headers.addAll(headers);
      for (int i = 0; i < images.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            images[i],
            filename: 'burst_$i.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
      var response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        // JSON 파싱
        var jsonResponse = jsonDecode(response.body);
        String photoId = jsonResponse['id'];
        print("✅ 베스트컷 업로드 성공! ID: $photoId");

        // 이미지 다운로드
        return await downloadPhoto(getPhotoUrl(photoId));
      }
    } catch (e) {
      print("❌ 베스트 컷 통신 에러: $e");
      if (e.toString().contains("Connection refused")) {
        print("💡 서버가 켜져 있는지 확인해주세요.");
      }
    }
    return null;
  }

  // 사진 목록 가져오기 (Pagination)
  Future<List<dynamic>> fetchPhotos({int skip = 0, int limit = 100}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/photos?skip=$skip&limit=$limit"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        debugPrint("❌ 인증 실패: 로그인이 필요합니다.");
      }
    } catch (e) {
      print("❌ 사진 목록 로드 실패: $e");
    }
    return [];
  }

  // 사진 URL 생성 헬퍼
  String getPhotoUrl(String photoId) {
    return "$baseUrl/photos/$photoId?type=upscaled";
  }

  // 사진 삭제
  Future<bool> deletePhoto(String photoId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse("$baseUrl/photos/$photoId"),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ 삭제 실패: $e");
      return false;
    }
  }

  // 사진 다운로드 (URL -> Bytes)
  Future<Uint8List?> downloadPhoto(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (response.statusCode == 401) {
        debugPrint("❌ 인증 실패: 로그인이 필요합니다.");
      }
      return null;
    } catch (e) {
      print("❌ 다운로드 실패: $e");
      return null;
    }
  }
}
