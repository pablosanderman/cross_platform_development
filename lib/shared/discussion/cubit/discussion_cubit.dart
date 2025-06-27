import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../repositories/discussion_repository.dart';

part 'discussion_state.dart';

/// Status of the discussion operation
enum DiscussionStatus {
  /// Initial state
  initial,

  /// Loading state
  loading,

  /// Success state
  success,

  /// Failure state
  failure,
}

/// {@template discussion_cubit}
/// Manages discussion state and operations for events
/// {@endtemplate}
class DiscussionCubit extends Cubit<DiscussionState> {
  /// {@macro discussion_cubit}
  DiscussionCubit({required DiscussionRepository discussionRepository})
    : _discussionRepository = discussionRepository,
      super(const DiscussionState());

  final DiscussionRepository _discussionRepository;

  /// Add a new message to an event's discussion
  Future<void> addMessage({
    required String eventId,
    required String body,
    required String authorId,
    List<String> attachments = const [],
  }) async {
    emit(state.copyWith(status: DiscussionStatus.loading));

    try {
      final message = DiscussionMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        author: authorId,
        timestamp: DateTime.now(),
        body: body,
        replyTo: null,
        attachments: attachments,
      );

      final success = await _discussionRepository.addMessage(eventId, message);

      if (success) {
        final updatedEvent = await _discussionRepository.getEventWithDiscussion(
          eventId,
        );
        // If we have a current event, preserve its data and only update the discussion
        // This prevents losing original event data when the repository creates a fallback event
        final eventToEmit = state.currentEvent != null && updatedEvent != null
            ? state.currentEvent!.copyWith(discussion: updatedEvent.discussion)
            : updatedEvent;

        emit(
          state.copyWith(
            status: DiscussionStatus.success,
            currentEvent: eventToEmit,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: DiscussionStatus.failure,
            errorMessage: 'Failed to add message',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscussionStatus.failure,
          errorMessage: 'Error adding message: $e',
        ),
      );
    }
  }

  /// Add a reply to an existing message
  Future<void> addReply({
    required String eventId,
    required String parentMessageId,
    required String body,
    required String authorId,
    List<String> attachments = const [],
  }) async {
    emit(state.copyWith(status: DiscussionStatus.loading));

    try {
      final reply = DiscussionMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        author: authorId,
        timestamp: DateTime.now(),
        body: body,
        replyTo: parentMessageId,
        attachments: attachments,
      );

      final success = await _discussionRepository.addReply(
        eventId,
        parentMessageId,
        reply,
      );

      if (success) {
        final updatedEvent = await _discussionRepository.getEventWithDiscussion(
          eventId,
        );
        // If we have a current event, preserve its data and only update the discussion
        // This prevents losing original event data when the repository creates a fallback event
        final eventToEmit = state.currentEvent != null && updatedEvent != null
            ? state.currentEvent!.copyWith(discussion: updatedEvent.discussion)
            : updatedEvent;

        emit(
          state.copyWith(
            status: DiscussionStatus.success,
            currentEvent: eventToEmit,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: DiscussionStatus.failure,
            errorMessage: 'Failed to add reply',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscussionStatus.failure,
          errorMessage: 'Error adding reply: $e',
        ),
      );
    }
  }

  /// Add an attachment to an event's discussion
  Future<void> addAttachment({
    required String eventId,
    required EventAttachment attachment,
    required String authorId,
  }) async {
    emit(state.copyWith(status: DiscussionStatus.loading));

    try {
      final success = await _discussionRepository.addAttachment(
        eventId,
        attachment,
        authorId,
      );

      if (success) {
        final updatedEvent = await _discussionRepository.getEventWithDiscussion(
          eventId,
        );
        // If we have a current event, preserve its data and only update the discussion
        // This prevents losing original event data when the repository creates a fallback event
        final eventToEmit = state.currentEvent != null && updatedEvent != null
            ? state.currentEvent!.copyWith(discussion: updatedEvent.discussion)
            : updatedEvent;

        emit(
          state.copyWith(
            status: DiscussionStatus.success,
            currentEvent: eventToEmit,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: DiscussionStatus.failure,
            errorMessage: 'Failed to add attachment',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscussionStatus.failure,
          errorMessage: 'Error adding attachment: $e',
        ),
      );
    }
  }

  /// Load discussion for a specific event
  Future<void> loadEventDiscussion(String eventId) async {
    emit(state.copyWith(status: DiscussionStatus.loading));

    try {
      final event = await _discussionRepository.getEventWithDiscussion(eventId);

      if (event != null) {
        emit(
          state.copyWith(status: DiscussionStatus.success, currentEvent: event),
        );
      } else {
        emit(
          state.copyWith(
            status: DiscussionStatus.failure,
            errorMessage: 'Event not found',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscussionStatus.failure,
          errorMessage: 'Error loading event discussion: $e',
        ),
      );
    }
  }

  /// Clear current state
  void clearState() {
    emit(const DiscussionState());
  }
}
