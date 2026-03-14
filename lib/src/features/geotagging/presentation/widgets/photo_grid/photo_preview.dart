import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/services/raw_thumbnail_service.dart';
import '../../../domain/entities/photo.dart';

/// Thumbnail size for grid – decode at this resolution to reduce memory.
/// Grid tiles are ~1/3 screen width; 300px covers typical density.
const int _thumbnailSize = 300;

class PhotoPreview extends StatelessWidget {
  const PhotoPreview({super.key, required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    final imagePath = photo.imagePath;
    if (imagePath == null) return _placeholder(context);

    return FutureBuilder<String?>(
      key: ValueKey(imagePath),
      future: RawThumbnailService.instance.getThumbnailPath(imagePath),
      builder: (context, snapshot) {
        final path = snapshot.hasData && snapshot.data != null
            ? snapshot.data!
            : imagePath;
        if (snapshot.connectionState == ConnectionState.waiting &&
            RawThumbnailService.instance.isRawFile(imagePath)) {
          return _placeholder(context);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: _thumbnailSize,
            cacheHeight: _thumbnailSize,
            errorBuilder: (_, __, ___) => _placeholder(context),
          ),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.photo, size: 42, color: Colors.blueGrey.shade200),
      ),
    );
  }
}
