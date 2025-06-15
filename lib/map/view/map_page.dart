import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cross_platform_development/map/map.dart';
import 'package:cross_platform_development/shared/shared.dart';

/// {@template map_page}
/// A page that displays an interactive map using OpenStreetMap.
/// {@endtemplate}
class MapPage extends StatelessWidget {
  /// {@macro map_page}
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MapCubit()..loadMapEvents(),
      child: const MapView(),
    );
  }
}

/// {@template map_view}
/// The main map view widget that displays the map and markers.
/// {@endtemplate}
class MapView extends StatefulWidget {
  /// {@macro map_view}
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapCubit, MapState>(
      builder: (context, state) {
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
            if (state.status == MapStatus.loaded) ...[
              MarkerLayer(
                markers: state.events.map((event) {
                  return Marker(
                    point: LatLng(event.latitude!, event.longitude!),
                    child: EventMarker(
                      event: event,
                      isSelected: state.selectedEvent?.id == event.id,
                      onTap: () {
                        context.read<MapCubit>().selectEvent(event);
                        // Print event info to console for now
                        print('Selected event: ${event.title}');
                        print('Type: ${event.type}');
                        print(
                          'Coordinates: ${event.latitude}, ${event.longitude}',
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
            if (state.status == MapStatus.loading) ...[
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        );
      },
    );
  }
}
