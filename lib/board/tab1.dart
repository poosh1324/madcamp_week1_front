import 'package:flutter/material.dart';
import 'post_model.dart';
import 'write_post_page.dart';
import 'post_detail_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDummyData();
    _filteredPosts = _posts;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 더미 데이터 로드
  void _loadDummyData() {
    _posts = [
      Post(
        id: 1,
        title: 'Flutter 개발 시작하기',
        content: 'Flutter는 Google에서 개발한 크로스 플랫폼 앱 개발 프레임워크입니다. 하나의 코드베이스로 iOS와 Android 앱을 동시에 개발할 수 있어서 매우 효율적입니다.\n\n시작하기 위해서는 다음 단계들을 따라해보세요:\n1. Flutter SDK 설치\n2. 개발 환경 설정\n3. 첫 번째 앱 만들기\n4. 위젯 이해하기',
        author: '플러터러버',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        views: 45,
        tags: ['Flutter', '개발', '시작'],
      ),
      Post(
        id: 2,
        title: '위젯의 이해와 활용',
        content: 'Flutter에서 모든 것은 위젯입니다. 텍스트, 버튼, 레이아웃까지 모든 UI 요소가 위젯으로 구성되어 있습니다.\n\n주요 위젯들:\n- StatelessWidget: 상태가 없는 위젯\n- StatefulWidget: 상태가 있는 위젯\n- Container: 레이아웃과 스타일링을 위한 위젯\n- Row, Column: 수평, 수직 배치를 위한 위젯',
        author: '코드마스터',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        views: 23,
        tags: ['Widget', 'UI', 'Flutter'],
      ),
      Post(
        id: 3,
        title: '상태 관리 패턴 비교',
        content: 'Flutter에서 상태 관리는 매우 중요합니다. 여러 가지 패턴들이 있는데, 각각의 장단점을 알아보겠습니다.\n\n1. setState: 가장 기본적인 방법\n2. Provider: 의존성 주입과 상태 관리\n3. Bloc: 비즈니스 로직 분리\n4. Riverpod: Provider의 개선된 버전\n5. GetX: 간단하고 강력한 상태 관리',
        author: '아키텍처맨',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        views: 67,
        tags: ['상태관리', 'Provider', 'Bloc'],
      ),
      Post(
        id: 4,
        title: '앱 성능 최적화 팁',
        content: 'Flutter 앱의 성능을 향상시키는 여러 가지 방법들을 소개합니다.\n\n성능 최적화 방법:\n- const 위젯 사용하기\n- build 메서드 최적화\n- 이미지 최적화\n- 메모리 누수 방지\n- 프로파일 모드로 테스트하기',
        author: '성능최적화자',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        views: 89,
        tags: ['성능', '최적화', '팁'],
      ),
      Post(
        id: 5,
        title: '디자인 시스템 구축하기',
        content: '일관된 UI/UX를 위한 디자인 시스템 구축 방법을 알아보겠습니다.\n\n디자인 시스템 구성 요소:\n- 컬러 팔레트\n- 타이포그래피\n- 컴포넌트 라이브러리\n- 아이콘 시스템\n- 스페이싱 가이드',
        author: 'UI디자이너',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        views: 34,
        tags: ['디자인', 'UI', 'UX'],
      ),
    ];

    // 조회수가 높은 순으로 정렬
    _posts.sort((a, b) => b.views.compareTo(a.views));
  }

  void _filterPosts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPosts = _posts;
      } else {
        _filteredPosts = _posts.where((post) {
          return post.title.toLowerCase().contains(query.toLowerCase()) ||
                 post.content.toLowerCase().contains(query.toLowerCase()) ||
                 post.author.toLowerCase().contains(query.toLowerCase()) ||
                 post.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  void _writeNewPost() async {
    final result = await Navigator.push<Post>(
      context,
      MaterialPageRoute(
        builder: (context) => const WritePostPage(),
      ),
    );

    if (result != null) {
      setState(() {
        _posts.insert(0, result);
        _filterPosts(_searchController.text);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새 게시글이 작성되었습니다!')),
      );
    }
  }

  void _updatePost(Post updatedPost) {
    setState(() {
      final index = _posts.indexWhere((post) => post.id == updatedPost.id);
      if (index != -1) {
        _posts[index] = updatedPost;
        _filterPosts(_searchController.text);
      }
    });
  }

  void _deletePost(int postId) {
    setState(() {
      _posts.removeWhere((post) => post.id == postId);
      _filterPosts(_searchController.text);
    });
  }

  void _viewPost(Post post) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '검색어를 입력하세요...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _filterPosts,
                autofocus: true,
              )
            : const Text('게시판'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _filterPosts('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: _filteredPosts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '게시글이 없습니다',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '첫 번째 게시글을 작성해보세요!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filteredPosts.length,
              itemBuilder: (context, index) {
                final post = _filteredPosts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      post.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
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
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person, 
                                 size: 14, 
                                 color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              post.author,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time, 
                                 size: 14, 
                                 color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              post.timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.visibility, 
                                 size: 14, 
                                 color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${post.views}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        if (post.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            children: post.tags.take(3).map((tag) {
                              return Chip(
                                label: Text('#$tag'),
                                labelStyle: const TextStyle(fontSize: 10),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: Colors.blue.shade50,
                                side: BorderSide(color: Colors.blue.shade200),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                    onTap: () => _viewPost(post),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _writeNewPost,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit),
      ),
    );
  }
}