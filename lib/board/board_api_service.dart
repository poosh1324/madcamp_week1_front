import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'post_model.dart';

class BoardApiService {
  // static const String baseUrl = 'http://localhost:4000';
  static const String baseUrl = 'https://madcampweek1back-production.up.railway.app';

  
  // 토큰 가져오기
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
  // 공통 헤더 설정
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. 게시글 목록 조회
  static Future<List<Post>> getPosts({
    int page = 1,
    int limit = 10,
    String? searchQuery,
    String? sortBy = 'createdAt',
    String? sortOrder = 'desc',
  }) async {
    try {
      print('=== getPosts 시작 ===');
      print('요청 파라미터: page=$page, limit=$limit');
      
      final headers = await _getHeaders();
      print('헤더 확인: $headers');
      
      // 쿼리 파라미터 구성
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      final uri = Uri.parse('$baseUrl/posts/boards/all').replace(queryParameters: queryParams);
      print('요청 URL: $uri');
      
      final response = await http.get(uri, headers: headers);
      print('응답 상태코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        // 서버 응답 타입 확인
        final dynamic responseData = json.decode(response.body);
        print('파싱된 데이터: $responseData');
        print('파싱된 데이터 타입: ${responseData.runtimeType}');
        
        if (responseData is List) {
          final List<dynamic> postsJson = responseData;
          print('배열 길이: ${postsJson.length}');
          
          if (postsJson.isNotEmpty) {
            print('첫 번째 게시글: ${postsJson[0]}');
          }
          
          final posts = postsJson.map((json) => Post.fromJson(json)).toList();
          print('변환된 Post 객체 수: ${posts.length}');
          print('=== getPosts 성공 ===');
          return posts;
        } else {
          print('❌ 응답이 배열이 아님: ${responseData.runtimeType}');
          throw Exception('서버에서 예상하지 못한 응답 형식을 받았습니다: ${responseData.runtimeType}');
        }
      } else {
        print('❌ HTTP 오류: ${response.statusCode}');
        print('오류 본문: ${response.body}');
        throw Exception('게시글 목록을 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
      print('예외 타입: ${e.runtimeType}');
      throw Exception('네트워크 오류: $e');
    }
  }

  // 2. 게시글 상세 조회 (조회수 증가 포함)
  static Future<Post> getPost(String postId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Post.fromJson(data);
        
      } else {
        throw Exception('게시글을 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 3. 새 게시글 작성
  static Future<Post> createPost({
    required String title,
    required String content,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'title': title,
        'content': content,
      });
      
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Post.fromJson(data['post']);
      } else {
        throw Exception('게시글 작성에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 4. 게시글 수정
  static Future<Post> updatePost({
    required String postId,
    required String title,
    required String content,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'title': title,
        'content': content,
      });
      
      final response = await http.put(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Post.fromJson(data['post']);
      } else {
        throw Exception('게시글 수정에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 5. 게시글 삭제
  static Future<void> deletePost(String postId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/boards/$postId'),
        headers: headers,
      );
      
      if (response.statusCode != 200) {
        throw Exception('게시글 삭제에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 6. 게시글 검색
  static Future<List<Post>> searchPosts({
    required String query,
    String? category,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final queryParams = {
        'q': query,
        if (category != null) 'category': category,
      };
      
      final uri = Uri.parse('$baseUrl/search').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> postsJson = data['posts'];
        
        return postsJson.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('검색에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 7. 인기 게시글 조회
  static Future<List<Post>> getPopularPosts({int limit = 10}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/popular').replace(queryParameters: {
        'limit': limit.toString(),
      });
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> postsJson = data['posts'];
        
        return postsJson.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('인기 게시글을 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 8. 내가 작성한 게시글 조회
  static Future<List<Post>> getMyPosts({int page = 1, int limit = 20}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/my-posts').replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> postsJson = data['posts'];
        
        return postsJson.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('내 게시글을 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }
} 