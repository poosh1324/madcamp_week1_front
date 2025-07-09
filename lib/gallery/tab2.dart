import 'package:flutter/material.dart';
import '/gallery/gallery_api_service.dart';
import '/gallery/gallery_division_page.dart';

class GalleryTab extends StatefulWidget {
  const GalleryTab({super.key});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  late Future<Map<String, List<String>>> _previewUrls;

  @override
  void initState() {
    super.initState();
    _previewUrls = GalleryApiService.fetchAllImagePreviews();
  }

  void _reloadPreviews() {
    setState(() {
      _previewUrls = GalleryApiService.fetchAllImagePreviews();
    });
  }

  void _onDivisionTap(String division) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryDivisionPage(division: division),
      ),
    );

    if (result == true) {
      _reloadPreviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        title: const Text(
          'Our Memories',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 24),
            onPressed: _reloadPreviews,
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
      body: FutureBuilder<Map<String, List<String>>>(
        future: _previewUrls,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '이미지를 불러올 수 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _reloadPreviews,
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
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '저장된 이미지가 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '첫 번째 추억을 만들어보세요!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final previewData = snapshot.data!;
          final divisions = previewData.keys.toList();

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: divisions.length,
            itemBuilder: (context, index) {
              final division = divisions[index];
              final urls = previewData[division]!;

              return GestureDetector(
                onTap: () => _onDivisionTap(division),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFDBDBDB), width: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 헤더 섹션
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                division.isNotEmpty ? division[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$division 분반',
                          style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${urls.length}개의 추억',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                          ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 이미지 미리보기 섹션
                        if (urls.isNotEmpty) ...[
                        SizedBox(
                            height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                              itemCount: urls.length > 5 ? 5 : urls.length, // 최대 5개만 보여주기
                            itemBuilder: (context, i) {
                              print('📸 Preview image URL: ${urls[i]}');
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFDBDBDB),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  urls[i],
                                      width: 120,
                                      height: 120,
                                  fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey[400],
                                            size: 40,
                                          ),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey[100],
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.grey[400],
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ),
                              );
                            },
                          ),
                        ),
                          if (urls.length > 5) ...[
                            const SizedBox(height: 12),
                            Text(
                              '외 ${urls.length - 5}개 더 보기',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
