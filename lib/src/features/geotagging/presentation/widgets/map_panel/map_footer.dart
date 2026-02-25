import 'package:flutter/material.dart';
import 'package:geotag/src/core/theme/app_colors.dart';
import 'package:geotag/src/features/geotagging/domain/entities/location_info.dart';

class MapFooter extends StatelessWidget {
  const MapFooter({
    super.key,
    required this.location,
    required this.hasSelection,
    required this.onApply,
    required this.onApplyAndExport,
  });

  final LocationInfo? location;
  final bool hasSelection;
  final Future<void> Function() onApply;
  final Future<void> Function() onApplyAndExport;

  static const _accentColor = AppColors.brandOrange;

  @override
  Widget build(BuildContext context) {
    final locationText = location == null
        ? 'Tap the map or search to set a pin'
        : '${_formatDms(location!.latitude, isLatitude: true)}, '
              '${_formatDms(location!.longitude, isLatitude: false)}';

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT PIN LOCATION',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            locationText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
          ),
          if (location?.label != null && location!.label!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              location!.label!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasSelection && location != null ? onApply : null,
              icon: const Icon(Icons.add_location, size: 20),
              label: const Text('Apply to Selected'),
              style: FilledButton.styleFrom(
                backgroundColor: _accentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasSelection && location != null
                  ? onApplyAndExport
                  : null,
              icon: const Icon(Icons.drive_folder_upload, size: 20),
              label: const Text('Apply & Export Copies'),
              style: FilledButton.styleFrom(
                backgroundColor: _accentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDms(double value, {required bool isLatitude}) {
    final absolute = value.abs();
    final degrees = absolute.floor();
    final minutesFull = (absolute - degrees) * 60;
    final minutes = minutesFull.floor();
    final seconds = (minutesFull - minutes) * 60;
    final direction = isLatitude
        ? (value >= 0 ? 'N' : 'S')
        : (value >= 0 ? 'E' : 'W');
    final secondsText = seconds.toStringAsFixed(2).padLeft(5, '0');
    return '$degrees° $minutes\' $secondsText" $direction';
  }
}
