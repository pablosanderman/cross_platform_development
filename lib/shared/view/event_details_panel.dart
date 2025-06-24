import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/shared/models/models.dart';
import 'package:cross_platform_development/shared/repositories/repositories.dart';
import 'package:cross_platform_development/navigation/navigation.dart';

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
  final EventsV2Repository _eventsRepository = const EventsV2Repository();
  final UsersRepository _usersRepository = const UsersRepository();
  final GroupsRepository _groupsRepository = const GroupsRepository();
  
  EventV2? _event;
  List<User> _users = [];
  List<Group> _groups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
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
      // For now, we'll convert the old Event to EventV2
      // In a real implementation, you'd load from the new events.json
      final eventV2 = await _eventsRepository.loadEvent(selectedEvent.id);
      
      setState(() {
        _event = eventV2;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load event: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationBloc, NavigationState>(
      listener: (context, state) {
        if (state.selectedEventForDetails != _event?.id) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildTimelineBar(),
          const SizedBox(height: 24),
          _buildUniqueDataSection(),
          const SizedBox(height: 24),
          _buildAttachmentsSection(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 32),
          _buildDiscussionPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _event!.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
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

  Widget _buildTimelineBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDateTime(_event!.dateRange.start),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (_event!.dateRange.end != null)
              Text(
                _formatDateTime(_event!.dateRange.end!),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ],
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
                        entry.value.toString(),
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

  Widget _buildAttachmentsSection() {
    if (_event!.attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _event!.attachments.map((attachment) {
            return _buildAttachmentCard(attachment);
          }).toList(),
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
            // TODO: Implement view on map/timeline
          },
          icon: const Icon(Icons.map, size: 16),
          label: const Text('View on Map'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Implement add to comparison
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
      
      // Add replies
      final replies = _event!.getRepliesTo(message.id);
      for (final reply in replies) {
        widgets.add(_buildReplyCard(reply));
      }
      
      // Add spacing between message threads
      if (i < topLevelMessages.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
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
                    Row(
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ..._buildUserGroupBadges(user),
                      ],
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
          const SizedBox(height: 12),
          Text(
            message.body,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
          if (message.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMessageAttachments(message.attachments),
          ],
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
                        user.displayName,
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
                  const SizedBox(height: 8),
                  Text(
                    reply.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.4,
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

  List<Widget> _buildUserGroupBadges(User user) {
    return user.groups.take(2).map((groupId) {
      final group = _groups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => Group(id: groupId, label: groupId, color: '#6B7280'),
      );
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: group.colorValue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          group.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: group.colorValue,
          ),
        ),
      );
    }).toList();
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
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // TODO: Implement attachment
                    },
                    icon: const Icon(Icons.attach_file),
                    tooltip: 'Attach file',
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement emoji
                    },
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    tooltip: 'Add emoji',
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement post message
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

  IconData _getAttachmentIcon(EventAttachment attachment) {
    if (attachment.isImage) return Icons.image;
    if (attachment.isVideo) return Icons.video_file;
    if (attachment.isPdf) return Icons.picture_as_pdf;
    return Icons.attach_file;
  }
}
