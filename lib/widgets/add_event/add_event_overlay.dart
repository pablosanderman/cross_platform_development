import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddEventOverlay extends StatefulWidget {
  final Function(Map<String, dynamic>? eventData) onSubmitted;
  final VoidCallback onCancel;

  const AddEventOverlay({
    super.key,
    required this.onSubmitted,
    required this.onCancel,
  });

  @override
  State<AddEventOverlay> createState() => _AddEventOverlayState();
}

class _AddEventOverlayState extends State<AddEventOverlay> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(
    BuildContext context, {
    required bool isStart,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: this.context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null && mounted) {
        setState(() {
          final pickedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          if (isStart) {
            _startTime = pickedDateTime;
          } else {
            _endTime = pickedDateTime;
          }
        });
      }
    }
  }

  Future<void> _pickLocation() async {
    // Navigate to the location picker screen
    final selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );

    if (selectedLocation != null && mounted) {
      setState(() {
        _latitude = selectedLocation.latitude;
        _longitude = selectedLocation.longitude;
      });

      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Location picked: ($_latitude, $_longitude)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add Timeline Event',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Event Title'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Event Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        'Start Time: ${_startTime?.toString() ?? 'Not set'}',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () => _pickDateTime(context, isStart: true),
                    ),
                    ListTile(
                      title: Text(
                        'End Time: ${_endTime?.toString() ?? 'Not set'}',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () => _pickDateTime(context, isStart: false),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        _latitude != null && _longitude != null
                            ? 'Location: ($_latitude, $_longitude)'
                            : 'Pick Location',
                      ),
                      trailing: Icon(Icons.map),
                      onTap: _pickLocation,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: widget.onCancel,
                          child: Text('CANCEL'),
                        ),
                        ElevatedButton(
                          child: Text('ADD EVENT'),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onSubmitted({
                                'title': _titleController.text,
                                'description': _descriptionController.text
                                    .trim(),
                                'startTime': _startTime,
                                'endTime': _endTime,
                                'latitude': _latitude,
                                'longitude': _longitude,
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick a Location')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point; // Update selected location
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedLocation != null) {
                  Navigator.pop(
                    context,
                    _selectedLocation,
                  ); // Pass location back
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a location')),
                  );
                }
              },
              child: const Text('CONFIRM LOCATION'),
            ),
          ),
        ],
      ),
    );
  }
}
