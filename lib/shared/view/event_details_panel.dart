import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/shared/models/models.dart';
import 'package:cross_platform_development/shared/repositories/repositories.dart';
import 'package:cross_platform_development/navigation/navigation.dart';
import 'package:cross_platform_development/comparison/comparison.dart';

/// {@template event_details_panel}
/// Comprehensive event details panel with discussion functionality
/// {@endtemplate}
class EventDetailsPanel extends StatefulWidget {
  /// {@macro event_details_panel}
  const EventDetailsPanel({super.key});

  @override
  State<EventDetailsPanel> createState() => _EventDetailsPanelState();
}

class _EventDetailsPanelState extends State<EventDetailsPanel> {
  final UsersRepository _usersRepository = const UsersRepository();
  final GroupsRepository _groupsRepository = const GroupsRepository();
  
  EventV2? _event;
  List<User> _users = [];
  List<Group> _groups = [];
  bool _isLoading = true;
  String? _error;
  
  // State for managing reply visibility and inline reply fields
  final Map<String, bool> _repliesVisible = {};
  final Map<String, bool> _showReplyField = {};
  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, FocusNode> _replyFocusNodes = {};
  
  // Main comment composer controller
  final TextEditingController _mainComposerController = TextEditingController();
  final FocusNode _mainComposerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _replyFocusNodes.values) {
      focusNode.dispose();
    }
    _mainComposerController.dispose();
    _mainComposerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load supporting data
      final users = await _usersRepository.loadUsers();
      final groups = await _groupsRepository.loadGroups();

      setState(() {
        _users = users;
        _groups = groups;
      });

      // Load event data when navigation state changes
      _loadEventData();
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEventData() async {
    final navState = context.read<NavigationBloc>().state;
    final selectedEvent = navState.selectedEventForDetails;
    
    if (selectedEvent == null) {
      setState(() {
        _event = null;
        _isLoading = false;
      });
      return;
    }

    try {
      // Convert the old Event to EventV2 on the fly
      final eventV2 = _convertEventToV2(selectedEvent);
      
      setState(() {
        _event = eventV2;
        _isLoading = false;
        // Initialize reply visibility state
        for (final message in eventV2.topLevelMessages) {
          final replies = eventV2.getRepliesTo(message.id);
          if (replies.isNotEmpty) {
            _repliesVisible[message.id] = false; // Start collapsed
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load event: $e';
        _isLoading = false;
      });
    }
  }

  EventV2 _convertEventToV2(Event oldEvent) {
    // Convert old Event model to new EventV2 model
    return EventV2(
      id: oldEvent.id,
      title: oldEvent.title,
      type: oldEvent.type.name,
      location: EventLocation(
        name: _extractLocationName(oldEvent),
        lat: oldEvent.latitude,
        lng: oldEvent.longitude,
      ),
      description: oldEvent.displayDescription,
      dateRange: EventDateRange(
        start: oldEvent.effectiveStartTime,
        end: oldEvent.effectiveEndTime,
      ),
      uniqueData: _extractUniqueData(oldEvent),
      attachments: _generateSampleAttachments(oldEvent),
      discussion: _generateSampleDiscussion(oldEvent),
    );
  }

  String _extractLocationName(Event oldEvent) {
    if (oldEvent.properties != null) {
      final location = oldEvent.properties!['location']?.toString();
      final region = oldEvent.properties!['region']?.toString();
      
      if (location != null && region != null) {
        return '$location, $region';
      } else if (location != null) {
        return location;
      } else if (region != null) {
        return region;
      }
    }
    return 'Unknown Location';
  }

  Map<String, dynamic> _extractUniqueData(Event oldEvent) {
    final uniqueData = <String, dynamic>{};
    
    // Add properties if they exist
    if (oldEvent.properties != null) {
      uniqueData.addAll(oldEvent.properties!);
    }
    
    // Add aggregate data if it exists
    if (oldEvent.aggregateData != null) {
      uniqueData['aggregateData'] = oldEvent.aggregateData!;
    }
    
    // Add members data for grouped events
    if (oldEvent.members != null) {
      uniqueData['members'] = oldEvent.members!.map((m) => {
        'id': m.id,
        'timestamp': m.timestamp.toIso8601String(),
        ...m.data,
      }).toList();
    }
    
    return uniqueData;
  }

  List<EventAttachment> _generateSampleAttachments(Event oldEvent) {
    final attachments = <EventAttachment>[];
    
    // Generate sample attachments based on event type and properties
    switch (oldEvent.type) {
      case EventType.point:
        if (oldEvent.properties?.containsKey('magnitude') == true) {
          attachments.add(EventAttachment(
            id: '${oldEvent.id}_seismic_data',
            file: 'seismic_readings.png',
            mime: 'image/png',
            label: 'Seismic readings chart',
          ));
        }
        if (oldEvent.properties?.containsKey('ashHeightKm') == true) {
          attachments.add(EventAttachment(
            id: '${oldEvent.id}_ash_plume',
            file: 'ash_plume_satellite.jpg',
            mime: 'image/jpeg',
            label: 'Satellite ash plume image',
          ));
        }
        break;
        
      case EventType.period:
        attachments.add(EventAttachment(
          id: '${oldEvent.id}_timeline_chart',
          file: 'activity_timeline.png',
          mime: 'image/png',
          label: 'Activity timeline',
        ));
        if (oldEvent.properties?.containsKey('so2FluxTonsPerDay') == true) {
          attachments.add(EventAttachment(
            id: '${oldEvent.id}_gas_report',
            file: 'gas_emission_report.pdf',
            mime: 'application/pdf',
            label: 'Gas emission analysis',
          ));
        }
        break;
        
      case EventType.grouped:
        attachments.add(EventAttachment(
          id: '${oldEvent.id}_cluster_analysis',
          file: 'cluster_analysis.pdf',
          mime: 'application/pdf',
          label: 'Cluster analysis report',
        ));
        break;
    }
    
    return attachments;
  }

  List<DiscussionMessage> _generateSampleDiscussion(Event oldEvent) {
    final discussions = <DiscussionMessage>[];
    final now = DateTime.now();
    
    // Generate realistic discussion based on event type and properties
    switch (oldEvent.type) {
      case EventType.point:
        if (oldEvent.properties?.containsKey('magnitude') == true) {
          final magnitude = oldEvent.properties!['magnitude'];
          discussions.add(DiscussionMessage(
            id: '${oldEvent.id}_msg_001',
            author: 'u_dr_rossi',
            timestamp: now.subtract(const Duration(hours: 4)),
            body: 'M $magnitude event detected. Depth and location suggest volcanic-tectonic origin. Recommend continued monitoring.',
            replyTo: null,
            attachments: [],
          ));
          
          discussions.add(DiscussionMessage(
            id: '${oldEvent.id}_msg_002',
            author: 'u_dr_bianchi',
            timestamp: now.subtract(const Duration(hours: 2)),
            body: 'Agreed. The waveform characteristics match previous pre-eruptive sequences.',
            replyTo: '${oldEvent.id}_msg_001',
            attachments: [],
          ));
        }
        break;
        
      case EventType.period:
        discussions.add(DiscussionMessage(
          id: '${oldEvent.id}_msg_001',
          author: 'u_prof_ferrari',
          timestamp: now.subtract(const Duration(hours: 6)),
          body: 'Extended period of activity observed. All monitoring parameters show sustained elevation.',
          replyTo: null,
          attachments: [],
        ));
        
        if (oldEvent.properties?.containsKey('so2FluxTonsPerDay') == true) {
          discussions.add(DiscussionMessage(
            id: '${oldEvent.id}_msg_002',
            author: 'u_dr_moretti',
            timestamp: now.subtract(const Duration(hours: 3)),
            body: 'SO₂ flux measurements confirm significant degassing. Wind conditions are dispersing emissions safely offshore.',
            replyTo: '${oldEvent.id}_msg_001',
            attachments: ['${oldEvent.id}_gas_report'],
          ));
        }
        break;
        
      case EventType.grouped:
        discussions.add(DiscussionMessage(
          id: '${oldEvent.id}_msg_001',
          author: 'u_dr_moretti',
          timestamp: now.subtract(const Duration(hours: 8)),
          body: 'Swarm pattern analysis shows clustering consistent with magma intrusion. Depth distribution suggests common source.',
          replyTo: null,
          attachments: ['${oldEvent.id}_cluster_analysis'],
        ));
        
        discussions.add(DiscussionMessage(
          id: '${oldEvent.id}_msg_002',
          author: 'u_dr_rossi',
          timestamp: now.subtract(const Duration(hours: 5)),
          body: 'Migration pattern indicates possible dyke propagation. Should we deploy additional temporary stations?',
          replyTo: '${oldEvent.id}_msg_001',
          attachments: [],
        ));
        
        discussions.add(DiscussionMessage(
          id: '${oldEvent.id}_msg_003',
          author: 'u_prof_ferrari',
          timestamp: now.subtract(const Duration(hours: 1)),
          body: 'Yes, recommend deployment of 3 additional seismometers in the affected sector for better location accuracy.',
          replyTo: '${oldEvent.id}_msg_002',
          attachments: [],
        ));
        break;
    }
    
    return discussions;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationBloc, NavigationState>(
      listener: (context, state) {
        final currentEventId = state.selectedEventForDetails?.id;
        if (currentEventId != _event?.id) {
          _loadEventData();
        }
      },
      child: Container(
        color: Colors.white,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_event == null) {
      return const Center(
        child: Text(
          'Select an event to view details',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildUniqueDataSection(),
              const SizedBox(height: 24),
              _buildAttachmentsAndActionsSection(),
              const SizedBox(height: 32),
              _buildDiscussionPanel(),
            ],
          ),
        ),
        // Close button in upper-right corner
        Positioned(
          top: 16,
          right: 16,
          child: _buildCloseButton(),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () {
          context.read<NavigationBloc>().add(CloseEventDetails());
        },
        icon: const Icon(
          Icons.close,
          color: Color(0xFF6B7280),
          size: 20,
        ),
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with timeline bar next to it
        Row(
          children: [
            Expanded(
              child: Text(
                _event!.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Mini timeline bar next to title
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 120,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6E8EF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF63656E),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Expanded(flex: 7, child: Container()),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDurationLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              _event!.location.name,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            _buildTypeChip(),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _event!.description,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF374151),
            height: 1.5,
          ),
        ),
      ],
    );
  }



  String _getDurationLabel() {
    if (_event!.dateRange.end != null) {
      final duration = _event!.dateRange.end!.difference(_event!.dateRange.start);
      if (duration.inDays > 0) {
        return '${duration.inDays} d';
      } else if (duration.inHours > 0) {
        return '${duration.inHours} h';
      } else {
        return '${duration.inMinutes} m';
      }
    }
    return 'Point Event';
  }

  Widget _buildTypeChip() {
    final colors = {
      'point': Colors.blue,
      'period': Colors.green,
      'grouped': Colors.purple,
    };
    
    final color = colors[_event!.type] ?? Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _event!.type.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color.shade700,
        ),
      ),
    );
  }

  Widget _buildUniqueDataSection() {
    if (_event!.uniqueData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Data',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: _event!.uniqueData.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        _formatKey(entry.key),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatValue(entry.value),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsAndActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_event!.attachments.isNotEmpty) ...[
          Text(
            'Attachments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Attachments with action buttons aligned to bottom-right
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_event!.attachments.isNotEmpty) ...[
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _event!.attachments.map((attachment) {
                    return _buildAttachmentCard(attachment);
                  }).toList(),
                ),
              ),
              const SizedBox(width: 16),
            ],
            // Action buttons aligned to bottom-right of attachments
            _buildActionButtons(),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentCard(EventAttachment attachment) {
    return Container(
      width: 120,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getAttachmentIcon(attachment),
            size: 32,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              attachment.label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Close event details and focus on the source view
            final navBloc = context.read<NavigationBloc>();
            final currentSource = navBloc.state.detailsSource;
            navBloc.add(CloseEventDetails());
            
            // Focus on the appropriate view
            if (currentSource == EventDetailsSource.timeline) {
              navBloc.add(ShowTimeline());
            } else {
              navBloc.add(ShowMap());
            }
          },
          icon: const Icon(Icons.map, size: 16),
          label: const Text('View on Timeline'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {
            // Use real comparison logic from the codebase - removed snackbar
            final navState = context.read<NavigationBloc>().state;
            final selectedEvent = navState.selectedEventForDetails;
            if (selectedEvent != null) {
              final comparisonBloc = context.read<ComparisonBloc>();
              final state = comparisonBloc.state;

              if (!state.isEventInComparison(selectedEvent.id) && !state.isAtMaxCapacity) {
                comparisonBloc.add(AddEventToComparison(selectedEvent));
              }
            }
          },
          icon: const Icon(Icons.compare_arrows, size: 16),
          label: const Text('Add to Compare'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4A4D52),
            side: const BorderSide(color: Color(0xFF4A4D52)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscussionPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discussion',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        ..._buildDiscussionMessages(),
        const SizedBox(height: 16),
        _buildNewMessageComposer(),
      ],
    );
  }

  List<Widget> _buildDiscussionMessages() {
    final topLevelMessages = _event!.topLevelMessages;
    final widgets = <Widget>[];

    for (int i = 0; i < topLevelMessages.length; i++) {
      final message = topLevelMessages[i];
      widgets.add(_buildMessageCard(message));
      
      // Add replies section if there are replies
      final replies = _event!.getRepliesTo(message.id);
      if (replies.isNotEmpty) {
        widgets.add(_buildRepliesSection(message.id, replies));
      }
      
      // Add spacing between message threads
      if (i < topLevelMessages.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }

  Widget _buildRepliesSection(String parentMessageId, List<DiscussionMessage> replies) {
    final isVisible = _repliesVisible[parentMessageId] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Replies toggle button
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _repliesVisible[parentMessageId] = !isVisible;
              });
            },
            child: Text(
              isVisible 
                ? 'Hide replies' 
                : 'View replies (${replies.length})',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        
        // Replies content (visible when expanded)
        if (isVisible) ...[
          const SizedBox(height: 8),
          ...replies.map((reply) => _buildReplyCard(reply)),
          
          // Inline reply field for this thread
          _buildInlineReplyField(parentMessageId),
        ],
      ],
    );
  }

  Widget _buildInlineReplyField(String parentMessageId) {
    final showField = _showReplyField[parentMessageId] ?? false;
    
    if (!showField) {
      return Padding(
        padding: const EdgeInsets.only(left: 40, top: 8),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showReplyField[parentMessageId] = true;
            });
            // Create controller and focus node if they don't exist
            if (!_replyControllers.containsKey(parentMessageId)) {
              _replyControllers[parentMessageId] = TextEditingController();
              _replyFocusNodes[parentMessageId] = FocusNode();
            }
            // Pre-fill with @mention and focus
            final parentMessage = _event!.discussion.firstWhere((m) => m.id == parentMessageId);
            final parentAuthor = _users.firstWhere(
              (u) => u.id == parentMessage.author,
              orElse: () => User(id: parentMessage.author, displayName: 'Unknown User', avatar: '', groups: []),
            );
            _replyControllers[parentMessageId]!.text = '@${parentAuthor.id} ';
            _replyControllers[parentMessageId]!.selection = TextSelection.fromPosition(
              TextPosition(offset: _replyControllers[parentMessageId]!.text.length),
            );
            _replyFocusNodes[parentMessageId]!.requestFocus();
          },
          child: Text(
            'Reply...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(left: 40, top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _replyControllers[parentMessageId],
            focusNode: _replyFocusNodes[parentMessageId],
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Write a reply...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showReplyField[parentMessageId] = false;
                    _replyControllers[parentMessageId]?.clear();
                  });
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement actual reply posting
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reply posting feature coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  setState(() {
                    _showReplyField[parentMessageId] = false;
                    _replyControllers[parentMessageId]?.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Reply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(DiscussionMessage message) {
    final user = _users.firstWhere(
      (u) => u.id == message.author,
      orElse: () => User(
        id: message.author,
        displayName: 'Unknown User',
        avatar: '/avatars/default.png',
        groups: [],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade400,
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0] : '?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // @username format instead of friendly display name
                    Text(
                      '@${user.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      _formatRelativeTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Reduced from 12 to tighten layout
          Text(
            message.body,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
          if (message.attachments.isNotEmpty) ...[
            const SizedBox(height: 8), // Reduced from 12 to tighten layout
            _buildMessageAttachments(message.attachments),
          ],
          const SizedBox(height: 8),
          // Reply button for main comment
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showReplyField[message.id] = true;
                  // Initialize if needed
                  if (!_replyControllers.containsKey(message.id)) {
                    _replyControllers[message.id] = TextEditingController();
                    _replyFocusNodes[message.id] = FocusNode();
                  }
                  // Pre-fill with @mention
                  final author = _users.firstWhere(
                    (u) => u.id == message.author,
                    orElse: () => User(id: message.author, displayName: 'Unknown User', avatar: '', groups: []),
                  );
                  _replyControllers[message.id]!.text = '@${author.id} ';
                  _replyControllers[message.id]!.selection = TextSelection.fromPosition(
                    TextPosition(offset: _replyControllers[message.id]!.text.length),
                  );
                  _replyFocusNodes[message.id]!.requestFocus();
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Reply',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(DiscussionMessage reply) {
    final user = _users.firstWhere(
      (u) => u.id == reply.author,
      orElse: () => User(
        id: reply.author,
        displayName: 'Unknown User',
        avatar: '/avatars/default.png',
        groups: [],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(left: 24, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 1,
            height: 60,
            color: const Color(0xFFC8CCD4),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey.shade400,
                        child: Text(
                          user.displayName.isNotEmpty ? user.displayName[0] : '?',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '@${user.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatRelativeTime(reply.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6), // Reduced from 8 to tighten layout
                  // Render reply body with @mention highlighting
                  _buildReplyBodyWithMentions(reply.body),
                  const SizedBox(height: 6),
                  // Reply button for reply comment
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        // Use the top-level message ID for the reply field
                        final parentId = reply.replyTo ?? reply.id;
                        setState(() {
                          _showReplyField[parentId] = true;
                          // Initialize if needed
                          if (!_replyControllers.containsKey(parentId)) {
                            _replyControllers[parentId] = TextEditingController();
                            _replyFocusNodes[parentId] = FocusNode();
                          }
                          // Pre-fill with @mention to the reply author
                          final replyAuthor = _users.firstWhere(
                            (u) => u.id == reply.author,
                            orElse: () => User(id: reply.author, displayName: 'Unknown User', avatar: '', groups: []),
                          );
                          _replyControllers[parentId]!.text = '@${replyAuthor.id} ';
                          _replyControllers[parentId]!.selection = TextSelection.fromPosition(
                            TextPosition(offset: _replyControllers[parentId]!.text.length),
                          );
                          _replyFocusNodes[parentId]!.requestFocus();
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBodyWithMentions(String body) {
    final mentionRegex = RegExp(r'@([a-zA-Z0-9_]+(?:\s+[a-zA-Z0-9_]+)*)');
    final matches = mentionRegex.allMatches(body);
    
    if (matches.isEmpty) {
      return Text(
        body,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF374151),
          height: 1.4,
        ),
      );
    }
    
    final spans = <TextSpan>[];
    int lastEnd = 0;
    
    for (final match in matches) {
      // Add text before the mention
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: body.substring(lastEnd, match.start),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF374151),
          ),
        ));
      }
      
      // Add the highlighted mention
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          fontSize: 13,
          color: Colors.blue.shade600,
          fontWeight: FontWeight.w600,
          backgroundColor: Colors.blue.shade50,
        ),
      ));
      
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < body.length) {
      spans.add(TextSpan(
        text: body.substring(lastEnd),
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF374151),
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildMessageAttachments(List<String> attachmentIds) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachmentIds.map((id) {
        final attachment = _event!.getAttachment(id);
        if (attachment == null) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getAttachmentIcon(attachment),
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                attachment.label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNewMessageComposer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _mainComposerController,
            focusNode: _mainComposerFocusNode,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          // Fixed layout: attach-file and Post buttons on same row, right-aligned
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File attachment feature coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.attach_file),
                tooltip: 'Attach file',
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post message feature coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  _mainComposerController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  String _formatKey(String key) {
    return key.split(RegExp(r'(?=[A-Z])|_'))
        .map((word) => word.toLowerCase())
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : word)
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value is List) {
      return value.length <= 3 
          ? value.join(', ')
          : '${value.take(3).join(', ')}... (${value.length} items)';
    }
    return value.toString();
  }

  IconData _getAttachmentIcon(EventAttachment attachment) {
    if (attachment.isImage) return Icons.image;
    if (attachment.isVideo) return Icons.video_file;
    if (attachment.isPdf) return Icons.picture_as_pdf;
    return Icons.attach_file;
  }
}
