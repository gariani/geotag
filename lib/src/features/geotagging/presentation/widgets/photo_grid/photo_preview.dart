import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/entities/photo.dart';

class PhotoPreview extends StatelessWidget {
  const PhotoPreview({super.key, required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    final imagePath = photo.imagePath;
    if (imagePath == null) return _placeholder(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(context),
      ),
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
