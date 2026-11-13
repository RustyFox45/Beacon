class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String profilePictureUrl;

  User({
    required this.id,
    this.name = '',
    this.phoneNumber = '',
    this.email = '',
    this.profilePictureUrl = '',
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      phoneNumber: (map['phone_number'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      profilePictureUrl: (map['profile_picture_url'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'profile_picture_url': profilePictureUrl,
    };
  }

  User copyWith({
    String? name,
    String? phoneNumber,
    String? email,
    String? profilePictureUrl,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
