import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group.dart';
import '../../providers/lesson_provider.dart';
import '../lessons/lesson_editor_screen.dart';
import '../../theme/theme.dart';

class GroupLessonsScreen extends StatelessWidget {
  final Group group;

  const GroupLessonsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final lessons = context
        .watch<LessonProvider>()
        .lessons
        .where((l) => l.groupId == group.id)
        .toList();
    // Sort by date modified
    lessons.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${group.name} Lessons'),
      ),
      body: lessons.isEmpty
          ? const Center(child: Text('No lessons found for this group.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final dateStr =
                    "${_getMonthName(lesson.modifiedDate.month)} ${lesson.modifiedDate.day}, ${lesson.modifiedDate.year}";
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.grey[100],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      lesson.title.isEmpty ? 'Untitled Lesson' : lesson.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('Modified: $dateStr'),
                    trailing: AppIcons.chevronRight(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LessonEditorScreen(lessonPlan: lesson),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
