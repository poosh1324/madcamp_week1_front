import 'package:flutter/material.dart';
import 'package:test_madcamp/gallery/gallery_api_service.dart';
import 'gallery_division_page.dart';

class GalleryDetailPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Delete Image"),
                  content: const Text(
                    "Are you sure you want to delete this image?",
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                    TextButton(
                      child: const Text("Delete"),
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await GalleryApiService.deleteImage(imageId);
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image deleted')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          if (uploader != null || uploadedAt != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (uploader != null)
                    Text(
                      "Uploaded by: $uploader",
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (uploadedAt != null)
                    Text(
                      "Uploaded at: ${uploadedAt!.toLocal()}",
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
