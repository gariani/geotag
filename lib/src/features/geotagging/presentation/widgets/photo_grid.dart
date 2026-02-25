import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/photo.dart';
import '../controllers/geotagging_controller.dart';

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.controller,
    this.onSetLocationPressed,
    this.onExportCopiesPressed,
  });

  final GeotaggingController controller;
  final VoidCallback? onSetLocationPressed;
  final VoidCallback? onExportCopiesPressed;

  @override
  Widget build(BuildContext context) {
    final photos = controller.photos;
    final selectedCount = controller.selectedPhotoIds.length;
    final isMultiSelect = controller.isMultiSelectEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Static header: stays fixed at top, draws on top of list ---
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(width: 8),
                    Tooltip(
                      message: isMultiSelect ? 'Exit Bulk Edit' : 'Bulk Edit',
                      child: IconButton(
                        onPressed: photos.isEmpty
                            ? null
                            : () {
                                if (!isMultiSelect) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Bulk Edit on: tap photos to multi-select for tagging.',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                                controller.toggleMultiSelectMode();
                              },
                        icon: Icon(
                          isMultiSelect ? Icons.layers_clear : Icons.layers,
                        ),
                        color: isMultiSelect
                            ? AppColors.brandOrange
                            : Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : controller.importPhotos,
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 20,
                      ),
                      label: const Text('Import'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _PrimaryActionButton(
                        icon: Icons.add_location,
                        label: 'Set Location',
                        enabled:
                            selectedCount > 0 && onSetLocationPressed != null,
                        onPressed: onSetLocationPressed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PrimaryActionButton(
                        icon: isMultiSelect ? Icons.layers_clear : Icons.layers,
                        label: isMultiSelect ? 'Bulk Edit On' : 'Bulk Edit',
                        enabled: photos.isNotEmpty,
                        onPressed: () {
                          if (!isMultiSelect) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bulk Edit on: tap photos to multi-select for tagging.',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                          controller.toggleMultiSelectMode();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PrimaryActionButton(
                        icon: Icons.drive_folder_upload,
                        label: 'Export',
                        enabled:
                            controller.hasSelectedPhotosWithLocation &&
                            onExportCopiesPressed != null,
                        onPressed: onExportCopiesPressed,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                      isSelected:
                          controller.filter == PhotoFilter.missingLocation,
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
              const SizedBox(height: 8),
            ],
          ),
        ),
        // --- Scrollable list: only the photos; header and footer stay fixed ---
        Expanded(
          child: ClipRect(
            child: photos.isEmpty
                ? _EmptyState(
                    isLoading: controller.isLoading,
                    onImport: controller.importPhotos,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    clipBehavior: Clip.hardEdge,
                    physics: const ClampingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.15,
                        ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      final isSelected = controller.selectedPhotoIds.contains(
                        photo.id,
                      );
                      return _PhotoTile(
                        photo: photo,
                        isSelected: isSelected,
                        onTap: () => controller.togglePhotoSelection(photo.id),
                      );
                    },
                  ),
          ),
        ),
        // --- Static footer: fixed at bottom, never scrolls with the list ---
        if (selectedCount > 0)
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onSetLocationPressed,
                    icon: const Icon(Icons.add_location, size: 20),
                    label: Text('Set Location for $selectedCount selected'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
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
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text('No photos yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Import photos to start tagging locations.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isLoading ? null : onImport,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Import photos'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandOrange,
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
    final hasLocation = photo.location != null;
    final borderColor = isSelected
        ? AppColors.brandOrange
        : Colors.grey.shade300;
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
          padding: const EdgeInsets.all(8),
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
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.brandOrange,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                photo.title,
                maxLines: 1,
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
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: statusColor),
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

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = enabled ? onPressed : null;
    final color = enabled ? AppColors.brandOrange : Colors.grey.shade400;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: effectiveOnPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
                color: isSelected
                    ? AppColors.brandOrange
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 24,
                decoration: BoxDecoration(
                  color: AppColors.brandOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
