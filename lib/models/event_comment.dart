import 'user.dart';

class EventComment {
  final String id;
  final String eventId;
  final String userId;
  final String content;
  final DateTime createdAt;
  
  // Populated via join
  final User? user;

  EventComment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.user,
  });

  factory EventComment.fromMap(Map<String, dynamic> map) {
    User? profile;
    if (map['profiles'] != null) {
      profile = User.fromMap(map['profiles'] as Map<String, dynamic>);
    }

    return EventComment(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      user: profile,
    );
  }
}
