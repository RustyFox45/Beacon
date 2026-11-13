import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/group.dart';
import '../../providers/group_provider.dart';
import '../../providers/user_provider.dart';

/// Shows a "New Group" dialog and calls [onGroupCreated] with
/// the newly created group on success.
///
/// Use via [showCreateGroupDialog] rather than instantiating directly.
Future<void> showCreateGroupDialog(
  BuildContext context, {
  required void Function(Group group) onGroupCreated,
}) {
  return showDialog(
    context: context,
    builder: (_) => _CreateGroupDialogContent(onGroupCreated: onGroupCreated),
  );
}

class _CreateGroupDialogContent extends StatefulWidget {
  final void Function(Group group) onGroupCreated;

  const _CreateGroupDialogContent({required this.onGroupCreated});

  @override
  State<_CreateGroupDialogContent> createState() =>
      _CreateGroupDialogContentState();
}

class _CreateGroupDialogContentState
    extends State<_CreateGroupDialogContent> {
  final _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isCreating) return;

    setState(() => _isCreating = true);
    try {
      final currentUser = context.read<UserProvider>().currentUser;
      final newGroup = await context
          .read<GroupProvider>()
          .createGroup(name, [], currentUser);
      if (mounted) {
        Navigator.pop(context);
        widget.onGroupCreated(newGroup);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _nameController.text.trim().isNotEmpty && !_isCreating;

    return PopScope(
      canPop: !_isCreating,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'New Group',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Group name',
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: canSubmit ? (_) => _submit() : null,
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed:
                          _isCreating ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: canSubmit ? _submit : null,
                      child: _isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Create',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legacy widget kept for backward compatibility. Prefer [showCreateGroupDialog].
@Deprecated('Use showCreateGroupDialog instead')
class CreateGroupDialog extends StatelessWidget {
  final void Function(Group group) onGroupCreated;

  const CreateGroupDialog({super.key, required this.onGroupCreated});

  @override
  Widget build(BuildContext context) {
    return _CreateGroupDialogContent(onGroupCreated: onGroupCreated);
  }
}
