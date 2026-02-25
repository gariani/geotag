import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class PhotoGridEmptyState extends StatelessWidget {
  const PhotoGridEmptyState({
    super.key,
    required this.isLoading,
    required this.onImport,
  });

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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
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
