import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geotag/src/core/config/map_tile_config.dart';
import 'package:geotag/src/features/geotagging/data/services/osm_geocoding_service.dart';
import 'package:geotag/src/features/geotagging/domain/entities/location_info.dart';
import 'package:geotag/src/features/geotagging/presentation/controllers/geotagging_controller.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'map_footer.dart';
import 'map_overlay_widgets.dart';
import 'search_panel.dart';

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
                  _buildMap(tileConfig, selectedLocation),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: AttributionBadge(
                      attributionText: tileConfig.attributionText,
                      onTap: () => _openAttribution(context, tileConfig),
                    ),
                  ),
                  Positioned(right: 12, bottom: 80, child: _buildMapControls()),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: MapSearchPanel(
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
            MapFooter(
              location: selectedLocation,
              hasSelection: hasSelection,
              onApply:
                  widget.onApply ?? widget.controller.applyLocationToSelection,
              onApplyAndExport:
                  widget.onApplyAndExport ??
                  widget.controller.applyLocationAndExport,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(MapTileConfig tileConfig, LocationInfo? selectedLocation) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(48.8566, 2.3522),
        initialZoom: 10,
        onTap: (tapPosition, point) {
          _searchFocus.unfocus();
          widget.controller.setLocation(
            LocationInfo(latitude: point.latitude, longitude: point.longitude),
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
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        Tooltip(
          message: 'Current location',
          child: MapControlButton(
            icon: Icons.my_location,
            onPressed: _goToCurrentLocation,
          ),
        ),
        const SizedBox(height: 4),
        MapControlButton(
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
        MapControlButton(
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
    );
  }

  Future<void> _openAttribution(
    BuildContext context,
    MapTileConfig tileConfig,
  ) async {
    final uri = Uri.parse(tileConfig.attributionUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
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

    setState(() => _isSearching = true);

    final results = await _geocodingService.search(trimmed, userAgent);
    if (!mounted) return;
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
      widget.controller.setLocation(
        LocationInfo(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
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
