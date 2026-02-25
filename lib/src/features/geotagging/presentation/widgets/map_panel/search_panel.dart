import 'package:flutter/material.dart';
import 'package:geotag/src/core/theme/app_colors.dart';
import 'package:geotag/src/features/geotagging/data/services/osm_geocoding_service.dart';

class MapSearchPanel extends StatelessWidget {
  const MapSearchPanel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.results,
    required this.onChanged,
    required this.onClear,
    required this.onSelect,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final List<GeocodingResult> results;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<GeocodingResult> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.location_searching, color: AppColors.brandOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Search for a place (e.g. London)',
                      border: InputBorder.none,
                    ),
                    onChanged: onChanged,
                  ),
                ),
                if (isSearching)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (controller.text.isNotEmpty)
                  IconButton(icon: const Icon(Icons.close), onPressed: onClear),
              ],
            ),
          ),
          if (results.isNotEmpty) const Divider(height: 1),
          if (results.isNotEmpty)
            SizedBox(
              height: 240,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = results[index];
                  return ListTile(
                    title: Text(
                      result.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSelect(result),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
