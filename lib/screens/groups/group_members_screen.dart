import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group.dart';
import '../../providers/group_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/ui_utils.dart';
import 'search_people_screen.dart';
import '../../theme/theme.dart';
import '../../widgets/app_dialog.dart';

class GroupMembersScreen extends StatelessWidget {
  final Group group;

  const GroupMembersScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final currentGroup = groupProvider.groups.firstWhere(
      (g) => g.id == group.id,
      orElse: () => group,
    );
    final currentUser = context.read<UserProvider>().currentUser;
    final currentUserRole = currentGroup.userRoles[currentUser.id] ?? 'Member';
    final isAdmin = currentUserRole == 'Admin';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Group Members'),
      ),
      body: ListView.builder(
        itemCount: currentGroup.members.length,
        itemBuilder: (context, index) {
          final member = currentGroup.members[index];
          final role = currentGroup.userRoles[member.id] ?? 'Member';
          final avatarUrl = member.profilePictureUrl;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              backgroundImage: UiUtils.getAvatarProvider(avatarUrl),
              child: avatarUrl.isEmpty
                  ? AppIcons.profile(color: Colors.grey)
                  : null,
            ),
            title: Text(member.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 12,
                      color: role == 'Admin'
                          ? Colors.blue[700]
                          : Colors.blueGrey,
                    ),
                  ),
                ),
                if (isAdmin && member.id != currentUser.id)
                  PopupMenuButton<String>(
                    icon: AppIcons.moreVert(),
                    onSelected: (value) async {
                      if (value == 'remove') {
                        final provider = context.read<GroupProvider>();
                        showAppDialog(
                          context: context,
                          title: 'Remove Member',
                          content: Text(
                            'Are you sure you want to remove ${member.name} from the group?',
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
                                    await provider.removeMember(
                                      currentGroup.id,
                                      member.id,
                                    );
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to remove member.'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Remove',
                                    style: TextStyle(
                                        color: AppColors.destructiveRed,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        );
                        return;
                      }
                      try {
                        if (value == 'admin') {
                          await context.read<GroupProvider>().assignRole(
                            currentGroup.id,
                            member.id,
                            'Admin',
                          );
                        } else if (value == 'member') {
                          await context.read<GroupProvider>().assignRole(
                            currentGroup.id,
                            member.id,
                            'Member',
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Operation failed.'),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'admin',
                            child: Text('Assign Role: Admin'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'member',
                            child: Text('Assign Role: Member'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'remove',
                            child: Text('Remove User'),
                          ),
                        ],
                  ),
              ],
            ),
          );
        },
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
              child: AppIcons.add(color: Colors.white),
            )
          : null,
    );
  }
}
