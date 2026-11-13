import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/event.dart';
import '../models/event_comment.dart';
import '../models/event_occurrence.dart';
import 'supabase_service.dart';

class EventService {
  static SupabaseClient get _client => SupabaseService.client;

  static const String _eventSelect =
      '*, lesson_plans(*), event_personnel(*, profiles(*)), event_occurrences(*, lesson_plans(*))';

  // -- EVENTS --

  static Future<List<Event>> fetchEventsForGroup(String groupId) async {
    final response = await _client
        .from('events')
        .select(_eventSelect)
        .eq('group_id', groupId)
        .order('date', ascending: true);

    return response.map<Event>((data) => Event.fromMap(data)).toList();
  }

  static Future<Event> createEvent(
    String groupId,
    String title,
    DateTime date, {
    RecurrenceFrequency? recurrenceFrequency,
    DateTime? recurrenceEndDate,
  }) async {
    final payload = {
      'group_id': groupId,
      'title': title,
      'date': date.toUtc().toIso8601String(),
      if (recurrenceFrequency != null)
        'recurrence_frequency': recurrenceFrequency.name,
      if (recurrenceEndDate != null)
        'recurrence_end_date':
            recurrenceEndDate.toIso8601String().split('T')[0],
    };

    final data = await _client
        .from('events')
        .insert(payload)
        .select(_eventSelect)
        .single();

    final event = Event.fromMap(data);

    if (recurrenceFrequency != null) {
      try {
        await _client.rpc('generate_event_occurrences', params: {
          'p_event_id': event.id,
        });
        // Re-fetch to get the generated occurrences
        return await _fetchEventById(event.id);
      } catch (e) {
        // Clean up the orphaned event row if occurrence generation fails
        await _client.from('events').delete().eq('id', event.id);
        rethrow;
      }
    }

    return event;
  }

  static Future<Event> _fetchEventById(String eventId) async {
    final data = await _client
        .from('events')
        .select(_eventSelect)
        .eq('id', eventId)
        .single();
    return Event.fromMap(data);
  }

  static Future<void> updateEvent(
      String eventId, Map<String, dynamic> updates) async {
    final response = await _client
        .from('events')
        .update(updates)
        .eq('id', eventId)
        .select();

    if (response.isEmpty) {
      throw Exception(
          'Update failed: No rows affected. Check RLS policies or ID.');
    }
  }

  static Future<List<String>> getBusyLessonIds() async {
    final eventResponse = await _client
        .from('events')
        .select('lesson_plan_id')
        .not('lesson_plan_id', 'is', null);

    final occurrenceResponse = await _client
        .from('event_occurrences')
        .select('lesson_plan_id')
        .not('lesson_plan_id', 'is', null);

    final fromEvents = (eventResponse as List<dynamic>)
        .map((e) => e['lesson_plan_id'] as String);
    final fromOccurrences = (occurrenceResponse as List<dynamic>)
        .map((e) => e['lesson_plan_id'] as String);

    return [...fromEvents, ...fromOccurrences];
  }

  static Future<void> deleteEvent(String eventId) async {
    await _client.from('events').delete().eq('id', eventId);
  }

  static Future<void> attachLessonToEvent(
      String eventId, String lessonPlanId) async {
    await updateEvent(eventId, {'lesson_plan_id': lessonPlanId});
  }

  static Future<void> detachLessonFromEvent(String eventId) async {
    await updateEvent(eventId, {'lesson_plan_id': null});
  }

  static Future<void> setRecurrence(
    String eventId,
    RecurrenceFrequency frequency,
    DateTime endDate, {
    DateTime? startDate,
  }) async {
    // Delete all existing occurrences first, then update the rule and regenerate
    await _client
        .from('event_occurrences')
        .delete()
        .eq('event_id', eventId);

    await updateEvent(eventId, {
      'recurrence_frequency': frequency.name,
      'recurrence_end_date': endDate.toIso8601String().split('T')[0],
      if (startDate != null) 'date': startDate.toUtc().toIso8601String(),
    });

    await _client.rpc('generate_event_occurrences', params: {
      'p_event_id': eventId,
    });
  }

  static Future<void> removeRecurrence(String eventId, {DateTime? startDate}) async {
    await _client
        .from('event_occurrences')
        .delete()
        .eq('event_id', eventId);

    await updateEvent(eventId, {
      'recurrence_frequency': null,
      'recurrence_end_date': null,
      if (startDate != null) 'date': startDate.toUtc().toIso8601String(),
    });
  }

  // -- OCCURRENCES --

  static Future<List<EventOccurrence>> fetchOccurrencesForEvent(
      String eventId) async {
    final response = await _client
        .from('event_occurrences')
        .select('*, lesson_plans(*)')
        .eq('event_id', eventId)
        .order('occurrence_date', ascending: true);

    return response
        .map<EventOccurrence>((data) => EventOccurrence.fromMap(data))
        .toList();
  }

  static Future<void> attachLessonToOccurrence(
      String occurrenceId, String lessonPlanId) async {
    final response = await _client
        .from('event_occurrences')
        .update({'lesson_plan_id': lessonPlanId})
        .eq('id', occurrenceId)
        .select();

    if (response.isEmpty) {
      throw Exception('Failed to attach lesson to occurrence.');
    }
  }

  static Future<void> detachLessonFromOccurrence(
      String occurrenceId) async {
    final response = await _client
        .from('event_occurrences')
        .update({'lesson_plan_id': null})
        .eq('id', occurrenceId)
        .select();

    if (response.isEmpty) {
      throw Exception('Failed to detach lesson from occurrence.');
    }
  }

  // -- PERSONNEL --

  static Future<void> addPersonnel(
      String eventId, String userId, String roleName) async {
    await _client.from('event_personnel').insert({
      'event_id': eventId,
      'user_id': userId,
      'role_name': roleName,
    });
  }

  static Future<void> removePersonnel(String personnelId) async {
    await _client.from('event_personnel').delete().eq('id', personnelId);
  }

  static Future<void> togglePersonnelAgreement(
      String personnelId, bool agreed) async {
    await _client
        .from('event_personnel')
        .update({'agreed': agreed})
        .eq('id', personnelId);
  }

  // -- COMMENTS --

  static Future<List<EventComment>> fetchCommentsForEvent(
      String eventId) async {
    final response = await _client
        .from('event_comments')
        .select('*, profiles(*)')
        .eq('event_id', eventId)
        .order('created_at', ascending: true);

    return response
        .map<EventComment>((data) => EventComment.fromMap(data))
        .toList();
  }

  static Future<EventComment> addComment(
      String eventId, String userId, String content) async {
    final data = await _client
        .from('event_comments')
        .insert({
          'event_id': eventId,
          'user_id': userId,
          'content': content,
        })
        .select('*, profiles(*)')
        .single();

    return EventComment.fromMap(data);
  }

  static Future<void> deleteComment(String commentId) async {
    await _client.from('event_comments').delete().eq('id', commentId);
  }
}
