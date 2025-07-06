import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // debugPrint 사용을 위해 추가

class ApiService {
  // 백엔드 서버 URL (실제 서버 주소로 변경하세요)
  static const String baseUrl = 'http://localhost:4000';
  //   static const String baseUrl = 'http://143.248.163.115:4000';
  //   static const String baseUrl = 'http://192.249.29.78:4000';
  // static const String baseUrl =
  //     'https://madcampweek1back-production.up.railway.app';

  // JSON 응답인지 확인하는 도우미 함수
  static bool _isJsonResponse(String responseBody) {
    try {
      jsonDecode(responseBody);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 응답 처리하는 도우미 함수
  static Map<String, dynamic> _handleResponse(
    http.Response response,
    String operation,
  ) {
    if (!_isJsonResponse(response.body)) {
      return {
        'success': false,
        'message':
            '$operation 실패: 서버에서 잘못된 응답을 받았습니다. (서버 상태코드: ${response.statusCode})',
      };
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': data,
        'message': data['message'] ?? '$operation 성공',
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? '$operation 실패 (${response.statusCode})',
      };
    }
  }

  // 로그인 API 호출
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );

      final result = _handleResponse(response, '로그인');

      if (result['success'] && result['data'] != null) {
        // 토큰 저장
        if (result['data']['token'] != null) {
          await saveToken(result['data']['token']);
        }

        // userId 저장
        if (result['data']['userId'] != null) {
          await saveUserId(result['data']['userId'].toString());
        }
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': '로그인 중 네트워크 오류가 발생했습니다: $e'};
    }
  }

  // 회원가입 API 호출
  static Future<Map<String, dynamic>> register(
    String nickname,
    String username,
    String password,
    String realname,
    String division,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nickname': nickname,
          'username': username,
          'password': password,
          'realName': realname,
          'division': division,
        }),
      );

      return _handleResponse(response, '회원가입');
    } catch (e) {
      return {'success': false, 'message': '회원가입 중 네트워크 오류가 발생했습니다: $e'};
    }
  }

  // 토큰 저장
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);

    // 🔍 디버깅: 토큰 저장 확인
    print("토큰: $token");
  }

  // 토큰 가져오기
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // 🔍 디버깅: 토큰 조회 결과
    if (token != null) {
      print("토큰: $token");
    } else {
      print("❌ 토큰 없음");
    }

    return token;
  }

  // 토큰 삭제 (로그아웃)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    // 🔍 디버깅: 토큰 삭제 확인
    print("🗑️ 토큰 삭제됨");
  }

  // 완전 로그아웃 (토큰 + userId 모두 삭제)
  static Future<void> logout() async {
    await removeToken();
    await removeUserId();

    // 🔍 디버깅: 완전 로그아웃 확인
    print("🚪 완전 로그아웃 완료");
  }

  // 아이디 찾기 API 호출
  static Future<Map<String, dynamic>> findId(
    String realname,
    String division,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/find-id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'realName': realname, 'division': division}),
      );

      return _handleResponse(response, '아이디 찾기');
    } catch (e) {
      return {'success': false, 'message': '아이디 찾기 중 네트워크 오류가 발생했습니다: $e'};
    }
  }

  // userId 저장
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);

    // 🔍 디버깅: userId 저장 확인
    print("👤 userId 저장됨: $userId");
  }

  // userId 가져오기
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    // 🔍 디버깅: userId 조회 결과
    if (userId != null) {
      print("👤 userId 조회 성공: $userId");
    } else {
      print("❌ userId 없음");
    }

    return userId;
  }

  // userId 삭제 (로그아웃)
  static Future<void> removeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');

    // 🔍 디버깅: userId 삭제 확인
    print("🗑️ userId 삭제됨");
  }

  // 토큰 유효성 검증
  static Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verify-token'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 비밀번호 재설정
  static Future<Map<String, dynamic>> resetPassword(
    String username,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'newPassword': newPassword}),
      );

      return _handleResponse(response, '비밀번호 재설정');
    } catch (e) {
      return {'success': false, 'message': '비밀번호 재설정 중 네트워크 오류가 발생했습니다: $e'};
    }
  }

  // 로그인한 사용자 프로필 정보 가져오기
  static Future<Map<String, dynamic>> fetchUserInfo() async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': '토큰이 없습니다', 'data': null};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final result = _handleResponse(response, '사용자 정보 조회');

      // 디버깅 로그 출력
      debugPrint('👤 User Info Fetched: ${result['data']}');

      return result['data'];
    } catch (e) {
      return {
        'success': false,
        'message': '사용자 정보 조회 중 오류가 발생했습니다: $e',
        'data': null,
      };
    }
  }

  // 내가 쓴 글 가져오기
  static Future<List<Map<String, dynamic>>> fetchMyPosts() async {
    final token = await getToken();
    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/posts'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('❌ fetchMyPosts 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ fetchMyPosts 오류: $e');
      return [];
    }
  }

  // 내가 쓴 댓글 가져오기
  static Future<List<Map<String, dynamic>>> fetchMyComments() async {
    final token = await getToken();
    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/comments'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('❌ fetchMyComments 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ fetchMyComments 오류: $e');
      return [];
    }
  }
}
