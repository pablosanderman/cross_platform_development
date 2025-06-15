import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// {@template map_page}
/// A page that displays an interactive map using OpenStreetMap.
/// {@endtemplate}
class MapPage extends StatefulWidget {
  /// {@macro map_page}
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        // Center on Italy/Sicily area where the volcanic events are
        initialCenter: LatLng(37.7513, 14.9934), // Mount Etna coordinates
        initialZoom: 8.0,
        minZoom: 3.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.cross_platform_development',
        ),
      ],
    );
  }
}
