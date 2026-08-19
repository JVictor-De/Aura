/// Entidade User do domínio.
///
/// Referência: ARCHITECTURE.md §ERD: USERS
class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String role;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    String? name,
    this.phone,
    String? role,
    this.avatarUrl,
  }) : role = role ?? 'customer';

  /// Getter de conveniência — retorna fullName ou name
  String get name => fullName ?? '';

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String? ?? json['name'] as String?,
        phone: json['phone'] as String?,
        role: json['role'] as String? ?? 'customer',
        avatarUrl: json['avatar_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': role,
        'avatar_url': avatarUrl,
      };
}
