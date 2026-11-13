import 'package:flutter/material.dart';

import '../models/group.dart';
import '../models/user.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  final List<Group> _groups = [];
  bool _isLoading = false;

  List<Group> get groups => List.unmodifiable(_groups);
  bool get isLoading => _isLoading;

  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();

    try {
      final groups = await GroupService.fetchUserGroups();
      _groups
        ..clear()
        ..addAll(groups);
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Group> createGroup(
    String name,
    List<User> members,
    User creator,
  ) async {
    try {
      final memberIds = members.map((u) => u.id).toList();
      final newGroup = await GroupService.createGroup(
        name,
        memberIds,
        creator.id,
      );
      _groups.add(newGroup);
      notifyListeners();
      return newGroup;
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteGroup(String id) async {
    try {
      await GroupService.deleteGroup(id);
      _groups.removeWhere((g) => g.id == id);
      notifyListeners();
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMember(String groupId, User user) async {
    try {
      await GroupService.addMember(groupId, user.id);
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        final group = _groups[index];
        if (!group.members.any((m) => m.id == user.id)) {
          final updatedMembers = List<User>.from(group.members)..add(user);
          final newRoles = Map<String, String>.from(group.userRoles);
          newRoles[user.id] = 'Member';
          _groups[index] = group.copyWith(
            members: updatedMembers,
            userRoles: newRoles,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    try {
      await GroupService.removeMember(groupId, userId);
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        final group = _groups[index];
        final updatedMembers =
            group.members.where((m) => m.id != userId).toList();
        final newRoles = Map<String, String>.from(group.userRoles)
          ..remove(userId);
        _groups[index] = group.copyWith(
          members: updatedMembers,
          userRoles: newRoles,
        );
        notifyListeners();
      }
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  Future<void> assignRole(
    String groupId,
    String userId,
    String role,
  ) async {
    try {
      await GroupService.assignRole(groupId, userId, role);
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        final group = _groups[index];
        final newRoles = Map<String, String>.from(group.userRoles);
        newRoles[userId] = role;
        _groups[index] = group.copyWith(userRoles: newRoles);
        notifyListeners();
      }
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setGroupPrivacy(String groupId, bool isPrivate) async {
    try {
      await GroupService.setGroupPrivacy(groupId, isPrivate);
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = _groups[index].copyWith(isPrivate: isPrivate);
        notifyListeners();
      }
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  Future<String> generateAddCode(String groupId) async {
    try {
      final code = await GroupService.generateAndSetAddCode(groupId);
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = _groups[index].copyWith(addCode: code);
        notifyListeners();
      }
      return code;
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setGroupPhoto(String groupId, String photoUrl) async {
    try {
      await GroupService.setGroupPhoto(groupId, photoUrl);
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = _groups[index].copyWith(groupPhotoUrl: photoUrl);
        notifyListeners();
      }
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    try {
      await GroupService.updateGroup(groupId, {'name': newName});
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = _groups[index].copyWith(name: newName);
        notifyListeners();
      }
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  void clear() {
    _groups.clear();
    notifyListeners();
  }
}
