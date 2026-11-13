import 'lesson_plan.dart';

class EventOccurrence {
  final String id;
  final String eventId;
  final DateTime occurrenceDate;
  final String? lessonPlanId;
  final DateTime createdAt;

  final LessonPlan? lessonPlan;

  const EventOccurrence({
    required this.id,
    required this.eventId,
    required this.occurrenceDate,
    this.lessonPlanId,
    required this.createdAt,
    this.lessonPlan,
  });

  factory EventOccurrence.fromMap(Map<String, dynamic> map) {
    LessonPlan? lessonPlan;
    if (map['lesson_plans'] != null) {
      lessonPlan = LessonPlan.fromMap(map['lesson_plans'] as Map<String, dynamic>);
    }

    return EventOccurrence(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      occurrenceDate: DateTime.parse(map['occurrence_date'] as String).toLocal(),
      lessonPlanId: map['lesson_plan_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      lessonPlan: lessonPlan,
    );
  }

  EventOccurrence copyWith({
    String? lessonPlanId,
    LessonPlan? lessonPlan,
    bool clearLesson = false,
  }) {
    return EventOccurrence(
      id: id,
      eventId: eventId,
      occurrenceDate: occurrenceDate,
      lessonPlanId: clearLesson ? null : (lessonPlanId ?? this.lessonPlanId),
      createdAt: createdAt,
      lessonPlan: clearLesson ? null : (lessonPlan ?? this.lessonPlan),
    );
  }
}
