import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AiService {
  // 💡 사장님 PC의 현재 IP로 수정 필수!
  static const String baseUrl = "http://172.24.112.37:8000";

  // 1장 업스케일링
  Future<Uint8List?> upscaleImage(Uint8List imageBytes) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/upscale"),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'capture.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      var response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {
      print("❌ AI 업스케일링 에러: $e");
      if (e.toString().contains("Connection refused")) {
        print("💡 서버가 켜져 있는지 확인해주세요.");
      }
    }
    return null;
  }

  // 3장 중 베스트 컷 선별 + 업스케일링
  Future<Uint8List?> getBestCut(List<Uint8List> images) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/bestcut"),
      );
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
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {
      print("❌ 베스트 컷 통신 에러: $e");
      if (e.toString().contains("Connection refused")) {
        print("💡 서버가 켜져 있는지 확인해주세요.");
      }
    }
    return null;
  }

  // 사진 목록 가져오기
  Future<List<dynamic>> fetchPhotos() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/photos"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
      final response = await http.delete(Uri.parse("$baseUrl/photos/$photoId"));
      return response.statusCode == 200;
    } catch (e) {
      print("❌ 삭제 실패: $e");
      return false;
    }
  }

  // 사진 다운로드 (URL -> Bytes)
  Future<Uint8List?> downloadPhoto(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print("❌ 다운로드 실패: $e");
      return null;
    }
  }
}
