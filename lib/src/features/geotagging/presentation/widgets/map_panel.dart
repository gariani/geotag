import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/map_tile_config.dart';
import '../../data/services/osm_geocoding_service.dart';
import '../../domain/entities/location_info.dart';
import '../controllers/geotagging_controller.dart';

class MapPanel extends StatefulWidget {
  const MapPanel({
    super.key,
    required this.controller,
    this.onPreFill,
    this.onApply,
    this.onApplyAndExport,
  });

  final GeotaggingController controller;
  final Future<void> Function()? onPreFill;
  final Future<void> Function()? onApply;
  final Future<void> Function()? onApplyAndExport;

  @override
  State<MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<MapPanel> {
  final MapController _mapController = MapController();
  LocationInfo? _lastCenteredLocation;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final OsmGeocodingService _geocodingService = OsmGeocodingService();
  Timer? _searchDebounce;
  List<GeocodingResult> _results = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final selectedLocation = widget.controller.selectedLocation;
    final hasSelection = widget.controller.selectedPhotoIds.isNotEmpty;
    final tileConfig = MapTileConfig.fromEnvironment();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(48.8566, 2.3522),
                      initialZoom: 10,
                      onTap: (tapPosition, point) {
                        _searchFocus.unfocus();
                        widget.controller.setLocation(
                          LocationInfo(
                            latitude: point.latitude,
                            longitude: point.longitude,
                          ),
                        );
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: tileConfig.urlTemplate,
                        userAgentPackageName: tileConfig.userAgentPackageName,
                      ),
                      if (selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                selectedLocation.latitude,
                                selectedLocation.longitude,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.place,
                                color: Colors.redAccent,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _AttributionBadge(
                      attributionText: tileConfig.attributionText,
                      onTap: () => _openAttribution(context, tileConfig),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 80,
                    child: Column(
                      children: [
                        Tooltip(
                          message: 'Current location',
                          child: _MapControlButton(
                            icon: Icons.my_location,
                            onPressed: _goToCurrentLocation,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _MapControlButton(
                          icon: Icons.add,
                          onPressed: () {
                            final zoom = _mapController.camera.zoom;
                            _mapController.move(
                              _mapController.camera.center,
                              (zoom + 1).clamp(1.0, 18.0),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        _MapControlButton(
                          icon: Icons.remove,
                          onPressed: () {
                            final zoom = _mapController.camera.zoom;
                            _mapController.move(
                              _mapController.camera.center,
                              (zoom - 1).clamp(1.0, 18.0),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: _SearchPanel(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      isSearching: _isSearching,
                      results: _results,
                      onChanged: (value) => _onSearchChanged(value, tileConfig),
                      onClear: _clearSearch,
                      onSelect: _selectResult,
                    ),
                  ),
                ],
              ),
            ),
            _MapFooter(
              location: selectedLocation,
              hasSelection: hasSelection,
              onApply: widget.onApply ?? widget.controller.applyLocationToSelection,
              onApplyAndExport:
                  widget.onApplyAndExport ?? widget.controller.applyLocationAndExport,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttribution(
    BuildContext context,
    MapTileConfig tileConfig,
  ) async {
    final uri = Uri.parse(tileConfig.attributionUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open attribution page')),
      );
    }
  }

  void _onSearchChanged(String value, MapTileConfig tileConfig) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch(value, tileConfig.userAgentPackageName);
    });
  }

  Future<void> _performSearch(String value, String userAgent) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _geocodingService.search(trimmed, userAgent);
    if (!mounted) {
      return;
    }
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  void _selectResult(GeocodingResult result) {
    _searchFocus.unfocus();
    setState(() {
      _results = [];
      _searchController.text = result.displayName;
    });

    final location = LocationInfo(
      latitude: result.latitude,
      longitude: result.longitude,
      label: result.displayName,
    );
    _lastCenteredLocation = location;
    widget.controller.setLocation(location);
    _mapController.move(LatLng(result.latitude, result.longitude), 13);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _results = [];
      _isSearching = false;
    });
  }

  Future<void> _goToCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      _mapController.move(point, 14);
      widget.controller.setLocation(LocationInfo(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant MapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final loc = widget.controller.selectedLocation;
    if (loc != null && loc != _lastCenteredLocation) {
      _lastCenteredLocation = loc;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(LatLng(loc.latitude, loc.longitude), 13);
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}

class _MapFooter extends StatelessWidget {
  const _MapFooter({
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
          if (location?.label != null && location!.label!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              location!.label!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
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

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _AttributionBadge extends StatelessWidget {
  const _AttributionBadge({required this.attributionText, required this.onTap});

  final String attributionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            attributionText,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
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
