import 'dart:async';
import 'package:flutter/material.dart';
import 'package:test_madcamp/gallery/gallery_api_service.dart';
import 'package:test_madcamp/gallery/gallery_comment_api_service.dart';

class GalleryDetailPage extends StatefulWidget {
  final int imageId;
  final String imageUrl;
  final String? uploader;
  final DateTime? uploadedAt;
  final String division;

  const GalleryDetailPage({
    Key? key,
    required this.imageId,
    required this.imageUrl,
    this.uploader,
    this.uploadedAt,
    required this.division,
  }) : super(key: key);

  @override
  State<GalleryDetailPage> createState() => _GalleryDetailPageState();
}

class _GalleryDetailPageState extends State<GalleryDetailPage> {
  late ScrollController _scrollController;
  BoxFit _currentFit = BoxFit.cover;

  late int _likeCount;
  bool? _isLiked;

  List<Map<String, dynamic>> _comments = [];

  final TextEditingController _commentController = TextEditingController();

  Timer? _fitUpdateTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fitUpdateTimer = null;
    _scrollController.addListener(() {
      _fitUpdateTimer?.cancel();
      _fitUpdateTimer = Timer(const Duration(milliseconds: 200), () {
        final shouldContain = _scrollController.offset > 100;
        if ((_currentFit == BoxFit.cover && shouldContain) ||
            (_currentFit == BoxFit.contain && !shouldContain)) {
          setState(() {
            _currentFit = shouldContain ? BoxFit.contain : BoxFit.cover;
          });
        }
      });
    });

    _loadInitialLikeStatus();
    _loadComments();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      await GalleryCommentApiService.postComment(widget.imageId, content);
      _commentController.clear();
      _loadComments();
    } catch (e) {
      print('댓글 작성 실패: $e');
    }
  }

  Future<void> _loadInitialLikeStatus() async {
    try {
      final likeData = await GalleryApiService.checkIfLiked(widget.imageId);
      // print('🟢 likeData received: $likeData');
      if (mounted) {
        setState(() {
          _isLiked = likeData['liked'];
          _likeCount = likeData['likeCount'];
        });
      }
    } catch (e) {
      print('Failed to load like status: $e');
      if (mounted) {
        setState(() {
          _isLiked = false;
          _likeCount = 0;
        });
      }
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await GalleryCommentApiService.getComments(
        widget.imageId,
      );
      // Allow temporary keys for reply UI state and showReplies for top-level comments
      if (mounted) {
        setState(() {
          _comments = comments.map<Map<String, dynamic>>((c) {
            final isTopLevel = c['parent_id'] == null;
            return {
              ...c,
              'showReplyField': c['showReplyField'] ?? false,
              'replyText': c['replyText'] ?? '',
              if (isTopLevel) 'showReplies': c['showReplies'] ?? false,
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Failed to load comments: $e');
    }
  }

  @override
  void dispose() {
    _fitUpdateTimer?.cancel();
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleLikeTap() async {
    final newLikeState = !_isLiked!;
    final success = newLikeState
        ? await GalleryApiService.likeImage(widget.imageId)
        : await GalleryApiService.unlikeImage(widget.imageId);

    if (success) {
      setState(() {
        _isLiked = newLikeState;
        _likeCount += _isLiked! ? 1 : -1;
      });
    } else {
      // Optionally, show an error message
      print('Failed to update like status');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLiked == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverPersistentHeader(
            delegate: _ImageHeaderDelegate(
              imageUrl: widget.imageUrl,
              fit: _currentFit,
              expandedHeight: screenHeight,
            ),
            pinned: false,
            floating: false,
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _LikesHeaderDelegate(
              onTap: _handleLikeTap,
              isLiked: _isLiked!,
              likeCount: _likeCount,
            ),
          ),
        ],
        body: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.uploader != null)
                  Text(
                    "Uploaded by: ${widget.uploader}",
                    style: const TextStyle(fontSize: 12),
                  ),
                const SizedBox(height: 20),
                const Divider(),
                const Text(
                  "Comments",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: "Add a comment",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _submitComment,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // New comment/reply rendering logic
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _comments
                      .where((c) => c['parent_id'] == null)
                      .length,
                  itemBuilder: (context, topLevelIndex) {
                    // Only top-level comments in this builder
                    final topLevelComments = _comments
                        .where((c) => c['parent_id'] == null)
                        .toList();
                    final comment = topLevelComments[topLevelIndex];
                    final commentIndex = _comments.indexWhere(
                      (c) => c['id'] == comment['id'],
                    );

                    // Helper to build a comment tile (used for replies)
                    Widget buildCommentTile(
                      Map<String, dynamic> c,
                      int idx, {
                      bool isReply = false,
                    }) {
                      // Move the hasReplies declaration above the widget logic
                      final hasReplies = _comments.any(
                        (r) => r['parent_id'] == c['id'],
                      );
                      return Padding(
                        padding: EdgeInsets.only(
                          left: isReply ? 24.0 : 0.0,
                          right: 0,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['image_unknown_number'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(c['content'] ?? ''),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, size: 18),
                                      onPressed: () {
                                        final controller =
                                            TextEditingController(
                                              text: c['content'],
                                            );
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text("Edit Comment"),
                                            content: TextField(
                                              controller: controller,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  final newText = controller
                                                      .text
                                                      .trim();
                                                  if (newText.isNotEmpty) {
                                                    await GalleryCommentApiService.updateComment(
                                                      c['id'],
                                                      newText,
                                                    );
                                                    Navigator.pop(context);
                                                    _loadComments();
                                                  }
                                                },
                                                child: Text("Save"),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 18),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text("Delete Comment"),
                                            content: Text(
                                              "Are you sure you want to delete this comment?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: Text("Delete"),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await GalleryCommentApiService.deleteComment(
                                            c['id'],
                                          );
                                          _loadComments();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Reply button (only for top-level comments, not replies)
                            if (!isReply)
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _comments[idx]['showReplyField'] =
                                            !(_comments[idx]['showReplyField'] ??
                                                false);
                                      });
                                    },
                                    child: Text("Reply"),
                                  ),
                                  // Show/hide replies button only if there are replies
                                  if (hasReplies)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _comments[idx]['showReplies'] =
                                              !(_comments[idx]['showReplies'] ??
                                                  false);
                                        });
                                      },
                                      child: Text(
                                        (c['showReplies'] ?? false)
                                            ? "Hide replies"
                                            : "Show replies",
                                      ),
                                    ),
                                ],
                              ),
                            // Show reply field if toggled
                            if (c['showReplyField'] ?? false)
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Column(
                                  children: [
                                    TextField(
                                      onChanged: (text) {
                                        setState(() {
                                          _comments[idx]['replyText'] = text;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        hintText: "Write a reply...",
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () async {
                                            final replyContent =
                                                _comments[idx]['replyText']
                                                    ?.trim() ??
                                                '';
                                            if (replyContent.isNotEmpty) {
                                              await GalleryCommentApiService.postComment(
                                                widget.imageId,
                                                replyContent,
                                                parentId: c['id'],
                                              );
                                              _loadComments();
                                            }
                                          },
                                          child: Text("Post Reply"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            Divider(),
                          ],
                        ),
                      );
                    }

                    // Build this top-level comment and its replies (if showReplies)
                    final replies = _comments
                        .where((r) => r['parent_id'] == comment['id'])
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildCommentTile(comment, commentIndex, isReply: false),
                        if (comment['showReplies'] == true)
                          ...replies.map((reply) {
                            final replyIdx = _comments.indexWhere(
                              (c) => c['id'] == reply['id'],
                            );
                            return buildCommentTile(
                              reply,
                              replyIdx,
                              isReply: true,
                            );
                          }).toList(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String imageUrl;
  final BoxFit fit;
  final double expandedHeight;

  _ImageHeaderDelegate({
    required this.imageUrl,
    required this.fit,
    required this.expandedHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: Duration(milliseconds: 400),
          child: Image.network(
            imageUrl,
            key: ValueKey('${imageUrl.hashCode}_${fit.toString()}'),
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
          ),
        ),
        Positioned(
          top: 40,
          left: 16,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white.withAlpha(200)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: 40,
          right: 16,
          child: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.delete, color: Colors.white.withAlpha(200)),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Delete Image"),
                      content: Text("정말로 이미지를 삭제하시겠습니까?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text("취소"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text("삭제"),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  final success = await GalleryApiService.deleteImage(
                    (context
                            .findAncestorStateOfType<
                              _GalleryDetailPageState
                            >())!
                        .widget
                        .imageId,
                  );
                  if (success && context.mounted) {
                    Navigator.pop(context, true);
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => expandedHeight;

  @override
  bool shouldRebuild(covariant _ImageHeaderDelegate oldDelegate) {
    return oldDelegate.fit != fit || oldDelegate.imageUrl != imageUrl;
  }
}

class _LikesHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onTap;
  final bool isLiked;
  final int likeCount;

  _LikesHeaderDelegate({
    required this.onTap,
    required this.isLiked,
    required this.likeCount,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(
      height: minExtent,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: LikesHeader(
          imageId: (context.findAncestorStateOfType<_GalleryDetailPageState>()!)
              .widget
              .imageId,
          likeCount: likeCount,
          isLiked: isLiked,
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 48.0;
  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant _LikesHeaderDelegate oldDelegate) {
    return oldDelegate.isLiked != isLiked || oldDelegate.likeCount != likeCount;
  }
}

class LikesHeader extends StatelessWidget {
  final int imageId;
  final int likeCount;
  final bool isLiked;
  final VoidCallback onTap;

  const LikesHeader({
    required this.imageId,
    required this.likeCount,
    required this.isLiked,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
          ),
          SizedBox(width: 8),
          Text('$likeCount likes', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
