import 'package:flutter/material.dart';
import 'post_model.dart';

class WritePostPage extends StatefulWidget {
  final Post? post; // 수정할 때 기존 게시글 전달

  const WritePostPage({super.key, this.post});

  @override
  State<WritePostPage> createState() => _WritePostPageState();
}

class _WritePostPageState extends State<WritePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  List<String> _tags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // 수정 모드인 경우 기존 데이터 로드
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _contentController.text = widget.post!.content;
      _tags = List.from(widget.post!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _savePost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력하세요.')),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력하세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 새 게시글 생성
    final newPost = Post(
      id: widget.post?.id ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      content: content,
      author: '익명', // 나중에 로그인한 사용자명으로 변경
      createdAt: widget.post?.createdAt ?? DateTime.now(),
      views: widget.post?.views ?? 0,
      tags: _tags,
    );

    // 잠시 로딩 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });

    // 게시글을 이전 화면으로 전달
    Navigator.pop(context, newPost);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.post != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '게시글 수정' : '새 게시글'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePost,
            child: const Text(
              '완료',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 제목 입력
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '제목',
                      border: OutlineInputBorder(),
                      hintText: '게시글 제목을 입력하세요',
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  
                  // 내용 입력
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: '내용',
                        border: OutlineInputBorder(),
                        hintText: '게시글 내용을 입력하세요',
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 태그 입력
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            labelText: '태그',
                            border: OutlineInputBorder(),
                            hintText: '태그를 입력하세요',
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addTag,
                        child: const Text('추가'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // 태그 리스트
                  if (_tags.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeTag(tag),
                            backgroundColor: Colors.blue.shade50,
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
} 