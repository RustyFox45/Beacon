import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../models/event_occurrence.dart';
import '../models/group.dart';
import '../providers/event_provider.dart';
import '../providers/group_provider.dart';
import '../screens/groups/create_group_dialog.dart';
import '../screens/groups/create_session_sheet.dart';
import '../services/supabase_service.dart';
import '../theme/theme.dart';
import '../utils/toasts.dart';
import '../widgets/app_dialog.dart';

/// Shows the list of group events/occurrences this lesson is currently attached
/// to, each as a removable row. Below the list, an "Add to a group event" row
/// lets the user attach the lesson to additional events via a two-step glass
/// picker. For recurring events a third step shows occurrence-level < >
/// navigation.
class EventAssignmentField extends StatefulWidget {
  final String lessonId;
  final VoidCallback onChanged;

  /// Called before the group picker opens. Should save the lesson and return
  /// the real database ID, or null to abort. Only needed for unsaved lessons.
  final Future<String?> Function()? onBeforeAttach;

  const EventAssignmentField({
    super.key,
    required this.lessonId,
    required this.onChanged,
    this.onBeforeAttach,
  });

  @override
  State<EventAssignmentField> createState() => _EventAssignmentFieldState();
}

class _EventAssignmentFieldState extends State<EventAssignmentField> {
  List<Map<String, dynamic>> _attachedEvents = [];
  bool _isLoading = false;

  /// Set after onBeforeAttach resolves; overrides widget.lessonId for DB calls.
  String? _resolvedLessonId;

  String get _effectiveLessonId => _resolvedLessonId ?? widget.lessonId;

  @override
  void initState() {
    super.initState();
    if (widget.lessonId.isNotEmpty) _fetchAttached();
  }

  Future<void> _fetchAttached() async {
    setState(() => _isLoading = true);
    try {
      // Fetch from single-shot events
      final eventRows = await SupabaseService.client
          .from('events')
          .select('id, title, date, groups(name), recurrence_frequency')
          .eq('lesson_plan_id', _effectiveLessonId);

      // Fetch from occurrences
      final occurrenceRows = await SupabaseService.client
          .from('event_occurrences')
          .select(
              'id, occurrence_date, lesson_plan_id, events(id, title, groups(name))')
          .eq('lesson_plan_id', _effectiveLessonId);

      if (mounted) {
        final List<Map<String, dynamic>> combined = [
          ...List<Map<String, dynamic>>.from(eventRows)
              .map((r) => {...r, '_source': 'event'}),
          ...List<Map<String, dynamic>>.from(occurrenceRows)
              .map((r) => {...r, '_source': 'occurrence'}),
        ];
        setState(() {
          _attachedEvents = combined;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDetach(Map<String, dynamic> row) async {
    final isOccurrence = row['_source'] == 'occurrence';
    final eventTitle = isOccurrence
        ? (row['events']?['title'] as String? ?? 'this session')
        : (row['title'] as String? ?? 'this session');
    final groupName = isOccurrence
        ? (row['events']?['groups']?['name'] as String? ?? '')
        : (row['groups']?['name'] as String? ?? '');
    final label =
        groupName.isNotEmpty ? '$groupName — $eventTitle' : eventTitle;

    final confirm = await showAppDialog<bool>(
      context: context,
      title: 'Remove Lesson?',
      content: Text(
        'Remove this lesson from "$label"?',
        textAlign: TextAlign.center,
      ),
      actions: [
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ),
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(
                  color: AppColors.destructiveRed,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );

    if (confirm != true || !mounted) return;

    try {
      if (isOccurrence) {
        final eventId = row['events']?['id'] as String?;
        if (eventId != null) {
          await context
              .read<EventProvider>()
              .detachLessonFromOccurrence(eventId, row['id'] as String);
        }
      } else {
        await context
            .read<EventProvider>()
            .detachLesson(row['id'] as String);
      }
      await _fetchAttached();
      widget.onChanged();
    } catch (_) {
      if (mounted) Toast.error(context, 'Failed to remove from session.');
    }
  }

  Future<void> _showGroupPicker() async {
    // For unsaved lessons, save to DB first so the FK constraint is satisfied.
    if (widget.onBeforeAttach != null && _resolvedLessonId == null) {
      final newId = await widget.onBeforeAttach!();
      if (newId == null || !mounted) return;
      setState(() => _resolvedLessonId = newId);
    }

    final groups = context.read<GroupProvider>().groups;

    if (groups.isEmpty) {
      await showCreateGroupDialog(
        context,
        onGroupCreated: (newGroup) {
          _showEventPicker(newGroup);
        },
      );
      return;
    }

    if (!mounted) return;

    final selectedGroup = await showAppDialog<Group>(
      context: context,
      title: 'Pick a Group',
      content: Builder(
        builder: (ctx) => _PagedGroupPicker(
          groups: groups,
          onSelected: (g) => Navigator.pop(ctx, g),
          onCreateGroup: () async {
            Navigator.pop(ctx);
            await showCreateGroupDialog(
              context,
              onGroupCreated: (newGroup) {
                _showEventPicker(newGroup);
              },
            );
          },
        ),
      ),
      actions: [
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );

    if (selectedGroup == null || !mounted) return;

    await _showEventPicker(selectedGroup);
  }

  Future<void> _showEventPicker(Group group) async {
    final eventProvider = context.read<EventProvider>();

    List<Event> groupEvents =
        eventProvider.events.where((e) => e.groupId == group.id).toList();

    if (groupEvents.isEmpty) {
      try {
        await eventProvider.fetchEvents(group.id);
        groupEvents =
            eventProvider.events.where((e) => e.groupId == group.id).toList();
      } catch (_) {}
    }

    // Already-attached event ids (single-shot)
    final attachedEventIds = _attachedEvents
        .where((r) => r['_source'] == 'event')
        .map((r) => r['id'] as String)
        .toSet();

    // Already-attached occurrence ids
    final attachedOccurrenceIds = _attachedEvents
        .where((r) => r['_source'] == 'occurrence')
        .map((r) => r['id'] as String)
        .toSet();

    // For single-shot events, exclude already-attached ones.
    // For recurring events, always show (occurrence picker handles exclusion).
    final available = groupEvents.where((e) {
      if (!e.isRecurring) return !attachedEventIds.contains(e.id);
      return true;
    }).toList();

    if (!mounted) return;

    if (available.isEmpty) {
      await showCreateSessionDialog(
        context,
        groupId: group.id,
        onSessionCreated: (newEvent) {
          if (newEvent.isRecurring) {
            _showOccurrencePicker(newEvent, attachedOccurrenceIds);
          } else {
            _attachToEvent(newEvent);
          }
        },
      );
      return;
    }

    final selectedEvent = await showAppDialog<Event>(
      context: context,
      title: group.name,
      content: Builder(
        builder: (ctx) => _PagedEventPicker(
          events: available,
          onSelected: (e) => Navigator.pop(ctx, e),
          onCreateSession: () async {
            Navigator.pop(ctx);
            await showCreateSessionDialog(
              context,
              groupId: group.id,
              onSessionCreated: (newEvent) {
                if (newEvent.isRecurring) {
                  _showOccurrencePicker(newEvent, attachedOccurrenceIds);
                } else {
                  _attachToEvent(newEvent);
                }
              },
            );
          },
        ),
      ),
      actions: [
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );

    if (selectedEvent == null || !mounted) return;

    if (selectedEvent.isRecurring) {
      await _showOccurrencePicker(selectedEvent, attachedOccurrenceIds);
    } else {
      await _attachToEvent(selectedEvent);
    }
  }

  Future<void> _showOccurrencePicker(
      Event event, Set<String> attachedOccurrenceIds) async {
    final available = event.occurrences
        .where((o) => !attachedOccurrenceIds.contains(o.id))
        .toList();

    if (!mounted) return;

    if (available.isEmpty) {
      await showAppDialog<void>(
        context: context,
        title: 'No Occurrences Available',
        content: Text(
          'All occurrences of "${event.title}" already have a lesson attached.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Builder(
            builder: (ctx) => TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
      return;
    }

    final selectedOccurrence = await showAppDialog<EventOccurrence>(
      context: context,
      title: event.title.isEmpty ? 'Pick a Date' : event.title,
      content: Builder(
        builder: (ctx) => _PagedOccurrencePicker(
          occurrences: available,
          onSelected: (o) => Navigator.pop(ctx, o),
        ),
      ),
      actions: [
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );

    if (selectedOccurrence == null || !mounted) return;

    try {
      await context.read<EventProvider>().attachLessonToOccurrence(
            event.id,
            selectedOccurrence.id,
            _effectiveLessonId,
          );
      await _fetchAttached();
      widget.onChanged();
      if (mounted) Toast.success(context, 'Lesson added to session!');
    } catch (_) {
      if (mounted) Toast.error(context, 'Failed to attach lesson to session.');
    }
  }

  Future<void> _attachToEvent(Event event) async {
    try {
      await context.read<EventProvider>().attachLesson(event.id, _effectiveLessonId);
      await _fetchAttached();
      widget.onChanged();
      if (mounted) Toast.success(context, 'Lesson added to session!');
    } catch (_) {
      if (mounted) Toast.error(context, 'Failed to attach lesson to session.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._attachedEvents.map((r) => _AttachedEventRow(
              row: r,
              onRemove: () => _confirmDetach(r),
            )),

        if (widget.lessonId.isNotEmpty)
          InkWell(
            onTap: _showGroupPicker,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  AppIcons.group(size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _attachedEvents.isEmpty
                          ? 'Add to a group event (optional)'
                          : 'Add to another group event',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  AppIcons.chevronRight(size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Attached event/occurrence row with remove button
// ---------------------------------------------------------------------------

class _AttachedEventRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback onRemove;

  const _AttachedEventRow({required this.row, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isOccurrence = row['_source'] == 'occurrence';

    final String title;
    final String groupName;
    final DateTime? date;

    if (isOccurrence) {
      title = row['events']?['title'] as String? ?? 'Untitled Session';
      groupName = row['events']?['groups']?['name'] as String? ?? '';
      date = row['occurrence_date'] != null
          ? DateTime.tryParse(row['occurrence_date'] as String)?.toLocal()
          : null;
    } else {
      title = row['title'] as String? ?? 'Untitled Session';
      groupName = row['groups']?['name'] as String? ?? '';
      date = row['date'] != null
          ? DateTime.tryParse(row['date'] as String)?.toLocal()
          : null;
    }

    final dateStr =
        date != null ? '${date.month}/${date.day}/${date.year}' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          AppIcons.calendar(size: 16, color: AppColors.primaryMidTeal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName.isNotEmpty ? '$groupName — $title' : title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryMidTeal,
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AppIcons.close(size: 16, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Paged group picker
// ---------------------------------------------------------------------------

const int _kGroupPageSize = 5;

class _PagedGroupPicker extends StatefulWidget {
  final List<Group> groups;
  final void Function(Group) onSelected;
  final VoidCallback onCreateGroup;

  const _PagedGroupPicker({
    required this.groups,
    required this.onSelected,
    required this.onCreateGroup,
  });

  @override
  State<_PagedGroupPicker> createState() => _PagedGroupPickerState();
}

class _PagedGroupPickerState extends State<_PagedGroupPicker> {
  int _page = 0;

  int get _totalPages => (widget.groups.length / _kGroupPageSize).ceil();

  List<Group> get _currentPageGroups {
    final start = _page * _kGroupPageSize;
    final end = (start + _kGroupPageSize).clamp(0, widget.groups.length);
    return widget.groups.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._currentPageGroups.map(
          (g) => _PickerTile(
            label: g.name,
            icon: AppIcons.group(size: 18, color: Colors.black),
            onTap: () => widget.onSelected(g),
          ),
        ),
        if (_totalPages > 1) ...[
          const SizedBox(height: 8),
          _PaginationRow(
            page: _page,
            totalPages: _totalPages,
            onPrev: _page > 0 ? () => setState(() => _page--) : null,
            onNext:
                _page < _totalPages - 1 ? () => setState(() => _page++) : null,
          ),
        ],
        const SizedBox(height: 4),
        _PickerTile(
          label: 'New Group',
          icon: AppIcons.add(size: 18, color: Colors.black),
          onTap: widget.onCreateGroup,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Paged event picker
// ---------------------------------------------------------------------------

const int _kEventPageSize = 5;

class _PagedEventPicker extends StatefulWidget {
  final List<Event> events;
  final void Function(Event) onSelected;
  final VoidCallback onCreateSession;

  const _PagedEventPicker({
    required this.events,
    required this.onSelected,
    required this.onCreateSession,
  });

  @override
  State<_PagedEventPicker> createState() => _PagedEventPickerState();
}

class _PagedEventPickerState extends State<_PagedEventPicker> {
  int _page = 0;

  int get _totalPages => (widget.events.length / _kEventPageSize).ceil();

  List<Event> get _currentPageEvents {
    final start = _page * _kEventPageSize;
    final end = (start + _kEventPageSize).clamp(0, widget.events.length);
    return widget.events.sublist(start, end);
  }

  String _sublabel(Event e) {
    if (e.isRecurring) {
      final freq = e.recurrenceFrequency;
      final freqStr = freq == RecurrenceFrequency.weekly
          ? 'Weekly'
          : freq == RecurrenceFrequency.biweekly
              ? 'Every 2 weeks'
              : 'Monthly';
      return '$freqStr · ${e.occurrences.length} occurrences';
    }
    return '${e.date.month}/${e.date.day}/${e.date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._currentPageEvents.map(
          (e) => _PickerTile(
            label: e.title.isEmpty ? 'Untitled Session' : e.title,
            sublabel: _sublabel(e),
            icon: AppIcons.calendar(size: 18, color: Colors.black),
            onTap: () => widget.onSelected(e),
          ),
        ),
        if (_totalPages > 1) ...[
          const SizedBox(height: 8),
          _PaginationRow(
            page: _page,
            totalPages: _totalPages,
            onPrev: _page > 0 ? () => setState(() => _page--) : null,
            onNext:
                _page < _totalPages - 1 ? () => setState(() => _page++) : null,
          ),
        ],
        const SizedBox(height: 4),
        _PickerTile(
          label: 'New Session',
          icon: AppIcons.add(size: 18, color: Colors.black),
          onTap: widget.onCreateSession,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Paged occurrence picker (< > navigation)
// ---------------------------------------------------------------------------

const int _kOccurrencePageSize = 5;

class _PagedOccurrencePicker extends StatefulWidget {
  final List<EventOccurrence> occurrences;
  final void Function(EventOccurrence) onSelected;

  const _PagedOccurrencePicker({
    required this.occurrences,
    required this.onSelected,
  });

  @override
  State<_PagedOccurrencePicker> createState() =>
      _PagedOccurrencePickerState();
}

class _PagedOccurrencePickerState extends State<_PagedOccurrencePicker> {
  int _page = 0;

  int get _totalPages =>
      (widget.occurrences.length / _kOccurrencePageSize).ceil();

  List<EventOccurrence> get _currentPage {
    final start = _page * _kOccurrencePageSize;
    final end =
        (start + _kOccurrencePageSize).clamp(0, widget.occurrences.length);
    return widget.occurrences.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._currentPage.map(
          (o) => _PickerTile(
            label:
                '${o.occurrenceDate.month}/${o.occurrenceDate.day}/${o.occurrenceDate.year}',
            icon: AppIcons.calendar(size: 18, color: Colors.black),
            onTap: () => widget.onSelected(o),
          ),
        ),
        if (_totalPages > 1) ...[
          const SizedBox(height: 8),
          _PaginationRow(
            page: _page,
            totalPages: _totalPages,
            onPrev: _page > 0 ? () => setState(() => _page--) : null,
            onNext:
                _page < _totalPages - 1 ? () => setState(() => _page++) : null,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pagination row
// ---------------------------------------------------------------------------

class _PaginationRow extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationRow({
    required this.page,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 22,
        ),
        const SizedBox(width: 12),
        Text(
          '${page + 1} / $totalPages',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 22,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable picker tile
// ---------------------------------------------------------------------------

class _PickerTile extends StatelessWidget {
  final Widget icon;
  final String label;
  final String? sublabel;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                  if (sublabel != null)
                    Text(
                      sublabel!,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
            AppIcons.chevronRight(size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
