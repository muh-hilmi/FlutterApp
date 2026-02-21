import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anigmaa/domain/entities/event.dart';
import 'package:anigmaa/domain/entities/event_category.dart';
import 'package:anigmaa/core/theme/app_colors.dart';
import 'package:anigmaa/core/theme/app_text_styles.dart';

class DiscoverMapView extends StatefulWidget {
  final List<Event> events;
  final LatLng userLocation;
  final Function(Event) onEventTap;
  final Completer<GoogleMapController> mapController;
  final VoidCallback? onMapReady;

  const DiscoverMapView({
    super.key,
    required this.events,
    required this.userLocation,
    required this.onEventTap,
    required this.mapController,
    this.onMapReady,
  });

  @override
  State<DiscoverMapView> createState() => _DiscoverMapViewState();
}

class _DiscoverMapViewState extends State<DiscoverMapView> {
  final Map<String, BitmapDescriptor> _markerIcons = {};
  BitmapDescriptor? _userLocationIcon;

  Event? _selectedEvent;
  List<Event>? _selectedCluster; // Non-null when a cluster (2+ events) was tapped

  @override
  void initState() {
    super.initState();
    _generateMarkerIcons();
  }

  Future<void> _generateMarkerIcons() async {
    final categories = {
      EventCategory.meetup: _createMarkerIcon(Colors.blue, '👥'),
      EventCategory.sports: _createMarkerIcon(Colors.green, '⚽'),
      EventCategory.workshop: _createMarkerIcon(Colors.orange, '🛠️'),
      EventCategory.networking: _createMarkerIcon(Colors.purple, '🤝'),
      EventCategory.food: _createMarkerIcon(Colors.red, '🍴'),
      EventCategory.creative: _createMarkerIcon(Colors.pink, '🎨'),
      EventCategory.outdoor: _createMarkerIcon(Colors.teal, '🌳'),
      EventCategory.fitness: _createMarkerIcon(Colors.lime, '💪'),
      EventCategory.learning: _createMarkerIcon(Colors.indigo, '📚'),
      EventCategory.social: _createMarkerIcon(Colors.amber, '🎉'),
    };

    for (final entry in categories.entries) {
      _markerIcons[entry.key.toString()] = await entry.value;
    }

    // Default single-event marker
    _markerIcons['default'] = await _createMarkerIcon(AppColors.secondary, '📍');

    // Pre-generate cluster icons for counts 2–9 and 9+
    for (int i = 2; i <= 9; i++) {
      _markerIcons['cluster_$i'] = await _createClusterIcon(i);
    }
    _markerIcons['cluster_max'] = await _createClusterIcon(9, isMax: true);

    // Custom user location marker
    _userLocationIcon = await _createUserLocationMarker();

    if (mounted) setState(() {});
  }

  /// Category emoji marker — 80×80 canvas, small and clean
  Future<BitmapDescriptor> _createMarkerIcon(Color color, String emoji) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const center = Offset(40, 38);
    const radius = 26.0;

    // Drop shadow
    canvas.drawCircle(
      center.translate(0, 3),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Filled circle
    canvas.drawCircle(center, radius, Paint()..color = color);

    // White border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Emoji label
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: const TextStyle(fontSize: 20)),
    )..textDirection = TextDirection.ltr;
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));

    final img = await recorder.endRecording().toImage(80, 80);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Cluster badge marker — dark circle with a count number
  Future<BitmapDescriptor> _createClusterIcon(int count, {bool isMax = false}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const center = Offset(40, 38);
    const radius = 28.0;

    // Drop shadow
    canvas.drawCircle(
      center.translate(0, 3),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Dark background
    canvas.drawCircle(center, radius, Paint()..color = AppColors.primary);

    // Lime border to make it pop
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Count label
    final label = isMax ? '9+' : '$count';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    )..textDirection = TextDirection.ltr;
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));

    final img = await recorder.endRecording().toImage(80, 80);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Custom "you are here" marker — blue circle with pulse ring
  Future<BitmapDescriptor> _createUserLocationMarker() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const center = Offset(36, 36);

    // Outer pulse glow
    canvas.drawCircle(center, 30, Paint()..color = const Color(0x334285F4));

    // Main blue circle
    canvas.drawCircle(center, 17, Paint()..color = const Color(0xFF4285F4));

    // White border
    canvas.drawCircle(
      center,
      17,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Inner white dot
    canvas.drawCircle(center, 6, Paint()..color = Colors.white);

    final img = await recorder.endRecording().toImage(72, 72);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Groups events by rounded lat/lng (~100m precision).
  /// Events at the same venue/address will share a key.
  Map<String, List<Event>> _groupEventsByLocation(List<Event> events) {
    final groups = <String, List<Event>>{};
    for (final event in events) {
      final key =
          '${event.location.latitude.toStringAsFixed(3)},'
          '${event.location.longitude.toStringAsFixed(3)}';
      groups.putIfAbsent(key, () => []).add(event);
    }
    return groups;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        pow(sin(dLon / 2), 2) *
            cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2));
    return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180.0);

  String _getDistanceFromUser(Event event) {
    final d = _calculateDistance(
      widget.userLocation.latitude,
      widget.userLocation.longitude,
      event.location.latitude,
      event.location.longitude,
    );
    return d < 1 ? '${(d * 1000).toStringAsFixed(0)}m' : '${d.toStringAsFixed(1)}km';
  }

  Future<void> _openMapForDirections(double lat, double lng) async {
    final uri = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final web = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await canLaunchUrl(web)) await launchUrl(web);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationGroups = _groupEventsByLocation(widget.events);
    final markers = <Marker>{};

    // --- User location marker ---
    if (_userLocationIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('__user_location__'),
        position: widget.userLocation,
        icon: _userLocationIcon!,
        zIndexInt: 99,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));
    }

    // --- Event markers (clustered by location) ---
    for (final entry in locationGroups.entries) {
      final events = entry.value;
      final rep = events.first;
      final position = LatLng(rep.location.latitude, rep.location.longitude);

      if (events.length == 1) {
        // Single event pin
        final icon = _markerIcons[rep.category.toString()] ??
            _markerIcons['default'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        markers.add(Marker(
          markerId: MarkerId(rep.id),
          position: position,
          icon: icon,
          onTap: () => setState(() {
            _selectedEvent = rep;
            _selectedCluster = null;
          }),
        ));
      } else {
        // Cluster pin — shows event count
        final count = events.length;
        final clusterKey = count <= 9 ? 'cluster_$count' : 'cluster_max';
        final icon = _markerIcons[clusterKey] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        markers.add(Marker(
          markerId: MarkerId('cluster__${entry.key}'),
          position: position,
          icon: icon,
          onTap: () => setState(() {
            _selectedEvent = rep;
            _selectedCluster = events;
          }),
        ));
      }
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.userLocation,
            zoom: 13.0,
          ),
          onMapCreated: (controller) {
            widget.mapController.complete(controller);
            widget.onMapReady?.call();
          },
          trafficEnabled: false,
          myLocationEnabled: false,
          myLocationButtonEnabled: false, // We have a custom FAB in discover_screen
          markers: markers,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          style: _getMapStyle(),
          onTap: (_) => setState(() {
            _selectedEvent = null;
            _selectedCluster = null;
          }),
        ),

        // --- Event / cluster preview card ---
        if (_selectedEvent != null)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildEventCard(_selectedEvent!),
          ),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
    final distance = _getDistanceFromUser(event);
    final isCluster = _selectedCluster != null && _selectedCluster!.length > 1;
    final otherEvents = isCluster
        ? _selectedCluster!.where((e) => e.id != event.id).toList()
        : <Event>[];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image header ──
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                // Event image
                Builder(builder: (context) {
                  final imageUrl = event.fullImageUrls.isNotEmpty
                      ? event.fullImageUrls.first
                      : null;
                  if (imageUrl != null) {
                    return Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    );
                  }
                  return _buildImagePlaceholder();
                }),

                // Close button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedEvent = null;
                      _selectedCluster = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),

                // Cluster badge (top-left)
                if (isCluster)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${_selectedCluster!.length} event di sini',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Distance badge (bottom-left)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Event info ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.category.displayName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.title,
                  style: AppTextStyles.h3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location.name,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(event.startTime)} · ${_formatTime(event.startTime)}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── "Other events here" cluster chips ──
          if (otherEvents.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'Event lain di lokasi ini',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: otherEvents.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final e = otherEvents[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEvent = e),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        e.title,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textEmphasis,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 12),

          // ── Action buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openMapForDirections(
                      event.location.latitude,
                      event.location.longitude,
                    ),
                    icon: const Icon(Icons.directions, color: Colors.white, size: 16),
                    label: const Text(
                      'Petunjuk Arah',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onEventTap(event),
                    icon: Icon(Icons.info_outline, color: AppColors.secondary, size: 16),
                    label: Text(
                      'Lihat Detail',
                      style: TextStyle(color: AppColors.secondary, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: AppColors.secondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      color: AppColors.surfaceAlt,
      child: Icon(Icons.event_rounded, size: 48, color: AppColors.border),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  /// Clean minimal light map style — hides POIs and transit so event pins stand out
  String _getMapStyle() {
    return '''
    [
      {"featureType":"poi","stylers":[{"visibility":"off"}]},
      {"featureType":"transit","stylers":[{"visibility":"off"}]},
      {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#ffffff"}]},
      {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e8e8e8"},{"weight":0.5}]},
      {"featureType":"road.arterial","elementType":"geometry.fill","stylers":[{"color":"#f8f8f8"}]},
      {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#f2f2f2"}]},
      {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
      {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c8e4f5"}]},
      {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]}
    ]
    ''';
  }
}
