import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 백엔드 서버 URL (실제 서버 주소로 변경하세요)
  static const String baseUrl = 'http://192.249.29.78:4000';
//   static const String baseUrl = 'http://localhost:4000';
//   static const String baseUrl = 'http://143.248.163.115:4000';

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
  static Map<String, dynamic> _handleResponse(http.Response response, String operation) {
    if (!_isJsonResponse(response.body)) {
      return {
        'success': false,
        'message': '$operation 실패: 서버에서 잘못된 응답을 받았습니다. (서버 상태코드: ${response.statusCode})'
      };
    }

    final data = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': data,
        'message': data['message'] ?? '$operation 성공'
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? '$operation 실패 (${response.statusCode})'
      };
    }
  }
  
  // 로그인 API 호출
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
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
      return {
        'success': false,
        'message': '로그인 중 네트워크 오류가 발생했습니다: $e'
      };
    }
  }

  // 회원가입 API 호출
  static Future<Map<String, dynamic>> register(String nickname, String username, String password, String realname, String division) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
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
      return {
        'success': false,
        'message': '회원가입 중 네트워크 오류가 발생했습니다: $e'
      };
    }
  }

  // 토큰 저장
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // 토큰 가져오기
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // 토큰 삭제 (로그아웃)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // 완전 로그아웃 (토큰 + userId 모두 삭제)
  static Future<void> logout() async {
    await removeToken();
    await removeUserId();
  }

  // 아이디 찾기 API 호출
  static Future<Map<String, dynamic>> findId(String realname, String division) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/find-id'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'realName': realname,
          'division': division,
        }),
      );

      return _handleResponse(response, '아이디 찾기');
    } catch (e) {
      return {
        'success': false,
        'message': '아이디 찾기 중 네트워크 오류가 발생했습니다: $e'
      };
    }
  }

  // userId 저장
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  // userId 가져오기
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // userId 삭제 (로그아웃)
  static Future<void> removeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  // 토큰 유효성 검증
  static Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verify-token'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 사용자 정보 가져오기
  static Future<Map<String, dynamic>> getUserInfo() async {
    final token = await getToken();
    if (token == null) {
      return {
        'success': false,
        'message': '토큰이 없습니다'
      };
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response, '사용자 정보 조회');
    } catch (e) {
      return {
        'success': false,
        'message': '사용자 정보 조회 중 네트워크 오류가 발생했습니다: $e'
      };
    }
  }


  // 비밀번호 재설정
  static Future<Map<String, dynamic>> resetPassword(String username, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'newPassword': newPassword,
        }),
      );

      return _handleResponse(response, '비밀번호 재설정');
    } catch (e) {
      return {
        'success': false,
        'message': '비밀번호 재설정 중 네트워크 오류가 발생했습니다: $e'
      };
    }
  }
} 