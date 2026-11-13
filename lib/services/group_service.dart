import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group.dart';
import 'supabase_service.dart';

class GroupService {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<Group> createGroup(
    String name,
    List<String> memberIds,
    String creatorId,
  ) async {
    // Uses a SECURITY DEFINER RPC that inserts the group and adds the caller
    // as Admin atomically. A direct INSERT + .select() would fail here because
    // the groups SELECT policy checks group_members membership, which doesn't
    // exist yet at the point the RETURNING clause is evaluated.
    final groupId =
        await _client.rpc('create_group', params: {'p_name': name}) as String;

    for (final memberId in memberIds) {
      if (memberId != creatorId) {
        await _client.from('group_members').insert({
          'group_id': groupId,
          'user_id': memberId,
          'role': 'Member',
        });
      }
    }

    return fetchGroup(groupId);
  }

  static Future<Group> fetchGroup(String groupId) async {
    final data = await _client
        .from('groups')
        .select(
          '*, group_members(user_id, role, profiles(id, name, email, profile_picture_url))',
        )
        .eq('id', groupId)
        .single();
    return Group.fromMap(data);
  }

  static Future<List<Group>> fetchUserGroups() async {
    final response = await _client
        .from('groups')
        .select(
          '*, group_members(user_id, role, profiles(id, name, email, profile_picture_url))',
        )
        .order('created_at');
    return response.map<Group>((data) => Group.fromMap(data)).toList();
  }

  static Future<void> updateGroup(
    String groupId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('groups').update(data).eq('id', groupId);
  }

  static Future<void> deleteGroup(String groupId) async {
    await _client.from('groups').delete().eq('id', groupId);
  }

  static Future<void> addMember(String groupId, String userId) async {
    await _client.from('group_members').upsert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'Member',
    });
  }

  static Future<void> removeMember(String groupId, String userId) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  static Future<void> assignRole(
    String groupId,
    String userId,
    String role,
  ) async {
    await _client
        .from('group_members')
        .update({'role': role})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  static Future<String> generateAndSetAddCode(String groupId) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    String code;

    do {
      code = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
      final existing = await _client
          .from('groups')
          .select('id')
          .eq('add_code', code)
          .maybeSingle();
      if (existing == null) break;
    } while (true);

    await _client
        .from('groups')
        .update({'add_code': code})
        .eq('id', groupId);
    return code;
  }

  static Future<void> setGroupPhoto(String groupId, String photoUrl) async {
    await _client
        .from('groups')
        .update({'group_photo_url': photoUrl})
        .eq('id', groupId);
  }

  static Future<void> setGroupPrivacy(
    String groupId,
    bool isPrivate,
  ) async {
    await _client
        .from('groups')
        .update({'is_private': isPrivate})
        .eq('id', groupId);
  }

  static Future<Group?> joinByCode(String code, String userId) async {
    final groupData = await _client
        .from('groups')
        .select()
        .eq('add_code', code)
        .maybeSingle();
    if (groupData == null) return null;

    final groupId = groupData['id'] as String;
    await addMember(groupId, userId);
    return fetchGroup(groupId);
  }
}
