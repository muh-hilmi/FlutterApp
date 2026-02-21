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
      EventCategory.meetup: _createMarkerIcon(AppColors.secondary, '👥'),
      EventCategory.sports: _createMarkerIcon(AppColors.secondary, '⚽'),
      EventCategory.workshop: _createMarkerIcon(AppColors.secondary, '🛠️'),
      EventCategory.networking: _createMarkerIcon(AppColors.secondary, '🤝'),
      EventCategory.food: _createMarkerIcon(AppColors.secondary, '🍴'),
      EventCategory.creative: _createMarkerIcon(AppColors.secondary, '🎨'),
      EventCategory.outdoor: _createMarkerIcon(AppColors.secondary, '🌳'),
      EventCategory.fitness: _createMarkerIcon(AppColors.secondary, '💪'),
      EventCategory.learning: _createMarkerIcon(AppColors.secondary, '📚'),
      EventCategory.social: _createMarkerIcon(AppColors.secondary, '🎉'),
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

        // --- Cluster list card ---
        if (_selectedCluster != null && _selectedCluster!.length > 1)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildClusterCard(_selectedCluster!),
          )
        // --- Single event preview card ---
        else if (_selectedEvent != null)
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
                        const Icon(Icons.location_on, color: AppColors.primary, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
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
                    icon: const Icon(Icons.directions, color: AppColors.primary, size: 16),
                    label: const Text(
                      'Petunjuk Arah',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.primary,
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

  Widget _buildClusterCard(List<Event> events) {
    final locationName = events.first.location.name;

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
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${events.length}',
                    style: AppTextStyles.bodyLargeBold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${events.length} Event di Lokasi Ini',
                        style: AppTextStyles.h3,
                      ),
                      Text(
                        locationName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedEvent = null;
                    _selectedCluster = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.border),

          // ── Event list ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: events.length,
              separatorBuilder: (_, __) => Divider(height: 1, thickness: 1, color: AppColors.border),
              itemBuilder: (context, i) => _buildClusterEventRow(events[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterEventRow(Event event) {
    final imageUrl = event.fullImageUrls.isNotEmpty ? event.fullImageUrls.first : null;
    final priceLabel = event.isFree ? 'Gratis' : 'Berbayar';

    return InkWell(
      onTap: () => widget.onEventTap(event),
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: AppColors.surfaceAlt,
                        child: Icon(Icons.event_rounded, size: 24, color: AppColors.border),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: AppColors.surfaceAlt,
                      child: Icon(Icons.event_rounded, size: 24, color: AppColors.border),
                    ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.category.displayName,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· $priceLabel',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(event.startTime)} · ${_formatTime(event.startTime)}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
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
