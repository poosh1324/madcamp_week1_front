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

  // 분반별 이미지 목록 불러오기
  static Future<List<Map<String, dynamic>>> fetchImages(String division) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/gallery/$division'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map<Map<String, dynamic>>((item) {
          return {
            'imageId': item['imageId'],
            'imageUrl': item['imageUrl'],
            'uploader': item['uploader'],
            'uploadedAt': item['uploadedAt'],
          };
        }).toList();
      } else {
        throw Exception('이미지 목록 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 이미지 업로드
  static Future<void> uploadImage(String division) async {
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
      request.fields['division'] = division;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        throw Exception('이미지 업로드 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('업로드 중 오류 발생: $e');
    }
  }

  // 분반별 이미지 프리뷰 불러오기
  static Future<List<String>> fetchImagePreviews(String division) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/gallery/$division'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item['imageUrl'].toString()).toList();
      } else {
        throw Exception('이미지 프리뷰 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 분반별 이미지 프리뷰 Map 타입으로 리턴
  static Future<Map<String, List<String>>> fetchAllImagePreviews() async {
    const divisions = ['1', '2', '3', '4'];
    final Map<String, List<String>> previews = {};

    for (final division in divisions) {
      try {
        final images = await fetchImagePreviews(division);
        previews[division] = images;
      } catch (e) {
        previews[division] = []; // 실패 시 빈 리스트 처리
      }
    }

    return previews;
  }

  // 이미지 삭제
  static Future<bool> deleteImage(int imageId) async {
    try {
      final headers = await ApiService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/gallery/$imageId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('이미지 삭제 실패: ${response.body}');
        return false;
      }
    } catch (e) {
      print('삭제 중 오류 발생: $e');
      return false;
    }
  }
}
