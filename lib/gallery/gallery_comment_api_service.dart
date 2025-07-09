import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_service.dart';

class GalleryCommentApiService {
  // Fetch comments for a specific image
  static Future<List<Map<String, dynamic>>> getComments(int imageId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/gallery/$imageId/comments'),
        headers: await ApiService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['comments'];
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ Failed to fetch comments: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching comments: $e');
      return [];
    }
  }

  // Post a new comment to an image
  static Future<bool> postComment(
    int imageId,
    String content, {
    int? parentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/gallery/$imageId/comments'),
        headers: await ApiService.getAuthHeaders(),
        body: json.encode({
          'content': content,
          if (parentId != null) 'parentId': parentId,
        }),
      );

      if (response.statusCode == 201) {
        print('✅ Comment posted successfully');
        return true;
      } else {
        print('❌ Failed to post comment: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error posting comment: $e');
      return false;
    }
  }

  // Delete a comment
  static Future<bool> deleteComment(int commentId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/gallery/comments/$commentId'),
        headers: await ApiService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        print('✅ Comment deleted successfully');
        return true;
      } else {
        print('❌ Failed to delete comment: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting comment: $e');
      return false;
    }
  }

  // Update a comment
  static Future<bool> updateComment(int commentId, String content) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/gallery/comments/$commentId'),
        headers: await ApiService.getAuthHeaders(),
        body: json.encode({'content': content}),
      );

      if (response.statusCode == 200) {
        print('✅ Comment updated successfully');
        return true;
      } else {
        print('❌ Failed to update comment: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating comment: $e');
      return false;
    }
  }
}
