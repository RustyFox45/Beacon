import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson_plan.dart';
import 'supabase_service.dart';

class LessonService {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<LessonPlan> saveLesson(LessonPlan lesson) async {
    final userId = SupabaseService.currentUserId!;
    final isNew = lesson.creatorId.isEmpty;
    final now = DateTime.now();

    final planData = <String, dynamic>{
      'title': lesson.title,
      'description': lesson.description,
      'target_audience': lesson.targetAudience,
      'date': lesson.date.toIso8601String(),
      'modified_date': now.toIso8601String(),
      'group_id': lesson.groupId,
      'creator_id': userId,
    };

    final String lessonId;
    if (isNew) {
      final result = await _client
          .from('lesson_plans')
          .insert(planData)
          .select()
          .single();
      lessonId = result['id'] as String;
    } else {
      lessonId = lesson.id;
      await _client
          .from('lesson_plans')
          .update(planData)
          .eq('id', lessonId);
    }

    await _client
        .from('lesson_sections')
        .delete()
        .eq('lesson_plan_id', lessonId);

    if (lesson.sections.isNotEmpty) {
      final sectionsData = lesson.sections.asMap().entries.map((entry) {
        final section = entry.value;
        return <String, dynamic>{
          'lesson_plan_id': lessonId,
          'title': section.title,
          'content': section.content,
          'type': section.type.name,
          'link_url': section.linkUrl,
          'link_title': section.linkTitle,
          'link_image_url': section.linkImageUrl,
          'position': entry.key,
        };
      }).toList();
      await _client.from('lesson_sections').insert(sectionsData);
    }
    
    // Check if we need to update last opened
    await trackLessonOpen(lessonId);

    return lesson.copyWith(id: lessonId, creatorId: userId, modifiedDate: now);
  }

  static Future<List<LessonPlan>> fetchLessons() async {
    final response = await _client
        .from('lesson_plans')
        .select('*, lesson_sections(*), user_lesson_activity(last_opened_at)')
        .order('modified_date', ascending: false);
    return response
        .map<LessonPlan>((data) => LessonPlan.fromMap(data))
        .toList();
  }

  static Future<void> deleteLesson(String lessonId) async {
    await _client.from('lesson_plans').delete().eq('id', lessonId);
  }

  static Future<void> trackLessonOpen(String lessonId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    
    await _client.from('user_lesson_activity').upsert({
      'user_id': userId,
      'lesson_plan_id': lessonId,
      'last_opened_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
