import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/group_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/ui_utils.dart';
import '../../theme/theme.dart';

class SearchPeopleScreen extends StatefulWidget {
  final String groupId;

  const SearchPeopleScreen({super.key, required this.groupId});

  @override
  State<SearchPeopleScreen> createState() => _SearchPeopleScreenState();
}

class _SearchPeopleScreenState extends State<SearchPeopleScreen> {
  final List<User> _selectedUsers = [];
  final List<User> _searchResults = [];
  bool _isSearching = false;
  bool _isAdding = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final currentUserId = context.read<UserProvider>().currentUser.id;
      final existingMemberIds = context
          .read<GroupProvider>()
          .groups
          .where((g) => g.id == widget.groupId)
          .expand((g) => g.members.map((m) => m.id))
          .toSet();

      final results = await SupabaseService.searchUsers(query);
      final filtered = results
          .where(
            (u) => u.id != currentUserId && !existingMemberIds.contains(u.id),
          )
          .toList();

      if (mounted) {
        setState(() {
          _searchResults
            ..clear()
            ..addAll(filtered);
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _confirmAddToGroup() async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    try {
      for (final user in _selectedUsers) {
        await context.read<GroupProvider>().addMember(widget.groupId, user);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add members.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Search People'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: AppIcons.search(),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'Search for people by name or email',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final isSelected =
                              _selectedUsers.any((u) => u.id == user.id);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              backgroundImage: UiUtils.getAvatarProvider(
                                user.profilePictureUrl,
                              ),
                              child: user.profilePictureUrl.isEmpty
                                  ? AppIcons.profile(color: Colors.grey)
                                  : null,
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: IconButton(
                              icon: isSelected
                                  ? AppIcons.checkCircle(color: Colors.green)
                                  : AppIcons.add(color: Colors.black),
                              onPressed: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedUsers
                                        .removeWhere((u) => u.id == user.id);
                                  } else {
                                    _selectedUsers.add(user);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
          if (_selectedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAdding ? null : _confirmAddToGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add to Group'),
                ),
              ),
            ),
        ],
      ),
    );
  }

}
