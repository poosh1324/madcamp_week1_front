import 'package:flutter/material.dart';
import 'gallery_detail_page.dart';
import 'gallery_api_service.dart';

class GalleryDivisionPage extends StatefulWidget {
  final String division;

  const GalleryDivisionPage({super.key, required this.division});

  @override
  State<GalleryDivisionPage> createState() => _GalleryDivisionPageState();
}

class _GalleryDivisionPageState extends State<GalleryDivisionPage> {
  late Future<List<String>> _imageUrls;
  late final String division;

  @override
  void initState() {
    super.initState();
    division = widget.division;
    _imageUrls = GalleryApiService.fetchImages(division);
  }

  void _reloadImages() {
    setState(() {
      _imageUrls = GalleryApiService.fetchImages(division);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text('$division 분반 갤러리')),
          body: FutureBuilder<List<String>>(
            future: _imageUrls,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('에러 발생: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('이미지가 없습니다.'));
              } else {
                final images = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: images.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemBuilder: (context, index) {
                    final imageUrl = images[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GalleryDetailPage(imageUrl: imageUrl),
                          ),
                        );
                      },
                      child: Image.network(imageUrl, fit: BoxFit.cover),
                    );
                  },
                );
              }
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              try {
                await GalleryApiService.uploadImage(division);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('업로드 성공!')));
                _reloadImages();
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
              }
            },
            child: const Icon(Icons.add_a_photo),
          ),
        ),
      ],
    );
  }
}
