import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../utils/toasts.dart';
import '../../theme/theme.dart';
import '../../widgets/app_dialog.dart';

/// Opens a glass dialog to add, change, or remove the recurrence rule on an
/// existing event. Pre-fills the current rule if one exists.
///
/// - Selecting a frequency + end date and saving regenerates all occurrences.
/// - Selecting "Does not repeat" removes all occurrences and reverts to single-shot.
Future<void> showSetRecurrenceDialog(
  BuildContext context, {
  required Event event,
}) async {
  final eventProvider = context.read<EventProvider>();

  await showAppDialog<void>(
    context: context,
    title: 'Set Recurrence',
    content: _SetRecurrenceForm(
      event: event,
      eventProvider: eventProvider,
    ),
  );
}

class _SetRecurrenceForm extends StatefulWidget {
  final Event event;
  final EventProvider eventProvider;

  const _SetRecurrenceForm({
    required this.event,
    required this.eventProvider,
  });

  @override
  State<_SetRecurrenceForm> createState() => _SetRecurrenceFormState();
}

class _SetRecurrenceFormState extends State<_SetRecurrenceForm> {
  late RecurrenceFrequency? _frequency;
  late DateTime? _endDate;
  late DateTime _startDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _frequency = widget.event.recurrenceFrequency;
    _endDate = widget.event.recurrenceEndDate;
    _startDate = widget.event.date;
  }

  bool get _isRecurring => _frequency != null;

  bool get _hasLessonsAttached =>
      widget.event.occurrences.any((o) => o.lessonPlanId != null);

  bool get _canSave {
    final sameFrequency = _frequency == widget.event.recurrenceFrequency;
    final sameEndDate = _endDate == widget.event.recurrenceEndDate;
    final sameStartDate = _startDate == widget.event.date;
    if (sameFrequency && sameEndDate && sameStartDate) return false;

    // Recurring requires an end date
    if (_isRecurring && _endDate == null) return false;

    return true;
  }

  Future<void> _save() async {
    if (!_canSave || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      if (_frequency == null) {
        await widget.eventProvider.removeRecurrence(
          widget.event.id,
          startDate: _startDate,
        );
        if (mounted) {
          Navigator.pop(context);
          Toast.success(context, 'Recurrence removed.');
        }
      } else {
        await widget.eventProvider.setRecurrence(
          widget.event.id,
          _frequency!,
          _endDate!,
          startDate: _startDate,
        );
        if (mounted) {
          Navigator.pop(context);
          Toast.success(context, 'Recurrence updated.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        Toast.error(context, 'Failed to update recurrence.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning if existing occurrences have lessons attached
        if (_hasLessonsAttached) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Some occurrences have lessons attached. Changing recurrence will remove all occurrences and detach those lessons.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.orange[800]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Start date
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${_startDate.month}/${_startDate.day}/${_startDate.year}',
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                      // Reset end date if it's now before the new start
                      if (_endDate != null &&
                          !_endDate!.isAfter(_startDate)) {
                        _endDate = null;
                      }
                    });
                  }
                },
                child: const Text('Change',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Repeat frequency
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Repeat',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w600),
              ),
              DropdownButton<RecurrenceFrequency?>(
                value: _frequency,
                underline: const SizedBox.shrink(),
                style: const TextStyle(
                    color: AppColors.primaryMidTeal,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Does not repeat',
                        style: TextStyle(color: Colors.black54)),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceFrequency.weekly,
                    child: Text('Weekly'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceFrequency.biweekly,
                    child: Text('Every 2 weeks'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceFrequency.monthly,
                    child: Text('Monthly'),
                  ),
                ],
                onChanged: (val) => setState(() {
                  _frequency = val;
                  if (val == null) _endDate = null;
                }),
              ),
            ],
          ),
        ),

        // End date — only shown when a frequency is selected
        if (_isRecurring) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: _endDate == null ? 0.03 : 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _endDate != null
                          ? 'End: ${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                          : 'End date',
                      style: TextStyle(
                        color: _endDate != null
                            ? Colors.black
                            : Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_endDate == null) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '(required)',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.destructiveRed),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ??
                          _startDate.add(const Duration(days: 30)),
                      firstDate: _startDate.add(const Duration(days: 1)),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                  child: Text(
                    _endDate != null ? 'Change' : 'Pick',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Cancel / Save row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed:
                  _isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 8),
            _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _canSave ? _save : null,
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _canSave
                            ? AppColors.primaryMidTeal
                            : Colors.grey[400],
                      ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }
}
