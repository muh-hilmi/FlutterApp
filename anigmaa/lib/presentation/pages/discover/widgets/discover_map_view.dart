import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anigmaa/domain/entities/event.dart';
import 'package:anigmaa/domain/entities/event_category.dart';
import 'package:anigmaa/core/theme/app_colors.dart';

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
  Event? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _generateMarkerIcons();
  }

  Future<void> _generateMarkerIcons() async {
    // Custom marker icons for each category
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

    for (var entry in categories.entries) {
      final icon = await entry.value;
      _markerIcons[entry.key.toString()] = icon;
    }

    // Default marker
    _markerIcons['default'] = await _createMarkerIcon(AppColors.secondary, '📍');

    setState(() {});
  }

  Future<BitmapDescriptor> _createMarkerIcon(Color color, String emoji) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;

    // Larger circle background
    canvas.drawCircle(const Offset(45, 45), 42, paint);

    // White border - thicker
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(const Offset(45, 45), 42, borderPaint);

    // Shadow effect
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(45, 45), 42, shadowPaint);

    // Larger emoji
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 36),
      ),
    )..textDirection = TextDirection.ltr;
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        45 - textPainter.width / 2,
        45 - textPainter.height / 2,
      ),
    );

    // Larger image size
    final image = await pictureRecorder.endRecording().toImage(180, 180);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = pow(sin(dLat / 2), 2) +
        pow(sin(dLon / 2), 2) * cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  String _getDistanceFromUser(Event event) {
    final distance = _calculateDistance(
      widget.userLocation.latitude,
      widget.userLocation.longitude,
      event.location.latitude,
      event.location.longitude,
    );

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }

  // Function to open external map for directions
  Future<void> _openMapForDirections(double lat, double lng) async {
    final uri = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback for when the Google Maps app is not installed
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri);
      } else {
        throw 'Could not launch map for $lat,$lng';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = widget.events.map((event) {
      final categoryKey = event.category.toString();
      final icon = _markerIcons[categoryKey] ?? _markerIcons['default'];

      return Marker(
        markerId: MarkerId(event.id),
        position: LatLng(event.location.latitude, event.location.longitude),
        onTap: () {
          setState(() {
            _selectedEvent = event;
          });
        },
        icon: icon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
    }).toSet();

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.userLocation,
            zoom: 13.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            widget.mapController.complete(controller);
            widget.onMapReady?.call();
          },
          trafficEnabled: false,
          myLocationEnabled: false, // Disable blue dot
          myLocationButtonEnabled: true, // Keep button for recentering
          markers: markers,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          style: _getMapStyle(),
        ),

        // Event preview card
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                Image.network(
                  (event.imageUrl?.isNotEmpty ?? false)
                      ? event.imageUrl!
                      : 'https://via.placeholder.com/400x200',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      color: AppColors.divider,
                      child: Icon(Icons.event, size: 48, color: AppColors.border),
                    );
                  },
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEvent = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          distance,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.category.displayName,
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(event.startTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(event.startTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openMapForDirections(
                            event.location.latitude, event.location.longitude),
                        icon: const Icon(Icons.directions, color: Colors.white),
                        label: const Text(
                          'Get Directions',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                        icon: Icon(Icons.info_outline, color: AppColors.secondary),
                        label: Text(
                          'View Details',
                          style: TextStyle(color: AppColors.secondary),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.secondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getMapStyle() {
    return '''
    [
      {
        "featureType": "all",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#242f3e"
          }
        ]
      },
      {
        "featureType": "all",
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "lightness": -80
          }
        ]
      },
      {
        "featureType": "all",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#746855"
          }
        ]
      },
      {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#d59563"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#d59563"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#263c3f"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#6b9a76"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry.fill",
        "stylers": [
          {
            "color": "#38414e"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#98a0b0"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#17263c"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#515c6d"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "lightness": -20
          }
        ]
      }
    ]
    ''';
  }
}
