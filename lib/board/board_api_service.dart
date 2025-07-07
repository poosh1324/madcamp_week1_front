import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'post_model.dart';
import '../api_service.dart' show ApiService;
import 'comment_model.dart';

class BoardApiService {
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

  // 1. 게시글 목록 조회
  static Future<List<Post>> getPosts({
    int page = 1,
    int limit = 10,
    String? searchQuery,
    String? sortBy = 'createdAt',
    String? sortOrder = 'desc',
  }) async {
    try {
      final headers = await _getHeaders();
      // 쿼리 파라미터 구성
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      final uri = Uri.parse(
        '${ApiService.baseUrl}/posts/boards/all',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);


      if (response.statusCode == 200) {
        // 서버 응답 타입 확인
        final dynamic responseData = json.decode(response.body);


        if (responseData is List) {
          final List<dynamic> postsJson = responseData;

          if (postsJson.isNotEmpty) {
          }

          final posts = postsJson.map((json) => Post.fromJson(json)).toList();

          return posts;
        } else {
          print('❌ 응답이 배열이 아님: ${responseData.runtimeType}');
          throw Exception(
            '서버에서 예상하지 못한 응답 형식을 받았습니다: ${responseData.runtimeType}',
          );
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
        Uri.parse('${ApiService.baseUrl}/posts/$postId'),
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
    required String division,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'title': title,
        'content': content,
        'division': division,
      });
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/posts/create'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String postId = data['postId'];
        return await getPost(postId);
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
      final body = json.encode({'title': title, 'content': content});

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/posts/$postId'),
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
        Uri.parse('${ApiService.baseUrl}/posts/$postId'),
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

      final uri = Uri.parse(
        '${ApiService.baseUrl}/search',
      ).replace(queryParameters: queryParams);
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
      final uri = Uri.parse(
        '${ApiService.baseUrl}/popular',
      ).replace(queryParameters: {'limit': limit.toString()});

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
      final uri = Uri.parse('${ApiService.baseUrl}/my-posts').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

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

  // === 댓글 관련 API 함수들 ===

  // 9. 특정 게시글의 댓글 목록 조회 (대댓글 포함)
  static Future<List<Comment>> getComments(String postId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/posts/$postId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print('댓글 응답 전체: ${response.body}');
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> commentsJson = data['comments'];
        print("🤢commentsJson: $commentsJson");
        return commentsJson.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception('댓글 목록을 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 10. 댓글 작성
  static Future<Comment> createComment({
    required String postId,
    required String content,
    String? parentId, // 대댓글인 경우 부모 댓글 ID
  }) async {
    try {
      print('parentId: $parentId');
      final headers = await _getHeaders();
      final body = json.encode({
        'content': content,
        if (parentId != null) 'parentCommentId': parentId,
      });

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/comments/$postId'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);

        return Comment.fromJson(data);
      } else {
        throw Exception('댓글 작성에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 11. 댓글 수정
  static Future<Comment> updateComment({
    required String commentId,
    required String content,
    String? parentId,
  }) async {
    print("😱commentId: $commentId");
    print("😱content: $content");
    try {
      final headers = await _getHeaders();
      final body = json.encode({'content': content});

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/comments/$commentId'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        print("😱response.body: ${response.body}");
        final Map<String, dynamic> data = json.decode(response.body);
        // 서버가 content를 포함하지 않으므로 수동으로 추가
        data['content'] = content;
        data['parentId'] = parentId;
        return Comment.fromJson(data);
      } else {
        throw Exception('댓글 수정에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 12. 댓글 삭제
  static Future<void> deleteComment(String commentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/comments/$commentId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('댓글 삭제에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 13. 댓글 좋아요/싫어요
  static Future<String> likeComment({
    required String commentId,
    required bool isLike, // true: 좋아요, false: 싫어요
  }) async {
    try {
      final headers = await _getHeaders();
      var body;
      if (isLike) {
        body = json.encode({'voteType': "like"});
      } else {
        body = json.encode({'voteType': "dislike"});
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/comments/$commentId/vote'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("😱data: $data");
        
        return data['message'];
      } else {
        throw Exception('댓글 좋아요/싫어요에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // 14. 대댓글 작성 (별도 엔드포인트가 있는 경우)
  static Future<Comment> createReply({
    required String commentId,
    required String content,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({'content': content});

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/comments/$commentId/replies'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Comment.fromJson(data['reply']);
      } else {
        throw Exception('대댓글 작성에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  // === 게시글 관련 추가 API 함수들 ===

  // 15. 게시글 좋아요/싫어요
  static Future<String> likePost({
    required String postId,
    required bool isLike, // true: 좋아요, false: 싫어요
  }) async {
    try {
      final headers = await _getHeaders();
      var body;
      if (isLike) {
        body = json.encode({'voteType': "like"});
      } else {
        body = json.encode({'voteType': "dislike"});
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/posts/$postId/vote'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("게시글 좋아요 응답: $data");
        
        return data['message'] ?? 'success';
      } else {
        throw Exception('게시글 좋아요/싫어요에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }
}
