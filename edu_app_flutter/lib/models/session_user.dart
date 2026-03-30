class SessionUser {
  const SessionUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatar,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String avatar;

  factory SessionUser.empty({required String uid}) {
    return SessionUser(
      uid: uid,
      fullName: '',
      email: '',
      phone: '',
      avatar: '',
    );
  }

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      uid: _firstNonEmpty([
        json['uid'],
        json['id'],
      ]),
      fullName: _firstNonEmpty([
        json['full_name'],
        json['fullName'],
        json['display_name'],
        json['displayName'],
        json['name'],
      ]),
      email: _firstNonEmpty([
        json['email'],
        json['email_address'],
        json['emailAddress'],
      ]),
      phone: _firstNonEmpty([
        json['phone'],
        json['phone_number'],
        json['phoneNumber'],
      ]),
      avatar: _firstNonEmpty([
        json['avatar'],
        json['avatar_url'],
        json['avatarUrl'],
        json['photo_url'],
        json['photoUrl'],
        json['photoURL'],
        json['picture'],
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
    };
  }

  SessionUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? avatar,
  }) {
    return SessionUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
    );
  }

  SessionUser mergePreferNonEmpty(SessionUser other) {
    String pick(String current, String incoming) {
      return incoming.trim().isNotEmpty ? incoming : current;
    }

    return SessionUser(
      uid: pick(uid, other.uid),
      fullName: pick(fullName, other.fullName),
      email: pick(email, other.email),
      phone: pick(phone, other.phone),
      avatar: pick(avatar, other.avatar),
    );
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }
}
