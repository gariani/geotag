import 'package:flutter/material.dart';
import '../controllers/geotagging_controller.dart';
import '../widgets/map_panel.dart';
import '../widgets/photo_grid.dart';

class GeotaggingPage extends StatelessWidget {
  const GeotaggingPage({
    super.key,
    required this.controller,
  });

  final GeotaggingController controller;

  void _openMapBottomSheet(BuildContext context) {
    final scaffoldContext = context;
    controller.prefillLocationFromSelection();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapBottomSheet(
        controller: controller,
        onApply: () async {
          final savePath = await controller.applyLocationToSelection();
          if (!scaffoldContext.mounted) return;
          Navigator.of(scaffoldContext).pop();
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Text(
                savePath != null
                    ? 'Saved to $savePath'
                    : 'Location applied to selected photos',
              ),
            ),
          );
        },
        onApplyAndExport: () async {
          await controller.applyLocationAndExport();
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final scaffoldContext = context;
            return PhotoGrid(
              controller: controller,
              onSetLocationPressed: () => _openMapBottomSheet(context),
              onExportCopiesPressed: () async {
                final result =
                    await controller.exportPhotosWithExistingLocation();
                if (!scaffoldContext.mounted) return;
                switch (result) {
                  case ExportPhotosSuccess(:final path):
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(content: Text('Exported to $path')),
                    );
                  case ExportPhotosNoLocation():
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No selected photos have location set',
                        ),
                      ),
                    );
                  case ExportPhotosCancelled():
                    break;
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _MapBottomSheet extends StatelessWidget {
  const _MapBottomSheet({
    required this.controller,
    required this.onApply,
    required this.onApplyAndExport,
  });

  final GeotaggingController controller;
  final Future<void> Function() onApply;
  final Future<void> Function() onApplyAndExport;

  static const _sheetRadius = 20.0;
  static const _dragHandleWidth = 40.0;
  static const _dragHandleHeight = 4.0;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = screenHeight * 0.55;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      snap: true,
      snapSizes: const [0.42, 0.72, 0.94],
      snapAnimationDuration: const Duration(milliseconds: 200),
      shouldCloseOnMinExtent: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(_sheetRadius)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: _dragHandleWidth,
                  height: _dragHandleHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Set location for ${controller.selectedPhotoIds.length} selected',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ) ?? const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(
                  height: mapHeight,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    child: ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) => MapPanel(
                        controller: controller,
                        onPreFill: controller.prefillLocationFromSelection,
                        onApply: onApply,
                        onApplyAndExport: onApplyAndExport,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
