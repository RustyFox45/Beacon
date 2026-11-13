import 'package:flutter/foundation.dart';

import '../models/event.dart';
import '../models/event_comment.dart';
import '../models/event_personnel.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  List<Event> _events = [];
  Map<String, List<EventComment>> _comments = {};
  Set<String> _busyLessonIds = {};
  bool _isLoading = false;
  String? errorMessage;

  List<Event> get events => _events;
  List<EventComment> getComments(String eventId) => _comments[eventId] ?? [];
  Set<String> get busyLessonIds => _busyLessonIds;
  bool get isLoading => _isLoading;

  Future<void> fetchEvents(String groupId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _events = await EventService.fetchEventsForGroup(groupId);
      _busyLessonIds = (await EventService.getBusyLessonIds()).toSet();
      errorMessage = null;
    } catch (e, stack) {
      errorMessage = 'Error fetching events: $e\n$stack';
      debugPrint(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBusyLessons() async {
    try {
      _busyLessonIds = (await EventService.getBusyLessonIds()).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing busy lessons: $e');
    }
  }

  Future<Event> createEvent(
    String groupId,
    String title,
    DateTime date, {
    RecurrenceFrequency? recurrenceFrequency,
    DateTime? recurrenceEndDate,
  }) async {
    try {
      final newEvent = await EventService.createEvent(
        groupId,
        title,
        date,
        recurrenceFrequency: recurrenceFrequency,
        recurrenceEndDate: recurrenceEndDate,
      );
      _events.add(newEvent);
      _events.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
      return newEvent;
    } catch (e) {
      debugPrint('Error creating event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await EventService.deleteEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting event: $e');
      rethrow;
    }
  }

  Future<void> renameEvent(String eventId, String newTitle) async {
    try {
      await EventService.updateEvent(eventId, {'title': newTitle});
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        final groupId = _events[index].groupId;
        await fetchEvents(groupId);
      } else {
        throw Exception('Event $eventId not found in local state');
      }
    } catch (e) {
      errorMessage = 'Error renaming: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> changeEventDate(String eventId, DateTime newDate) async {
    try {
      await EventService.updateEvent(
          eventId, {'date': newDate.toUtc().toIso8601String()});
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        final groupId = _events[index].groupId;
        await fetchEvents(groupId);
      } else {
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Error updating date: $e';
      notifyListeners();
      rethrow;
    }
  }

  // -- RECURRENCE --

  Future<void> setRecurrence(
    String eventId,
    RecurrenceFrequency frequency,
    DateTime endDate, {
    DateTime? startDate,
  }) async {
    try {
      await EventService.setRecurrence(eventId, frequency, endDate,
          startDate: startDate);
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        await fetchEvents(_events[index].groupId);
      }
    } catch (e) {
      debugPrint('Error setting recurrence: $e');
      rethrow;
    }
  }

  Future<void> removeRecurrence(String eventId, {DateTime? startDate}) async {
    try {
      await EventService.removeRecurrence(eventId, startDate: startDate);
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        await fetchEvents(_events[index].groupId);
      }
    } catch (e) {
      debugPrint('Error removing recurrence: $e');
      rethrow;
    }
  }

  // -- LESSON ATTACH/DETACH (single-shot events) --

  Future<void> attachLesson(String eventId, String lessonPlanId) async {
    try {
      await EventService.attachLessonToEvent(eventId, lessonPlanId);
      _busyLessonIds.add(lessonPlanId);
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        final groupId = _events[index].groupId;
        await fetchEvents(groupId);
      }
    } catch (e) {
      debugPrint('Error attaching lesson: $e');
      rethrow;
    }
  }

  Future<void> detachLesson(String eventId) async {
    try {
      final index = _events.indexWhere((e) => e.id == eventId);
      String? oldLessonId;
      if (index != -1) {
        oldLessonId = _events[index].lessonPlan?.id;
      }

      await EventService.detachLessonFromEvent(eventId);

      if (oldLessonId != null) {
        _busyLessonIds.remove(oldLessonId);
      }

      if (index != -1) {
        final groupId = _events[index].groupId;
        await fetchEvents(groupId);
      }
    } catch (e) {
      debugPrint('Error detaching lesson: $e');
      rethrow;
    }
  }

  // -- LESSON ATTACH/DETACH (occurrences) --

  Future<void> attachLessonToOccurrence(
      String eventId, String occurrenceId, String lessonPlanId) async {
    try {
      await EventService.attachLessonToOccurrence(occurrenceId, lessonPlanId);
      _busyLessonIds.add(lessonPlanId);
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        final groupId = _events[index].groupId;
        await fetchEvents(groupId);
      }
    } catch (e) {
      debugPrint('Error attaching lesson to occurrence: $e');
      rethrow;
    }
  }

  Future<void> detachLessonFromOccurrence(
      String eventId, String occurrenceId) async {
    try {
      final eventIndex = _events.indexWhere((e) => e.id == eventId);
      String? oldLessonId;
      if (eventIndex != -1) {
        final occ = _events[eventIndex]
            .occurrences
            .firstWhere((o) => o.id == occurrenceId,
                orElse: () => throw Exception('Occurrence not found'));
        oldLessonId = occ.lessonPlanId;
      }

      await EventService.detachLessonFromOccurrence(occurrenceId);

      if (oldLessonId != null) {
        _busyLessonIds.remove(oldLessonId);
      }

      if (eventIndex != -1) {
        final groupId = _events[eventIndex].groupId;
        await fetchEvents(groupId);
      }
    } catch (e) {
      debugPrint('Error detaching lesson from occurrence: $e');
      rethrow;
    }
  }

  // -- PERSONNEL --

  Future<void> addPersonnel(
      String eventId, String userId, String roleName) async {
    try {
      await EventService.addPersonnel(eventId, userId, roleName);
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        await fetchEvents(_events[index].groupId);
      }
    } catch (e) {
      debugPrint('Error adding personnel: $e');
      rethrow;
    }
  }

  Future<void> removePersonnel(String eventId, String personnelId) async {
    try {
      await EventService.removePersonnel(personnelId);
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        final oldEvent = _events[index];
        final newPersonnel =
            oldEvent.personnel.where((p) => p.id != personnelId).toList();
        _events[index] = oldEvent.copyWith(personnel: newPersonnel);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error removing personnel: $e');
      rethrow;
    }
  }

  Future<void> togglePersonnelAgreement(
      String eventId, String personnelId, bool agreed) async {
    try {
      await EventService.togglePersonnelAgreement(personnelId, agreed);
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        final oldEvent = _events[index];
        final newPersonnel = oldEvent.personnel.map((p) {
          if (p.id == personnelId) {
            return EventPersonnel(
              id: p.id,
              eventId: p.eventId,
              userId: p.userId,
              roleName: p.roleName,
              agreed: agreed,
              user: p.user,
            );
          }
          return p;
        }).toList();
        _events[index] = oldEvent.copyWith(personnel: newPersonnel);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling agreement: $e');
      rethrow;
    }
  }

  // -- COMMENTS --

  Future<void> fetchComments(String eventId) async {
    try {
      final comments = await EventService.fetchCommentsForEvent(eventId);
      _comments[eventId] = comments;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    }
  }

  Future<void> addComment(
      String eventId, String userId, String content) async {
    try {
      final newComment =
          await EventService.addComment(eventId, userId, content);
      if (_comments.containsKey(eventId)) {
        _comments[eventId]!.add(newComment);
      } else {
        _comments[eventId] = [newComment];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String eventId, String commentId) async {
    try {
      await EventService.deleteComment(commentId);
      if (_comments.containsKey(eventId)) {
        _comments[eventId]!.removeWhere((c) => c.id == commentId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      rethrow;
    }
  }
}
