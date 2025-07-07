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
      appBar: AppBar(
        title: const Text('Our Memories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadPreviews,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<String>>>(
        future: _previewUrls,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('불러오기 실패: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('이미지가 없습니다.'));
          }

          final previewData = snapshot.data!;
          final divisions = previewData.keys.toList();

          return ListView.builder(
            itemCount: divisions.length,
            itemBuilder: (context, index) {
              final division = divisions[index];
              final urls = previewData[division]!;

              return GestureDetector(
                onTap: () => _onDivisionTap(division),
                child: Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Division $division',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: urls.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Image.network(
                                urls[i],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
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
