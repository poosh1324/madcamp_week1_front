import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../api_service.dart'; // baseUrl 정의되어 있는 곳

class GalleryApiService {
  // 이미지 목록 불러오기
  static Future<List<String>> fetchImageUrls() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/gallery'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item.toString()).toList();
      } else {
        throw Exception('이미지 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 이미지 업로드
  static Future<void> uploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/gallery/upload'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('image', pickedFile.path),
      );
      final headers = await ApiService.getAuthHeaders();
      request.headers.addAll(headers);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        throw Exception('이미지 업로드 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('업로드 중 오류 발생: $e');
    }
  }
}
