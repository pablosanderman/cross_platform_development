part of 'discussion_cubit.dart';

/// {@template discussion_state}
/// State for the discussion feature
/// {@endtemplate}
class DiscussionState extends Equatable {
  /// {@macro discussion_state}
  const DiscussionState({
    this.status = DiscussionStatus.initial,
    this.currentEvent,
    this.errorMessage,
  });

  /// Current status of the discussion operation
  final DiscussionStatus status;

  /// Currently loaded event with discussion data
  final Event? currentEvent;

  /// Error message if operation failed
  final String? errorMessage;

  /// Whether the cubit is currently loading
  bool get isLoading => status == DiscussionStatus.loading;

  /// Whether the last operation was successful
  bool get isSuccess => status == DiscussionStatus.success;

  /// Whether the last operation failed
  bool get isFailure => status == DiscussionStatus.failure;

  /// Gets the discussion messages for the current event
  List<DiscussionMessage> get messages => currentEvent?.discussion ?? [];

  /// Gets top-level messages (not replies)
  List<DiscussionMessage> get topLevelMessages => 
      messages.where((message) => !message.isReply).toList();

  /// Gets replies for a specific message
  List<DiscussionMessage> getReplies(String messageId) =>
      messages.where((message) => message.replyTo == messageId).toList();

  /// Creates a copy of this state with the given fields replaced
  DiscussionState copyWith({
    DiscussionStatus? status,
    Event? currentEvent,
    String? errorMessage,
  }) {
    return DiscussionState(
      status: status ?? this.status,
      currentEvent: currentEvent ?? this.currentEvent,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, currentEvent, errorMessage];
}