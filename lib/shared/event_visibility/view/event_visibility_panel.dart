import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../cubit/event_visibility_cubit.dart';

/// {@template event_visibility_panel}
/// An overlay panel that shows a searchable list of events with visibility toggles.
/// {@endtemplate}
class EventVisibilityPanel extends StatefulWidget {
  /// {@macro event_visibility_panel}
  const EventVisibilityPanel({super.key});

  @override
  State<EventVisibilityPanel> createState() => _EventVisibilityPanelState();
}

class _EventVisibilityPanelState extends State<EventVisibilityPanel> {
  final TextEditingController _searchController = TextEditingController();
  final EventsRepository _eventsRepository = const EventsRepository();
  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _eventsRepository.loadEvents();
      setState(() {
        _allEvents = events;
        _filteredEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEvents = _allEvents;
      } else {
        _filteredEvents = _allEvents
            .where((event) => event.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close panel when tapping outside
        context.read<EventVisibilityCubit>().closePanel();
      },
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned(
              top: 80,
              right: 16,
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping on the panel
                child: _buildPanel(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.6;

    return Container(
      width: 300,
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search events…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          // Event list
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _filteredEvents.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No events found'),
                        ),
                      )
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 48.0 * 10, // Show up to 10 rows
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _filteredEvents.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                          itemBuilder: (context, index) {
                            final event = _filteredEvents[index];
                            return _EventRow(event: event);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// A single event row in the visibility panel
class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventVisibilityCubit, EventVisibilityState>(
      builder: (context, state) {
        final isHidden = state.hiddenIds.contains(event.id);
        
        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Event title
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Visibility toggle button
              IconButton(
                onPressed: () {
                  context.read<EventVisibilityCubit>().toggle(event.id);
                },
                icon: Icon(
                  isHidden ? Icons.visibility_off : Icons.visibility,
                  color: isHidden ? Colors.grey : Colors.blue,
                ),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
    );
  }
}