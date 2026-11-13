import 'event_occurrence.dart';
import 'event_personnel.dart';
import 'lesson_plan.dart';

enum RecurrenceFrequency { weekly, biweekly, monthly }

class Event {
  final String id;
  final String groupId;
  final String title;
  final DateTime date;
  final String? lessonPlanId;
  final DateTime createdAt;
  final RecurrenceFrequency? recurrenceFrequency;
  final DateTime? recurrenceEndDate;

  // Populated fields from joins
  final LessonPlan? lessonPlan;
  final List<EventPersonnel> personnel;
  final List<EventOccurrence> occurrences;

  const Event({
    required this.id,
    required this.groupId,
    required this.title,
    required this.date,
    this.lessonPlanId,
    required this.createdAt,
    this.recurrenceFrequency,
    this.recurrenceEndDate,
    this.lessonPlan,
    this.personnel = const [],
    this.occurrences = const [],
  });

  bool get isRecurring => recurrenceFrequency != null;

  factory Event.fromMap(Map<String, dynamic> map) {
    LessonPlan? lessonPlan;
    if (map['lesson_plans'] != null) {
      lessonPlan = LessonPlan.fromMap(map['lesson_plans'] as Map<String, dynamic>);
    }

    List<EventPersonnel> personnel = [];
    if (map['event_personnel'] != null) {
      final personnelData = map['event_personnel'] as List<dynamic>;
      personnel = personnelData
          .map((p) => EventPersonnel.fromMap(p as Map<String, dynamic>))
          .toList();
    }

    List<EventOccurrence> occurrences = [];
    if (map['event_occurrences'] != null) {
      final occurrenceData = map['event_occurrences'] as List<dynamic>;
      occurrences = occurrenceData
          .map((o) => EventOccurrence.fromMap(o as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.occurrenceDate.compareTo(b.occurrenceDate));
    }

    RecurrenceFrequency? recurrenceFrequency;
    final freqStr = map['recurrence_frequency'] as String?;
    if (freqStr != null) {
      recurrenceFrequency = RecurrenceFrequency.values.firstWhere(
        (f) => f.name == freqStr,
        orElse: () => RecurrenceFrequency.weekly,
      );
    }

    DateTime? recurrenceEndDate;
    if (map['recurrence_end_date'] != null) {
      recurrenceEndDate = DateTime.parse(map['recurrence_end_date'] as String).toLocal();
    }

    return Event(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String).toLocal(),
      lessonPlanId: map['lesson_plan_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      recurrenceFrequency: recurrenceFrequency,
      recurrenceEndDate: recurrenceEndDate,
      lessonPlan: lessonPlan,
      personnel: personnel,
      occurrences: occurrences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'title': title,
      'date': date.toUtc().toIso8601String(),
      'lesson_plan_id': lessonPlanId,
      if (recurrenceFrequency != null)
        'recurrence_frequency': recurrenceFrequency!.name,
      if (recurrenceEndDate != null)
        'recurrence_end_date': recurrenceEndDate!.toIso8601String().split('T')[0],
    };
  }

  Event copyWith({
    String? title,
    DateTime? date,
    String? lessonPlanId,
    LessonPlan? lessonPlan,
    List<EventPersonnel>? personnel,
    List<EventOccurrence>? occurrences,
    RecurrenceFrequency? recurrenceFrequency,
    DateTime? recurrenceEndDate,
  }) {
    return Event(
      id: id,
      groupId: groupId,
      title: title ?? this.title,
      date: date ?? this.date,
      lessonPlanId: lessonPlanId ?? this.lessonPlanId,
      createdAt: createdAt,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      lessonPlan: lessonPlan ?? this.lessonPlan,
      personnel: personnel ?? this.personnel,
      occurrences: occurrences ?? this.occurrences,
    );
  }
}
