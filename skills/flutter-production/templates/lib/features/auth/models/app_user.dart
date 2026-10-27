import 'package:flutter/foundation.dart';

/// Signed-in user. Extend with the fields the backend returns.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String role;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    role: json['role'] as String? ?? 'customer',
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'email': email,
    'phone': phone,
    'avatar_url': avatarUrl,
  };
}
