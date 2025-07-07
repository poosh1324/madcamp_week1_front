import 'package:flutter/material.dart';
import 'package:test_madcamp/gallery/gallery_api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final shouldContain = _scrollController.offset > 100;
      if ((_currentFit == BoxFit.cover && shouldContain) ||
          (_currentFit == BoxFit.contain && !shouldContain)) {
        setState(() {
          _currentFit = shouldContain ? BoxFit.contain : BoxFit.cover;
        });
      }
    });

    _loadInitialLikeStatus();
  }

  Future<void> _loadInitialLikeStatus() async {
    try {
      final likeData = await GalleryApiService.checkIfLiked(widget.imageId);
      print('🟢 likeData received: $likeData');
      setState(() {
        _isLiked = likeData['liked'];
        _likeCount = likeData['likeCount'];
      });
    } catch (e) {
      print('Failed to load like status: $e');
      setState(() {
        _isLiked = false;
        _likeCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
                const Text("댓글 영역 (향후 구현)"),
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
          duration: Duration(milliseconds: 300),
          child: Image.network(
            imageUrl,
            key: ValueKey(fit),
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
