import 'package:flutter/material.dart';
import '/gallery/gallery_detail_page.dart';
import '/gallery/gallery_api_service.dart';

class GalleryTab extends StatefulWidget {
  const GalleryTab({super.key});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  late Future<List<String>> _imageUrls;

  @override
  void initState() {
    super.initState();
    _imageUrls = GalleryApiService.fetchImageUrls(); // API에서 이미지 리스트 가져오기
  }

  void _reloadImages() {
    setState(() {
      _imageUrls = GalleryApiService.fetchImageUrls();
    });
  }

  void _onImageTap(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryDetailPage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Memories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () async {
              await GalleryApiService.uploadImage(); // 갤러리 업로드 기능
              _reloadImages();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _imageUrls,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('이미지 로드 실패: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('이미지가 없습니다.'));
          }

          final urls = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: urls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _onImageTap(urls[index]),
                child: Image.network(urls[index], fit: BoxFit.cover),
              );
            },
          );
        },
      ),
    );
  }
}
