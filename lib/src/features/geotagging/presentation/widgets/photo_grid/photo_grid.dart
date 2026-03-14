import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/photo.dart';
import '../../controllers/geotagging_controller.dart';
import '../../controllers/photo_filter.dart';
import 'filter_tab.dart';
import 'photo_grid_empty_state.dart';
import 'photo_tile.dart';
import 'primary_action_button.dart';

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
        _buildHeader(context, photos, selectedCount, isMultiSelect),
        Expanded(
          child: ClipRect(
            child: photos.isEmpty
                ? PhotoGridEmptyState(
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
                      final isSelected =
                          controller.selectedPhotoIds.contains(photo.id);
                      return PhotoTile(
                        photo: photo,
                        isSelected: isSelected,
                        onTap: () => controller.togglePhotoSelection(photo.id),
                        onLongPress: () {
                          if (!controller.isMultiSelectEnabled) {
                            controller.toggleMultiSelectMode();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Multi-select: tap photos to select for tagging.',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                          controller.togglePhotoSelection(photo.id);
                        },
                      );
                    },
                  ),
          ),
        ),
        if (selectedCount > 0) _buildFooter(context, selectedCount),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<Photo> photos,
    int selectedCount,
    bool isMultiSelect,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMultiSelect) const SizedBox(height: 16),
          if (isMultiSelect)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: controller.toggleMultiSelectMode,
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          if (isMultiSelect) const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryActionButton(
                    icon: Icons.add_photo_alternate_outlined,
                    label: 'Import',
                    enabled: !controller.isLoading,
                    onPressed: controller.importPhotos,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryActionButton(
                    icon: Icons.add_location,
                    label: 'Set Location',
                    enabled: selectedCount > 0 && onSetLocationPressed != null,
                    onPressed: onSetLocationPressed,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryActionButton(
                    icon: Icons.drive_folder_upload,
                    label: 'Export',
                    enabled: controller.hasSelectedPhotosWithLocation &&
                        onExportCopiesPressed != null,
                    onPressed: onExportCopiesPressed,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilterTab(
                  label: 'All',
                  isSelected: controller.filter == PhotoFilter.all,
                  onTap: () => controller.setFilter(PhotoFilter.all),
                ),
                FilterTab(
                  label: 'Missing Location',
                  isSelected:
                      controller.filter == PhotoFilter.missingLocation,
                  onTap: () =>
                      controller.setFilter(PhotoFilter.missingLocation),
                ),
                FilterTab(
                  label: 'Recent',
                  isSelected: controller.filter == PhotoFilter.recent,
                  onTap: () => controller.setFilter(PhotoFilter.recent),
                ),
                FilterTab(
                  label: 'Has Location',
                  isSelected: controller.filter == PhotoFilter.hasLocation,
                  onTap: () => controller.setFilter(PhotoFilter.hasLocation),
                ),
                FilterTab(
                  label: 'No Exported',
                  isSelected: controller.filter == PhotoFilter.exported,
                  onTap: () => controller.setFilter(PhotoFilter.exported),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, int selectedCount) {
    return Material(
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
    );
  }
}
