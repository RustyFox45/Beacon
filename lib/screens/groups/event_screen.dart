import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../models/event_occurrence.dart';
import '../../models/group.dart';
import '../../providers/event_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/auth_provider.dart';
import '../lessons/lesson_editor_screen.dart';
import '../../utils/toasts.dart';
import '../../theme/theme.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/occurrence_navigator.dart';
import 'set_recurrence_sheet.dart';

class EventScreen extends StatefulWidget {
  final Event event;
  final Group group;
  final int initialOccurrenceIndex;

  const EventScreen({
    super.key,
    required this.event,
    required this.group,
    this.initialOccurrenceIndex = 0,
  });

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isChatFocused = false;
  int _currentOccurrenceIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentOccurrenceIndex = widget.initialOccurrenceIndex;
    _chatFocusNode.addListener(() {
      setState(() {
        _isChatFocused = _chatFocusNode.hasFocus;
      });
      if (_chatFocusNode.hasFocus) {
        _scrollToBottom();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<EventProvider>().fetchComments(widget.event.id);
      _scrollToBottom(animate: false);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _scrollToBottom(animate: false);
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _chatFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final position = _scrollController.position.maxScrollExtent;
        if (animate) {
          _scrollController.animateTo(
            position,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(position);
        }
      }
    });
  }

  // Returns the live event from provider state
  Event _liveEvent(EventProvider eventProvider) {
    final idx = eventProvider.events.indexWhere((e) => e.id == widget.event.id);
    return idx != -1 ? eventProvider.events[idx] : widget.event;
  }

  // Returns the current occurrence (for recurring events)
  EventOccurrence? _currentOccurrence(Event event) {
    if (!event.isRecurring || event.occurrences.isEmpty) return null;
    final idx = _currentOccurrenceIndex.clamp(0, event.occurrences.length - 1);
    return event.occurrences[idx];
  }

  void _showAddLessonPicker(Event event) {
    final lessonProvider = context.read<LessonProvider>();
    final eventProvider = context.read<EventProvider>();
    final availableLessons = lessonProvider.lessons
        .where((l) => !eventProvider.busyLessonIds.contains(l.id))
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Add a Lesson',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: availableLessons.isEmpty
                    ? const Center(child: Text('No available lessons.'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableLessons.length,
                        itemBuilder: (context, index) {
                          final lesson = availableLessons[index];
                          return ListTile(
                            title: Text(
                              lesson.title.isEmpty ? 'Untitled' : lesson.title,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Last modified: ${lesson.modifiedDate.month}/${lesson.modifiedDate.day}',
                              style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.7)),
                            ),
                            trailing: AppIcons.add(),
                            onTap: () async {
                              Navigator.pop(sheetContext);
                              try {
                                final occ = _currentOccurrence(event);
                                if (occ != null) {
                                  await context
                                      .read<EventProvider>()
                                      .attachLessonToOccurrence(
                                          event.id, occ.id, lesson.id);
                                } else {
                                  await context
                                      .read<EventProvider>()
                                      .attachLesson(event.id, lesson.id);
                                }
                                if (context.mounted) {
                                  Toast.success(
                                      context, 'Lesson attached to event');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Toast.error(context,
                                      'Failed to attach lesson: $e');
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddPersonnelDialog(Event event) {
    final groupMembers = widget.group.members;
    String? selectedUserId;
    String roleName = 'Participant';

    showAppDialog(
      context: context,
      title: 'Add Personnel',
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Member',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black54),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Choose from group representatives',
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.05),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                ),
                dropdownColor: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(15),
                items: groupMembers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final m = entry.value;
                  return DropdownMenuItem(
                    value: m.id,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: index != groupMembers.length - 1
                            ? const Border(
                                bottom: BorderSide(
                                    color: Colors.black12, width: 0.5))
                            : null,
                      ),
                      child: Text(
                        m.name,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedUserId = val),
              ),
              const SizedBox(height: 24),
              const Text(
                'Assign Role',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: roleName,
                decoration: InputDecoration(
                  hintText: 'e.g. Speaker, Teacher, Coordinator',
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.05),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (val) => roleName = val,
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (selectedUserId != null && roleName.isNotEmpty) {
              Navigator.pop(context);
              try {
                await context
                    .read<EventProvider>()
                    .addPersonnel(event.id, selectedUserId!, roleName);
              } catch (e) {
                if (context.mounted) {
                  Toast.error(context, 'Failed to add personnel: $e');
                }
              }
            }
          },
          child:
              const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showEventMenu(Event event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (menuContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Event Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: AppIcons.edit(),
                title: const Text('Rename Event',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(menuContext);
                  _showRenameDialog(event.title);
                },
              ),
              ListTile(
                leading: AppIcons.calendar(),
                title: Text(
                  event.isRecurring ? 'Change Recurrence' : 'Set Recurrence',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(menuContext);
                  showSetRecurrenceDialog(context, event: event);
                },
              ),
              if (!event.isRecurring)
                ListTile(
                  leading: AppIcons.calendar(),
                  title: const Text('Change Date',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    Navigator.pop(menuContext);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: event.date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && context.mounted) {
                      try {
                        await context
                            .read<EventProvider>()
                            .changeEventDate(event.id, picked);
                        if (context.mounted) {
                          Toast.success(context, 'Date updated successfully!');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Toast.error(context, 'Failed to update date: $e');
                        }
                      }
                    }
                  },
                ),
              ListTile(
                leading: AppIcons.delete(color: AppColors.destructiveRed),
                title: const Text('Delete Event',
                    style: TextStyle(
                        color: AppColors.destructiveRed,
                        fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(menuContext);
                  final provider = context.read<EventProvider>();
                  final navigator = Navigator.of(context);
                  showAppDialog(
                    context: context,
                    title: 'Delete Event',
                    content: const Text(
                      'Are you sure you want to delete this event?',
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      Builder(
                        builder: (dialogContext) => TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                      ),
                      Builder(
                        builder: (dialogContext) => TextButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            try {
                              await provider.deleteEvent(event.id);
                              navigator.pop();
                              if (navigator.context.mounted)
                                Toast.success(navigator.context, 'Event deleted');
                            } catch (e) {
                              if (navigator.context.mounted)
                                Toast.error(navigator.context, 'Failed to delete');
                            }
                          },
                          child: const Text('Delete',
                              style: TextStyle(
                                  color: AppColors.destructiveRed,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(String currentTitle) {
    String newTitle = currentTitle;
    showAppDialog(
      context: context,
      title: 'Rename Event',
      content: TextFormField(
        initialValue: newTitle,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) => newTitle = val,
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            if (newTitle.isNotEmpty) {
              try {
                await context
                    .read<EventProvider>()
                    .renameEvent(widget.event.id, newTitle);
                if (context.mounted) Toast.success(context, 'Event renamed');
              } catch (e) {
                if (context.mounted)
                  Toast.error(context, 'Failed to rename: $e');
              }
            }
          },
          child:
              const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.session?.user.id;

    final event = _liveEvent(eventProvider);
    final occ = _currentOccurrence(event);

    // Clamp index if occurrences list shrank
    if (event.isRecurring &&
        event.occurrences.isNotEmpty &&
        _currentOccurrenceIndex >= event.occurrences.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentOccurrenceIndex = event.occurrences.length - 1;
          });
        }
      });
    }

    // The lesson to display: occurrence-level for recurring, event-level for single
    final displayedLesson = occ?.lessonPlan ?? (!event.isRecurring ? event.lessonPlan : null);

    // Sort personnel: Me first
    final sortedPersonnel = List<dynamic>.from(event.personnel);
    if (currentUserId != null) {
      sortedPersonnel.sort((a, b) {
        if (a.userId == currentUserId) return -1;
        if (b.userId == currentUserId) return 1;
        return 0;
      });
    }

    final comments = eventProvider.getComments(event.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title.toUpperCase()),
        actions: [
          IconButton(
            icon: AppIcons.moreVert(color: AppColors.beaconYellow),
            onPressed: () => _showEventMenu(event),
          ),
        ],
      ),
      body: Column(
        children: [
          if (eventProvider.errorMessage != null)
            Material(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    AppIcons.error(size: 20, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventProvider.errorMessage!,
                            style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              if (event.groupId.isNotEmpty) {
                                context
                                    .read<EventProvider>()
                                    .fetchEvents(event.groupId);
                              }
                            },
                            child: const Text('Retry Fetch'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!_isChatFocused) ...[
            // Occurrence navigator for recurring events
            if (event.isRecurring && event.occurrences.isNotEmpty) ...[
              const SizedBox(height: 12),
              OccurrenceNavigator(
                occurrences: event.occurrences,
                currentIndex: _currentOccurrenceIndex.clamp(
                    0, event.occurrences.length - 1),
                onIndexChanged: (i) =>
                    setState(() => _currentOccurrenceIndex = i),
              ),
              const SizedBox(height: 4),
            ],

            // Fixed Header (Event Info + Lesson status)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // For non-recurring events show the date here
                  if (!event.isRecurring)
                    Text(
                      '${event.date.month}/${event.date.day}/${event.date.year}',
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    )
                  else
                    const SizedBox.shrink(),
                  if (displayedLesson != null)
                    const Text('Lesson Attached',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Lesson Section
            if (displayedLesson != null)
              _SlidableLessonCard(
                lesson: displayedLesson,
                onDelete: () async {
                  try {
                    if (occ != null) {
                      await context
                          .read<EventProvider>()
                          .detachLessonFromOccurrence(event.id, occ.id);
                    } else {
                      await context
                          .read<EventProvider>()
                          .detachLesson(event.id);
                    }
                    if (context.mounted)
                      Toast.success(context, 'Lesson removed');
                  } catch (e) {
                    if (context.mounted)
                      Toast.error(context, 'Failed to remove lesson');
                  }
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LessonEditorScreen(lessonPlan: displayedLesson),
                    ),
                  );
                },
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () => _showAddLessonPicker(event),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcons.add(size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('Add Lesson',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Horizontal Participants
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Participants',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: AppIcons.add(size: 20),
                    onPressed: () => _showAddPersonnelDialog(event),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            if (event.personnel.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text('No participants added.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              SizedBox(
                height: 90,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: sortedPersonnel.length,
                  itemBuilder: (context, index) {
                    final p = sortedPersonnel[index];
                    final isMe = p.userId == currentUserId;
                    final initials = (p.user?.name ?? '??')
                        .split(' ')
                        .map((e) => e[0])
                        .take(2)
                        .join('')
                        .toUpperCase();

                    return GestureDetector(
                      onLongPress: () async {
                        final confirm = await showAppDialog<bool>(
                          context: context,
                          title: 'Remove Participant?',
                          content: Text(
                            'Remove ${p.user?.name ?? "this user"} from the event?',
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            Builder(
                              builder: (ctx) => TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                            Builder(
                              builder: (ctx) => TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Remove',
                                    style: TextStyle(
                                        color: AppColors.destructiveRed,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        );
                        if (confirm == true) {
                          await context
                              .read<EventProvider>()
                              .removePersonnel(event.id, p.id);
                        }
                      },
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: isMe
                                      ? Colors.blue[100]
                                      : Colors.grey[200],
                                  child: Text(initials,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isMe
                                              ? Colors.blue[800]
                                              : Colors.black87)),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.grey[300]!, width: 1),
                                    ),
                                    child: p.agreed
                                        ? AppIcons.checkCircle(
                                            size: 12, color: Colors.green)
                                        : AppIcons.help(
                                            size: 12, color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isMe
                                  ? 'Me'
                                  : (p.user?.name?.split(' ')[0] ?? 'User'),
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const Divider(height: 1),
          ],

          if (_isChatFocused)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border:
                    Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Text(
                event.title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ),

          // Scrollable Chat Section
          Expanded(
            child: comments.isEmpty
                ? const Center(
                    child: Text('No messages yet. Start the conversation!',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 13)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      final isMine = c.userId == currentUserId;

                      final prev = index > 0 ? comments[index - 1] : null;
                      final next = index < comments.length - 1
                          ? comments[index + 1]
                          : null;

                      final isSameUserAsPrev = prev?.userId == c.userId;
                      final isSameMinuteAsPrev = prev != null &&
                          prev.createdAt.year == c.createdAt.year &&
                          prev.createdAt.month == c.createdAt.month &&
                          prev.createdAt.day == c.createdAt.day &&
                          prev.createdAt.hour == c.createdAt.hour &&
                          prev.createdAt.minute == c.createdAt.minute;

                      final isSameUserAsNext = next?.userId == c.userId;
                      final isSameMinuteAsNext = next != null &&
                          next.createdAt.year == c.createdAt.year &&
                          next.createdAt.month == c.createdAt.month &&
                          next.createdAt.day == c.createdAt.day &&
                          next.createdAt.hour == c.createdAt.hour &&
                          next.createdAt.minute == c.createdAt.minute;

                      final isStartOfGroup =
                          !(isSameUserAsPrev && isSameMinuteAsPrev);
                      final isEndOfGroup =
                          !(isSameUserAsNext && isSameMinuteAsNext);

                      return Container(
                        margin: EdgeInsets.only(
                            bottom: isEndOfGroup ? 12 : 2),
                        child: Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isMine && isStartOfGroup)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 4, bottom: 4),
                                child: Text(
                                  c.user?.name ?? 'Unknown',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            GestureDetector(
                              onLongPress: isMine
                                  ? () async {
                                      final confirm =
                                          await showAppDialog<bool>(
                                        context: context,
                                        title: 'Delete Message?',
                                        content: const Text(
                                          'This message will be permanently deleted.',
                                          textAlign: TextAlign.center,
                                        ),
                                        actions: [
                                          Builder(
                                            builder: (ctx) => TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel',
                                                  style: TextStyle(
                                                      color: Colors.grey)),
                                            ),
                                          ),
                                          Builder(
                                            builder: (ctx) => TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Delete',
                                                  style: TextStyle(
                                                      color: AppColors
                                                          .destructiveRed,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      );
                                      if (confirm == true) {
                                        try {
                                          await context
                                              .read<EventProvider>()
                                              .deleteComment(event.id, c.id);
                                          if (context.mounted)
                                            Toast.success(context, 'Deleted');
                                        } catch (e) {
                                          if (context.mounted)
                                            Toast.error(
                                                context, 'Failed to delete');
                                        }
                                      }
                                    }
                                  : null,
                              child: Row(
                                mainAxisAlignment: isMine
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isMine
                                            ? Colors.black
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(
                                              isStartOfGroup ? 16 : 4),
                                          topRight: Radius.circular(
                                              isStartOfGroup ? 16 : 4),
                                          bottomLeft: Radius.circular(
                                              (isMine || isEndOfGroup)
                                                  ? 16
                                                  : 4),
                                          bottomRight: Radius.circular(
                                              (!isMine || isEndOfGroup)
                                                  ? 16
                                                  : 4),
                                        ),
                                      ),
                                      child: Text(
                                        c.content,
                                        style: TextStyle(
                                          color: isMine
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isEndOfGroup)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 4, left: 4, right: 4),
                                child: Text(
                                  '${c.createdAt.hour}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Chat input
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _chatFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: AppIcons.send(),
                  onPressed: () async {
                    if (_commentController.text.trim().isNotEmpty &&
                        currentUserId != null) {
                      final content = _commentController.text.trim();
                      _commentController.clear();
                      try {
                        await context
                            .read<EventProvider>()
                            .addComment(event.id, currentUserId, content);
                        _scrollToBottom();
                      } catch (e) {
                        if (context.mounted)
                          Toast.error(context, 'Failed to send');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slidable lesson card (swipe-to-delete)
// ---------------------------------------------------------------------------

class _SlidableLessonCard extends StatefulWidget {
  final dynamic lesson;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SlidableLessonCard({
    required this.lesson,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_SlidableLessonCard> createState() => _SlidableLessonCardState();
}

class _SlidableLessonCardState extends State<_SlidableLessonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = AlwaysStoppedAnimation(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runAnimation(double target) {
    _animation = Tween<double>(
      begin: _dragExtent,
      end: target,
    ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.reset();
    _controller.forward().then((_) {
      _dragExtent = target;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isRemoving) return;
    if (_controller.isAnimating) _controller.stop();
    setState(() {
      _dragExtent += details.delta.dx;
      if (_dragExtent > 0) _dragExtent = 0;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isRemoving) return;

    const threshold = -70.0;
    const dismissThreshold = -180.0;

    if (_dragExtent < dismissThreshold ||
        details.velocity.pixelsPerSecond.dx < -500) {
      _dismiss();
    } else if (_dragExtent < threshold / 2) {
      _runAnimation(threshold);
    } else {
      _runAnimation(0);
    }
  }

  void _dismiss() {
    if (_isRemoving) return;
    setState(() => _isRemoving = true);

    final screenWidth = MediaQuery.of(context).size.width;
    _animation = Tween<double>(
      begin: _dragExtent,
      end: -screenWidth - 100,
    ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.reset();
    _controller.forward().then((_) {
      widget.onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double currentOffset =
            _controller.isAnimating ? _animation.value : _dragExtent;

        if (_isRemoving && !_controller.isAnimating) {
          currentOffset = -MediaQuery.of(context).size.width - 100;
        }

        return TapRegion(
          enabled:
              _dragExtent != 0 || _isRemoving || _controller.isAnimating,
          onTapOutside: (_) {
            if ((_dragExtent != 0 || _controller.value > 0) &&
                !_isRemoving &&
                !_controller.isAnimating) {
              _runAnimation(0);
            }
          },
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: IconButton(
                    icon: AppIcons.delete(color: Colors.white),
                    onPressed: _dismiss,
                  ),
                ),
              ),
              GestureDetector(
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                onTap: widget.onTap,
                child: Transform.translate(
                  offset: Offset(currentOffset, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: Colors.grey[100],
                      elevation: 0,
                      child: ListTile(
                        title: Text(widget.lesson.title.isEmpty
                            ? 'Untitled'
                            : widget.lesson.title),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
