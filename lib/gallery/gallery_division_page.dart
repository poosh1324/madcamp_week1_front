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
  late Future<List<Map<String, dynamic>>> _imageDataList;
  late final String division;

  @override
  void initState() {
    super.initState();
    division = widget.division;
    _imageDataList = GalleryApiService.fetchImages(widget.division);
  }

  void _reloadImages() {
    setState(() {
      _imageDataList = GalleryApiService.fetchImages(division);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, true); // 변화가 있었음을 리턴
              },
            ),
            title: Text('$division 분반 갤러리'),
          ),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _imageDataList,
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
                    final image = images[index];
                    final imageId = image['imageId'];
                    final imageUrl = image['imageUrl'];
                    final imageUploader = image['uploader'];
                    final imageUploadedAt = DateTime.tryParse(
                      image['uploadedAt'],
                    );
                    return GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GalleryDetailPage(
                              imageId: imageId,
                              imageUrl: imageUrl,
                              uploader: imageUploader,
                              uploadedAt: imageUploadedAt,
                              division: division,
                            ),
                          ),
                        );
                        if (result == true) {
                          _reloadImages();
                        }
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
