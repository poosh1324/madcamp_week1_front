import 'package:flutter/material.dart';

class GalleryDetailPage extends StatelessWidget {
  final String imageUrl;
  final String? uploader;
  final DateTime? uploadedAt;

  const GalleryDetailPage({
    Key? key,
    required this.imageUrl,
    this.uploader,
    this.uploadedAt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Detail')),
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
