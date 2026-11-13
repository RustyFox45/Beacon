import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/group.dart';
import '../../providers/event_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/ui_utils.dart';
import '../../widgets/app_dialog.dart';
import 'create_session_sheet.dart';
import 'event_screen.dart';
import 'group_members_screen.dart';
import 'search_people_screen.dart';
import '../../theme/theme.dart';

class GroupManagementScreen extends StatefulWidget {
  final Group group;

  const GroupManagementScreen({super.key, required this.group});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EventProvider>().fetchEvents(widget.group.id);
      }
    });
  }

  Future<void> _pickGroupPhoto(BuildContext context, String groupId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null || !context.mounted) return;

    try {
      final url = await SupabaseService.uploadGroupPhoto(groupId, image.path);
      if (context.mounted) {
        await context.read<GroupProvider>().setGroupPhoto(groupId, url);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload photo.')),
        );
      }
    }
  }

  void _showVisibilityDialog(BuildContext context, Group currentGroup) {
    bool isPrivate = currentGroup.isPrivate;
    showAppDialog(
      context: context,
      title: 'Group Visibility',
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose who can join and view your group details.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isPrivate ? 'Private' : 'Public',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Switch(
                    value: isPrivate,
                    onChanged: (val) async {
                      setState(() => isPrivate = val);
                      try {
                        await context
                            .read<GroupProvider>()
                            .setGroupPrivacy(currentGroup.id, val);
                      } catch (_) {
                        setState(() => isPrivate = !val);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update privacy.'),
                            ),
                          );
                        }
                      }
                    },
                    activeColor: Colors.black,
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        Builder(
          builder: (dialogContext) => TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddCodeDialog(BuildContext context, String code) {
    final messenger = ScaffoldMessenger.of(context);
    showAppDialog(
      context: context,
      title: 'Group Add Code',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Share this code with others so they can join your group.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Builder(
          builder: (dialogContext) => TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ),
        Builder(
          builder: (dialogContext) => ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(dialogContext);
              messenger.showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  void _showRenameGroupDialog(BuildContext context, Group currentGroup) {
    final controller = TextEditingController(text: currentGroup.name);
    // Capture provider and messenger before the dialog opens so async
    // callbacks never touch a potentially-deactivated BuildContext.
    final provider = context.read<GroupProvider>();
    final messenger = ScaffoldMessenger.of(context);
    String? errorText;

    showAppDialog(
      context: context,
      title: 'Rename Group',
      content: StatefulBuilder(
        builder: (context, setState) {
          return TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Group Name',
              errorText: errorText,
              filled: true,
              fillColor: Colors.black.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) {
              if (errorText != null) setState(() => errorText = null);
            },
          );
        },
      ),
      actions: [
        Builder(
          builder: (dialogContext) => TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ),
        Builder(
          builder: (dialogContext) => TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                return;
              }
              if (newName == currentGroup.name) {
                Navigator.pop(dialogContext);
                return;
              }
              Navigator.pop(dialogContext);
              try {
                await provider.renameGroup(currentGroup.id, newName);
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Failed to rename group.')),
                  );
                }
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _showAdminMenu(BuildContext context, Group currentGroup) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Admin Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: AppIcons.edit(),
                title: const Text('Rename Group', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameGroupDialog(context, currentGroup);
                },
              ),
              ListTile(
                leading: AppIcons.privacy(),
                title: const Text('Change Group Visibility', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showVisibilityDialog(context, currentGroup);
                },
              ),
              ListTile(
                leading: AppIcons.key(),
                title: const Text('Show Group Add Code', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final String code;
                    if (currentGroup.addCode.isEmpty) {
                      code = await context
                          .read<GroupProvider>()
                          .generateAddCode(currentGroup.id);
                    } else {
                      code = currentGroup.addCode;
                    }
                    if (context.mounted) _showAddCodeDialog(context, code);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to generate code.'),
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: AppIcons.delete(color: AppColors.destructiveRed),
                title: const Text(
                  'Delete Group',
                  style: TextStyle(color: AppColors.destructiveRed, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final provider = context.read<GroupProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showAppDialog(
      context: context,
      title: 'Delete Group',
      content: const Text(
        'Are you sure you want to delete this group?',
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
              Navigator.pop(dialogContext); // Close dialog
              try {
                await provider.deleteGroup(widget.group.id);
                navigator.pop(); // Go back to groups list
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Failed to delete group.')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.destructiveRed, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final currentGroup = groupProvider.groups.firstWhere(
      (g) => g.id == widget.group.id,
      orElse: () => widget.group,
    );

    final currentUser = context.read<UserProvider>().currentUser;
    final currentUserRole = currentGroup.userRoles[currentUser.id] ?? 'Member';
    final isAdmin = currentUserRole == 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(currentGroup.name.toUpperCase()),
        actions: isAdmin
            ? [
                IconButton(
                  icon: AppIcons.moreVert(color: AppColors.beaconYellow),
                  onPressed: () => _showAdminMenu(context, currentGroup),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Photo
            GestureDetector(
              onTap: isAdmin
                  ? () => _pickGroupPhoto(context, currentGroup.id)
                  : null,
              child: Container(
                width: double.infinity,
                height: 180,
                color: Colors.grey[300],
                child: currentGroup.groupPhotoUrl.isNotEmpty
                    ? Image.network(
                        currentGroup.groupPhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            AppIcons.group(size: 80, color: Colors.grey[500]),
                      )
                    : AppIcons.group(size: 80, color: Colors.grey[500]),
              ),
            ),
            if (isAdmin && currentGroup.groupPhotoUrl.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Tap banner to set a group photo',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Members Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GroupMembersScreen(group: currentGroup),
                        ),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),

            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: currentGroup.members.length,
                itemBuilder: (context, index) {
                  final member = currentGroup.members[index];
                  final role =
                      currentGroup.userRoles[member.id] ?? 'Member';

                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: UiUtils.getAvatarProvider(
                            member.profilePictureUrl,
                          ),
                          child: member.profilePictureUrl.isEmpty
                              ? AppIcons.profile(color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          UiUtils.formatShortName(member.name),
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          role,
                          style: TextStyle(
                            fontSize: 10,
                            color: role == 'Admin'
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Events Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Group Events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isAdmin)
                    IconButton(
                      icon: AppIcons.add(),
                      onPressed: () => showCreateSessionDialog(context, groupId: currentGroup.id),
                    ),
                ],
              ),
            ),

            Consumer<EventProvider>(
              builder: (context, eventProvider, child) {
                if (eventProvider.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (eventProvider.errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      eventProvider.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                final events = eventProvider.events
                    .where((e) => e.groupId == currentGroup.id)
                    .toList();
                events.sort(
                  (a, b) => b.date.compareTo(a.date),
                );

                if (events.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('No events for this group.'),
                  );
                }

                return Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventScreen(
                                event: event,
                                group: currentGroup,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                event.title.isEmpty ? 'Untitled Event' : event.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${event.date.month}/${event.date.day}/${event.date.year}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SearchPeopleScreen(groupId: currentGroup.id),
                  ),
                );
              },
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              child: AppIcons.groupAdd(color: Colors.white),
            )
          : null,
    );
  }
}
