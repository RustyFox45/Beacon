import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson_plan.dart';
import '../providers/lesson_provider.dart';
import '../providers/user_provider.dart';
import '../utils/ui_utils.dart';
import 'lessons/lesson_editor_screen.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/lesson_template_card.dart';
import '../widgets/fhe_template_card.dart';
import 'profile/profile_screen.dart';
import '../theme/theme.dart';

enum LessonFilter { anyone, me, notMe }
enum LessonSort { lastOpened, lastModified, title }
enum LessonView { list, grid }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  LessonFilter _filter = LessonFilter.anyone;
  LessonSort _sort = LessonSort.lastOpened;
  LessonView _view = LessonView.list;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().currentUser;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(activeRoute: 'home'),
      appBar: AppBar(
        title: const Text('GOSPEL BEACON'),
        leading: IconButton(
          icon: AppIcons.menu(color: AppColors.beaconYellow),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey[300],
                backgroundImage: UiUtils.getAvatarProvider(
                  currentUser.profilePictureUrl,
                ),
                child: currentUser.profilePictureUrl.isEmpty
                    ? AppIcons.profile(color: Colors.grey)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Lesson Templates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Template Cards Horizontal List
            SizedBox(
              height: 215,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  LessonTemplateCard(
                    label: 'Start from scratch',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonEditorScreen(
                            lessonPlan: LessonPlan.empty(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  FheTemplateCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonEditorScreen(
                            lessonPlan: LessonPlan.fheTemplate(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  // Additional templates can go here
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Recent Lessons Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Created Lessons',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // Filter Dropdown
                    PopupMenuButton<LessonFilter>(
                      tooltip: 'Filter ownership',
                      onSelected: (val) => setState(() => _filter = val),
                      icon: AppIcons.filter(size: 20),
                      offset: const Offset(0, 40),
                      elevation: 8,
                      color: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: LessonFilter.anyone,
                          child: const Text(
                            'Owned by anyone',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: LessonFilter.me,
                          child: const Text(
                            'Owned by me',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: LessonFilter.notMe,
                          child: const Text(
                            'Not Owned by me',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    // Sort Dropdown
                    PopupMenuButton<LessonSort>(
                      tooltip: 'Sort lessons',
                      onSelected: (val) => setState(() => _sort = val),
                      icon: AppIcons.sort(size: 20),
                      offset: const Offset(0, 40),
                      elevation: 8,
                      color: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: LessonSort.lastOpened,
                          child: const Text(
                            'Last opened by me',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: LessonSort.lastModified,
                          child: const Text(
                            'Last modified',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: LessonSort.title,
                          child: const Text(
                            'Title',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    // Toggle View Button
                    IconButton(
                      tooltip: 'Toggle View',
                      icon: _view == LessonView.list
                          ? AppIcons.gridView(size: 20)
                          : AppIcons.viewList(size: 20),
                      onPressed: () {
                        setState(() {
                          _view = _view == LessonView.list
                              ? LessonView.grid
                              : LessonView.list;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Lessons List/Grid
            Expanded(
              child: Consumer<LessonProvider>(
                builder: (context, lessonProvider, child) {
                  if (lessonProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }
                  
                  // Filter out lessons
                  var lessons = lessonProvider.lessons.where((l) {
                    if (_filter == LessonFilter.me) return l.creatorId == currentUser.id;
                    if (_filter == LessonFilter.notMe) return l.creatorId != currentUser.id;
                    return true;
                  }).toList();

                  // Sort lessons
                  lessons.sort((a, b) {
                    if (_sort == LessonSort.title) {
                      return a.title.compareTo(b.title);
                    } else if (_sort == LessonSort.lastModified) {
                      return b.modifiedDate.compareTo(a.modifiedDate);
                    } else {
                      // Last opened by me
                      final aTime = a.lastOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                      final bTime = b.lastOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                      return bTime.compareTo(aTime);
                    }
                  });

                  if (lessons.isEmpty) {
                    return const Center(
                      child: Text(
                        'No lessons found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  if (_view == LessonView.grid) {
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                         final dateStr =
                            "${_getMonthName(lesson.modifiedDate.month)} ${lesson.modifiedDate.day}";
                        return _buildLessonGridCard(
                          context,
                          lesson: lesson,
                          dateStr: dateStr,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LessonEditorScreen(lessonPlan: lesson),
                              ),
                            );
                          },
                        );
                      },
                    );
                  } else {
                    return ListView.separated(
                      itemCount: lessons.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                        final dateStr =
                            "${_getMonthName(lesson.modifiedDate.month)} ${lesson.modifiedDate.day}, ${lesson.modifiedDate.year}";
                        return _buildLessonListCard(
                          context,
                          lesson: lesson,
                          dateStr: dateStr,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LessonEditorScreen(lessonPlan: lesson),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonListCard(
    BuildContext context, {
    required LessonPlan lesson,
    required String dateStr,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryMidTeal.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                lesson.title.isEmpty ? 'Untitled Lesson' : lesson.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonGridCard(
    BuildContext context, {
    required LessonPlan lesson,
    required String dateStr,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryMidTeal.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lesson.title.isEmpty ? 'Untitled Lesson' : lesson.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}
