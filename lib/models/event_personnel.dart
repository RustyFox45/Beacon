import 'user.dart';

class EventPersonnel {
  final String id;
  final String eventId;
  final String userId;
  final String roleName;
  final bool agreed;
  
  // Populated from profile join
  final User? user;

  EventPersonnel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.roleName,
    required this.agreed,
    this.user,
  });

  factory EventPersonnel.fromMap(Map<String, dynamic> map) {
    User? profile;
    if (map['profiles'] != null) {
      profile = User.fromMap(map['profiles'] as Map<String, dynamic>);
    }

    return EventPersonnel(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      userId: map['user_id'] as String,
      roleName: map['role_name'] as String,
      agreed: (map['agreed'] as bool?) ?? false,
      user: profile,
    );
  }
}
