import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../utils/toasts.dart';
import '../../theme/theme.dart';
import '../../widgets/app_dialog.dart';

/// Shows the "New Session" glass dialog (title, date, optional recurrence).
/// When a recurrence frequency is chosen, an end-date field appears and the
/// Create button is disabled until it is filled.
///
/// If [onSessionCreated] is provided, it is called with the newly created
/// [Event] after a successful creation, allowing callers to chain further
/// actions (e.g. attaching a lesson).
///
/// Call via [showCreateSessionDialog].
Future<void> showCreateSessionDialog(
  BuildContext context, {
  required String groupId,
  void Function(Event newEvent)? onSessionCreated,
}) async {
  final eventProvider = context.read<EventProvider>();

  final result = await showAppDialog<_SessionFormResult>(
    context: context,
    title: 'New Session',
    content: _SessionForm(),
  );

  if (result == null || !context.mounted) return;

  try {
    final newEvent = await eventProvider.createEvent(
      groupId,
      result.title,
      result.date,
      recurrenceFrequency: result.recurrenceFrequency,
      recurrenceEndDate: result.recurrenceEndDate,
    );
    if (context.mounted) Toast.success(context, 'Session created!');
    onSessionCreated?.call(newEvent);
  } catch (e) {
    if (context.mounted) Toast.error(context, 'Failed to create session.');
  }
}

class _SessionFormResult {
  final String title;
  final DateTime date;
  final RecurrenceFrequency? recurrenceFrequency;
  final DateTime? recurrenceEndDate;

  const _SessionFormResult({
    required this.title,
    required this.date,
    this.recurrenceFrequency,
    this.recurrenceEndDate,
  });
}

class _SessionForm extends StatefulWidget {
  const _SessionForm();

  @override
  State<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<_SessionForm> {
  String _title = '';
  DateTime _date = DateTime.now();
  RecurrenceFrequency? _recurrenceFrequency;
  DateTime? _recurrenceEndDate;

  bool get _canCreate =>
      _title.trim().isNotEmpty &&
      (_recurrenceFrequency == null || _recurrenceEndDate != null);

  @override
  Widget build(BuildContext context) {
    final isRecurring = _recurrenceFrequency != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Session Title',
            hintText: 'e.g. Family Home Evening',
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (val) => setState(() => _title = val),
        ),
        const SizedBox(height: 16),

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
                'Start: ${_date.month}/${_date.day}/${_date.year}',
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: const Text('Change',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Recurrence frequency picker
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
                value: _recurrenceFrequency,
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
                  _recurrenceFrequency = val;
                  if (val == null) _recurrenceEndDate = null;
                }),
              ),
            ],
          ),
        ),

        // End date — only shown when a frequency is selected
        if (isRecurring) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: _recurrenceEndDate == null ? 0.03 : 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _recurrenceEndDate != null
                          ? 'End: ${_recurrenceEndDate!.month}/${_recurrenceEndDate!.day}/${_recurrenceEndDate!.year}'
                          : 'End date',
                      style: TextStyle(
                        color: _recurrenceEndDate != null
                            ? Colors.black
                            : Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_recurrenceEndDate == null) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '(required)',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.destructiveRed),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _recurrenceEndDate ??
                          _date.add(const Duration(days: 30)),
                      firstDate: _date.add(const Duration(days: 1)),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _recurrenceEndDate = picked);
                    }
                  },
                  child: Text(
                    _recurrenceEndDate != null ? 'Change' : 'Pick',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Cancel / Create row — both here so they share state
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _canCreate
                  ? () => Navigator.pop(
                        context,
                        _SessionFormResult(
                          title: _title.trim(),
                          date: _date,
                          recurrenceFrequency: _recurrenceFrequency,
                          recurrenceEndDate: _recurrenceEndDate,
                        ),
                      )
                  : null,
              child: Text(
                'Create',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _canCreate ? AppColors.primaryMidTeal : Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
