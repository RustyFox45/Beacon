import 'package:flutter/material.dart';

import '../models/lesson_plan.dart';
import '../services/lesson_service.dart';

class LessonProvider extends ChangeNotifier {
  final List<LessonPlan> _lessons = [];
  bool _isLoading = false;
  String? _error;

  List<LessonPlan> get lessons => List.unmodifiable(_lessons);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLessons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final lessons = await LessonService.fetchLessons();
      _lessons
        ..clear()
        ..addAll(lessons);
    } catch (e) {
      _error = 'Failed to load lessons.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LessonPlan> addOrUpdateLesson(LessonPlan lesson) async {
    try {
      final saved = await LessonService.saveLesson(lesson);
      // Match by either the temp local ID or the real Supabase ID
      final index = _lessons.indexWhere(
        (l) => l.id == lesson.id || l.id == saved.id,
      );
      if (index != -1) {
        _lessons[index] = saved;
      } else {
        _lessons.insert(0, saved);
      }
      notifyListeners();
      return saved;
    } catch (e) {
      _error = 'Failed to save lesson.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteLesson(String id) async {
    try {
      await LessonService.deleteLesson(id);
      _lessons.removeWhere((l) => l.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete lesson.';
      notifyListeners();
      rethrow;
    }
  }

  void clear() {
    _lessons.clear();
    _error = null;
    notifyListeners();
  }
}
