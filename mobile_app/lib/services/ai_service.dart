import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AiService {
  // 💡 사장님 PC의 현재 IP로 수정 필수!
  static const String baseUrl = "http://172.24.112.37:8000";

  // 1장 업스케일링
  Future<Uint8List?> upscaleImage(Uint8List imageBytes) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/upscale"));
      request.files.add(http.MultipartFile.fromBytes(
        'file', imageBytes,
        filename: 'capture.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
      var response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {
      print("❌ AI 업스케일링 에러: $e");
    }
    return null;
  }

  // 3장 중 베스트 컷 선별 + 업스케일링
  Future<Uint8List?> getBestCut(List<Uint8List> images) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/bestcut"));
      for (int i = 0; i < images.length; i++) {
        request.files.add(http.MultipartFile.fromBytes(
          'files', images[i],
          filename: 'burst_$i.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      var response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {
      print("❌ 베스트 컷 통신 에러: $e");
    }
    return null;
  }
}
