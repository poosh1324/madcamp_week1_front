import 'package:flutter/material.dart';
import 'post_model.dart';
import 'write_post_page.dart';
import 'post_detail_page.dart';
import 'board_api_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Post> _posts = [];
  List<Post> _filteredPosts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      print('📱 _loadPosts 시작');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🌐 API 호출 시작');
      final posts = await BoardApiService.getPosts();
      print('📊 받은 게시글 수: ${posts.length}');

      setState(() {
        _posts = posts;
        _filteredPosts = posts;
        _isLoading = false;
      });

      print('✅ _loadPosts 완료');
    } catch (e) {
      print('❌ _loadPosts 에러: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      print('🔄 더미 데이터로 폴백');
      // 에러 발생 시 더미 데이터 사용 (개발 중에만)
      _loadDummyData();
    }
  }

  void _loadDummyData() {
    print('🔧 더미 데이터 로드 시작');
    _posts = [
      Post(
        id: '1',
        title: 'Flutter 개발 시작하기',
        content:
            'Flutter는 Google에서 개발한 크로스 플랫폼 앱 개발 프레임워크입니다. 하나의 코드베이스로 iOS와 Android 앱을 동시에 개발할 수 있어서 매우 효율적입니다.\n\n시작하기 위해서는 다음 단계들을 따라해보세요:\n1. Flutter SDK 설치\n2. 개발 환경 설정\n3. 첫 번째 앱 만들기\n4. 위젯 이해하기',
        author: '플러터러버',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        views: 45,
        division: '1',
      ),
      Post(
        id: '2',
        title: '위젯의 이해와 활용',
        content:
            'Flutter에서 모든 것은 위젯입니다. 텍스트, 버튼, 레이아웃까지 모든 UI 요소가 위젯으로 구성되어 있습니다.\n\n주요 위젯들:\n- StatelessWidget: 상태가 없는 위젯\n- StatefulWidget: 상태가 있는 위젯\n- Container: 레이아웃과 스타일링을 위한 위젯\n- Row, Column: 수평, 수직 배치를 위한 위젯',
        author: '코드마스터',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        views: 23,
        division: '2',
      ),
      Post(
        id: '3',
        title: '상태 관리 패턴 비교',
        content:
            'Flutter에서 상태 관리는 매우 중요합니다. 여러 가지 패턴들이 있는데, 각각의 장단점을 알아보겠습니다.\n\n1. setState: 가장 기본적인 방법\n2. Provider: 의존성 주입과 상태 관리\n3. Bloc: 비즈니스 로직 분리\n4. Riverpod: Provider의 개선된 버전\n5. GetX: 간단하고 강력한 상태 관리',
        author: '아키텍처맨',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        views: 67,
        division: '3',
      ),
    ];

    // 조회수가 높은 순으로 정렬
    _posts.sort((a, b) => b.views.compareTo(a.views));
    _filteredPosts = _posts;
    print('✅ 더미 데이터 ${_posts.length}개 로드 완료');
  }

  Future<void> _searchPosts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredPosts = _posts;
      });
      return;
    }

    try {
      final searchResults = await BoardApiService.searchPosts(query: query);
      setState(() {
        _filteredPosts = searchResults;
      });
    } catch (e) {
      _filterPosts(query);
    }
  }

  void _filterPosts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPosts = _posts;
      } else {
        _filteredPosts = _posts.where((post) {
          return post.title.toLowerCase().contains(query.toLowerCase()) ||
              post.content.toLowerCase().contains(query.toLowerCase()) ||
              post.author.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _writeNewPost() async {
    final result = await Navigator.push<Post>(
      context,
      MaterialPageRoute(builder: (context) => const WritePostPage()),
    );
    await _loadPosts();
    if (result != null) {
      try {
        final newPost = await BoardApiService.createPost(
          title: result.title,
          content: result.content,
        );
        setState(() {
          _posts.insert(0, newPost);
          _filterPosts(_searchController.text);
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('새 게시글이 작성되었습니다!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('게시글 작성 실패: ${e.toString()}')));
        }
      }
    }
  }

  void _updatePost(Post updatedPost) async {
    try {
      final updated = await BoardApiService.updatePost(
        postId: updatedPost.id,
        title: updatedPost.title,
        content: updatedPost.content,
      );

      setState(() {
        final index = _posts.indexWhere((post) => post.id == updated.id);
        if (index != -1) {
          _posts[index] = updated;
          _filterPosts(_searchController.text);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('게시글이 수정되었습니다!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('게시글 수정 실패: ${e.toString()}')));
      }
    }
  }

  void _deletePost(String postId) async {
    try {
      await BoardApiService.deletePost(postId);

      setState(() {
        _posts.removeWhere((post) => post.id == postId);
        _filterPosts(_searchController.text);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('게시글 삭제 실패: ${e.toString()}')));
      }
    }
  }

  void _viewPost(Post post) async {
    try {
      final updatedPost= await BoardApiService.getPost(post.id);
      if (mounted) {
        await Navigator.push<Post?>(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              post: updatedPost,
              onPostUpdated: (_) {},
              onPostDeleted: _deletePost,
            ),
          ),
        );
      }
      await _loadPosts();
    } catch (e) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              post: post,
              onPostUpdated: _updatePost,
              onPostDeleted: _deletePost,
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        title: _isSearching
            ? Container(
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                    hintText: '검색',
                  border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 20,
                    ),
                ),
                  style: const TextStyle(fontSize: 14),
                onChanged: _searchPosts,
                autofocus: true,
                ),
              )
            : const Text(
                'MeveryTime',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
        centerTitle: true,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, 
                      color: Colors.black, size: 24),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _filteredPosts = _posts;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 24), 
            onPressed: _refreshPosts
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: Color(0xFFDBDBDB),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '게시글을 불러올 수 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _refreshPosts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : _filteredPosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '게시글이 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '첫 번째 게시글을 작성해보세요!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshPosts,
              color: Colors.black,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _filteredPosts.length,
                itemBuilder: (context, index) {
                  final post = _filteredPosts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFDBDBDB), width: 0.5),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[600],
                        child: Text(
                          post.author.isNotEmpty ? post.author[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        post.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            post.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                post.author,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '·',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                post.timeAgo,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.visibility,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.views}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _viewPost(post),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
        onPressed: _writeNewPost,
          icon: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

