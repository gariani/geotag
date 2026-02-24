import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/photo.dart';
import '../controllers/geotagging_controller.dart';

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.controller,
    this.onSetLocationPressed,
  });

  final GeotaggingController controller;
  final VoidCallback? onSetLocationPressed;

  @override
  Widget build(BuildContext context) {
    final photos = controller.photos;
    final selectedCount = controller.selectedPhotoIds.length;
    const accentColor = Color(0xFFE65100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Text(
                'Photos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.isLoading ? null : controller.importPhotos,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: const Text('Import'),
                style: TextButton.styleFrom(foregroundColor: accentColor),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _FilterTab(
                label: 'All',
                isSelected: controller.filter == PhotoFilter.all,
                onTap: () => controller.setFilter(PhotoFilter.all),
              ),
              const SizedBox(width: 16),
              _FilterTab(
                label: 'Missing Location',
                isSelected: controller.filter == PhotoFilter.missingLocation,
                onTap: () =>
                    controller.setFilter(PhotoFilter.missingLocation),
              ),
              const SizedBox(width: 16),
              _FilterTab(
                label: 'Recent',
                isSelected: controller.filter == PhotoFilter.recent,
                onTap: () => controller.setFilter(PhotoFilter.recent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: photos.isEmpty
              ? _EmptyState(
                  isLoading: controller.isLoading,
                  onImport: controller.importPhotos,
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      final isSelected =
                          controller.selectedPhotoIds.contains(photo.id);
                      return _PhotoTile(
                        photo: photo,
                        isSelected: isSelected,
                        onTap: () => controller.togglePhotoSelection(photo.id),
                      );
                    },
                  ),
                ),
        ),
        if (selectedCount > 0)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSetLocationPressed,
                icon: const Icon(Icons.place),
                label: Text('Set Location for $selectedCount selected'),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isLoading, required this.onImport});

  final bool isLoading;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No photos yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Import photos to start tagging locations.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isLoading ? null : onImport,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Import photos'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.isSelected,
    required this.onTap,
  });

  final Photo photo;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE65100);
    final hasLocation = photo.location != null;
    final borderColor = isSelected ? accentColor : Colors.grey.shade300;
    final statusColor = hasLocation ? Colors.green : Colors.amber.shade700;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    _PhotoPreview(photo: photo),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.check_circle, color: accentColor, size: 24),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                photo.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    hasLocation ? Icons.place : Icons.place_outlined,
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      hasLocation ? 'Location set' : 'No location',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    final imagePath = photo.imagePath;
    if (imagePath == null) return _placeholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.photo, size: 42, color: Colors.blueGrey.shade200),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE65100);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? accentColor : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 24,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}