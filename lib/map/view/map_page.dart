import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cross_platform_development/map/map.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:cross_platform_development/shared/shared.dart';

/// {@template map_page}
/// A page that displays an interactive map using OpenStreetMap.
/// {@endtemplate}
class MapPage extends StatelessWidget {
  /// {@macro map_page}
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MapView();
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
  void initState() {
    super.initState();
    // Load map events after widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapCubit>().loadMapEvents();
    });
  }

  /// Build markers with manual clustering logic
  List<Marker> _buildClusteredMarkers(
    BuildContext context,
    MapState mapState,
    TimelineState timelineState,
  ) {
    // Group events by exact coordinates
    final Map<String, List<Event>> groupedEvents = {};

    for (final event in mapState.events) {
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
              isSelected: timelineState.selectedEvent?.id == firstEvent.id,
              isHighlighted: mapState.highlightedEvent?.id == firstEvent.id,
              onTap: () {
                context.read<MapCubit>().showEventPopup(firstEvent);
              },
              onHover: () {
                context.read<MapCubit>().hoverMapEvent(firstEvent);
              },
              onHoverExit: () {
                context.read<MapCubit>().exitMapEventHover();
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
              isSelected: events.any(
                (e) => timelineState.selectedEvent?.id == e.id,
              ),
              isHighlighted: events.any(
                (e) => mapState.highlightedEvent?.id == e.id,
              ),
              onTap: () {
                context.read<MapCubit>().showClusterPopup(events);
              },
              onHover: () {
                // For clusters, don't highlight any specific timeline event
                // Just provide visual feedback on the cluster itself
              },
              onHoverExit: () {
                // No timeline highlighting to clear for clusters
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
    return BlocListener<MapCubit, MapState>(
      listener: (context, state) {
        // Center map on event when centerOnEvent is set
        if (state.centerOnEvent != null) {
          final event = state.centerOnEvent!;
          final location = LatLng(event.latitude!, event.longitude!);

          // Move map to event location with animation
          _mapController.move(
            location,
            12.0,
          ); // Zoom level 12 for detailed view

          // Immediately clear the centerOnEvent flag to allow normal map interaction
          context.read<MapCubit>().clearCenterOnEvent();
        }
      },
      child: BlocBuilder<MapCubit, MapState>(
        builder: (context, mapState) {
          return BlocBuilder<TimelineCubit, TimelineState>(
            builder: (context, timelineState) {
              return Stack(
                children: [
                  // Map
                  FlutterMap(
                    mapController: _mapController,
                    options: const MapOptions(
                      // Center on Italy/Sicily area where the volcanic events are
                      initialCenter: LatLng(
                        37.7513,
                        14.9934,
                      ), // Mount Etna coordinates
                      initialZoom: 8.0,
                      minZoom: 3.0,
                      maxZoom: 18.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.cross_platform_development',
                      ),
                      if (mapState.status == MapStatus.loaded) ...[
                        MarkerLayer(
                          markers: _buildClusteredMarkers(
                            context,
                            mapState,
                            timelineState,
                          ),
                        ),
                      ],
                      if (mapState.status == MapStatus.loading) ...[
                        const Center(child: CircularProgressIndicator()),
                      ],
                    ],
                  ),

                  // Popup overlay
                  const EventPopup(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
