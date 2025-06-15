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

  /// Build markers with manual clustering logic
  List<Marker> _buildClusteredMarkers(BuildContext context, MapState state) {
    // Group events by exact coordinates
    final Map<String, List<Event>> groupedEvents = {};

    for (final event in state.events) {
      final key = '${event.latitude},${event.longitude}';
      groupedEvents.putIfAbsent(key, () => []).add(event);
    }

    // Create markers for each location
    final List<Marker> markers = [];

    for (final entry in groupedEvents.entries) {
      final events = entry.value;
      final firstEvent = events.first;
      final location = LatLng(firstEvent.latitude!, firstEvent.longitude!);

      if (events.length == 1) {
        // Single event - show individual marker
        markers.add(
          Marker(
            point: location,
            child: EventMarker(
              event: firstEvent,
              isSelected: state.selectedEvent?.id == firstEvent.id,
              onTap: () {
                context.read<MapCubit>().selectEvent(firstEvent);
                print('Selected event: ${firstEvent.title}');
                print('Type: ${firstEvent.type}');
              },
            ),
          ),
        );
      } else {
        // Multiple events - show cluster marker
        markers.add(
          Marker(
            point: location,
            child: ClusterMarker(
              events: events,
              isSelected: events.any((e) => state.selectedEvent?.id == e.id),
              onTap: () {
                // For now, just print cluster info
                print('Cluster with ${events.length} events:');
                for (final event in events) {
                  print('  - ${event.title} (${event.type})');
                }
              },
            ),
          ),
        );
      }
    }

    return markers;
  }

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
              MarkerLayer(markers: _buildClusteredMarkers(context, state)),
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
