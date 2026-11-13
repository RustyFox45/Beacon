import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/ui_utils.dart';
import '../../widgets/custom_drawer.dart';
import 'create_group_dialog.dart';
import 'group_management_screen.dart';
import '../profile/profile_screen.dart';
import '../../theme/theme.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showCreateGroupDialog() {
    showCreateGroupDialog(
      context,
      onGroupCreated: (newGroup) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupManagementScreen(group: newGroup),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final groups = groupProvider.groups;
    final currentUser = context.watch<UserProvider>().currentUser;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(activeRoute: 'groups'),
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
      body: groupProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : groups.isEmpty
          ? const Center(child: Text('No groups yet. Create one!'))
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    backgroundImage: UiUtils.getAvatarProvider(
                      group.groupPhotoUrl,
                    ),
                    child: group.groupPhotoUrl.isEmpty
                        ? AppIcons.group(color: Colors.grey)
                        : null,
                  ),
                  title: Text(group.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GroupManagementScreen(group: group),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppColors.primaryDarkTeal,
        foregroundColor: AppColors.beaconYellow,
        child: AppIcons.add(color: Colors.white),
      ),
    );
  }
}
