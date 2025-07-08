import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart'; // baseUrl 정의되어 있는 곳

class GalleryApiService {
  // 토큰 가져오기
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    print(prefs.getString('auth_token'));
    return prefs.getString('auth_token');
  }

  // 공통 헤더 설정
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

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
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/gallery/$division'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('받아온 이미지 데이터: $data');
        return data.map<Map<String, dynamic>>((item) {
          final imageMap = {
            'imageId': item['imageId'],
            'imageUrl': item['imageUrl'],
            'uploader': item['author_nickname'],
            'uploadedAt': item['uploadedAt'],
            'qualified': item['qualified'],
            'likes': item['likes'],
          };
          print(
            '이미지 ID: ${item['imageId']}, 좋아요 수: ${item['likes']}, qualified: ${item['qualified']}',
          );
          return imageMap;
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

  // 이미지 좋아요 요청
  static Future<bool> likeImage(int imageId) async {
    try {
      final headers = await ApiService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/gallery/$imageId/like'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        print('좋아요 실패: ${response.body}');
        return false;
      }
      return true;
    } catch (e) {
      print('좋아요 중 오류 발생: $e');
      return false;
    }
  }

  // 이미지 좋아요 취소 요청
  static Future<bool> unlikeImage(int imageId) async {
    try {
      final headers = await ApiService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/gallery/$imageId/like'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        print('좋아요 취소 실패: ${response.body}');
        return false;
      }
      return true;
    } catch (e) {
      print('좋아요 취소 중 오류 발생: $e');
      return false;
    }
  }

  // 특정 이미지에 대해 사용자가 좋아요를 눌렀는지 확인하고 좋아요 수 반환
  static Future<Map<String, dynamic>> checkIfLiked(int imageId) async {
    try {
      final headers = await ApiService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/gallery/$imageId/like'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // print('checkIfLiked 응답 데이터: $data');
        return {
          'liked': data['liked'] == true,
          'likeCount': data['likes'] ?? 0,
        };
      } else {
        print('좋아요 여부 확인 실패: ${response.body}');
        return {'liked': false, 'likes': 0};
      }
    } catch (e) {
      print('좋아요 여부 확인 중 오류 발생: $e');
      return {'liked': false, 'likes': 0};
    }
  }
}
