import 'user.dart';

class Group {
  final String id;
  final String name;
  final String iconUrl;
  final String groupPhotoUrl;
  final bool isPrivate;
  final String addCode;
  final Map<String, String> userRoles;
  final List<User> members;

  Group({
    required this.id,
    required this.name,
    this.iconUrl = '',
    this.groupPhotoUrl = '',
    this.isPrivate = false,
    this.addCode = '',
    this.userRoles = const {},
    required this.members,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    final membersData = (map['group_members'] as List<dynamic>?) ?? [];
    final Map<String, String> userRoles = {};
    final List<User> members = [];

    for (final memberRow in membersData) {
      final userId = memberRow['user_id'] as String;
      final role = memberRow['role'] as String;
      userRoles[userId] = role;
      if (memberRow['profiles'] != null) {
        members.add(
          User.fromMap(memberRow['profiles'] as Map<String, dynamic>),
        );
      }
    }

    return Group(
      id: map['id'] as String,
      name: map['name'] as String,
      iconUrl: (map['icon_url'] as String?) ?? '',
      groupPhotoUrl: (map['group_photo_url'] as String?) ?? '',
      isPrivate: (map['is_private'] as bool?) ?? false,
      addCode: (map['add_code'] as String?) ?? '',
      userRoles: userRoles,
      members: members,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon_url': iconUrl,
      'group_photo_url': groupPhotoUrl,
      'is_private': isPrivate,
      'add_code': addCode.isEmpty ? null : addCode,
    };
  }

  Group copyWith({
    String? name,
    String? iconUrl,
    String? groupPhotoUrl,
    bool? isPrivate,
    String? addCode,
    Map<String, String>? userRoles,
    List<User>? members,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      groupPhotoUrl: groupPhotoUrl ?? this.groupPhotoUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      addCode: addCode ?? this.addCode,
      userRoles: userRoles ?? this.userRoles,
      members: members ?? this.members,
    );
  }
}
