import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../domain/entities/event.dart';

class DiscoverMapView extends StatefulWidget {
  final List<Event> events;
  final LatLng userLocation;
  final Function(Event) onEventTap;

  const DiscoverMapView({
    super.key,
    required this.events,
    required this.userLocation,
    required this.onEventTap,
  });

  @override
  State<DiscoverMapView> createState() => _DiscoverMapViewState();
}

class _DiscoverMapViewState extends State<DiscoverMapView> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  final double _radiusKm = 10.0;

  @override
  void dispose() {
    super.dispose();
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = (dLat * dLat) +
        (_degreesToRadians(lat1) * _degreesToRadians(lat2) * dLon * dLon).abs();
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180.0);
  }

  // Filter events within 10km radius
  List<Event> _getEventsInRadius() {
    return widget.events.where((event) {
      if (event.location.latitude == 0 && event.location.longitude == 0)
        return false;

      final distance = _calculateDistance(
        widget.userLocation.latitude,
        widget.userLocation.longitude,
        event.location.latitude,
        event.location.longitude,
      );

      return distance <= _radiusKm;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final nearbyEvents = _getEventsInRadius();

    // Create marker set from nearby events
    final Set<Marker> eventMarkers = nearbyEvents.map((event) {
      return Marker(
        markerId: MarkerId(event.id),
        position: LatLng(
          event.location.latitude,
          event.location.longitude,
        ),
        onTap: () => widget.onEventTap(event),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.userLocation,
        zoom: 12.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController.complete(controller);
      },
      trafficEnabled: false,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: eventMarkers,
      zoomControlsEnabled: true,
      compassEnabled: true,
    );
  }
}
