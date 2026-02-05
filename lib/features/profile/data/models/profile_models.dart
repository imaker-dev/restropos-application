/// API Models for Profile Module

class UserProfile {
  final int id;
  final String uuid;
  final String employeeCode;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final bool isVerified;
  final DateTime? lastLoginAt;
  final List<UserRole> roles;
  final List<String> permissions;
  final Map<String, List<String>> permissionsByModule;

  const UserProfile({
    required this.id,
    required this.uuid,
    required this.employeeCode,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.isActive,
    required this.isVerified,
    this.lastLoginAt,
    required this.roles,
    required this.permissions,
    required this.permissionsByModule,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Parse roles
    final List<UserRole> roles = [];
    if (json['roles'] != null) {
      final rolesList = json['roles'] as List;
      for (final role in rolesList) {
        roles.add(UserRole.fromJson(role as Map<String, dynamic>));
      }
    }

    // Parse permissions
    final List<String> permissions = [];
    if (json['permissions'] != null) {
      final permissionsList = json['permissions'] as List;
      permissions.addAll(permissionsList.map((e) => e.toString()));
      }

    // Parse permissions by module
    final Map<String, List<String>> permissionsByModule = {};
    if (json['permissionsByModule'] != null) {
      final modules = json['permissionsByModule'] as Map<String, dynamic>;
      modules.forEach((key, value) {
        if (value is List) {
          permissionsByModule[key] = value.map((e) => e.toString()).toList();
        }
      });
    }

    // Parse lastLoginAt
    DateTime? lastLoginAt;
    if (json['lastLoginAt'] != null) {
      lastLoginAt = DateTime.parse(json['lastLoginAt'].toString());
    }

    return UserProfile(
      id: json['id'] as int? ?? 0,
      uuid: json['uuid'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isActive: (json['isActive'] as int? ?? 0) == 1,
      isVerified: (json['isVerified'] as int? ?? 0) == 1,
      lastLoginAt: lastLoginAt,
      roles: roles,
      permissions: permissions,
      permissionsByModule: permissionsByModule,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'employeeCode': employeeCode,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'isActive': isActive ? 1 : 0,
      'isVerified': isVerified ? 1 : 0,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'roles': roles.map((role) => role.toJson()).toList(),
      'permissions': permissions,
      'permissionsByModule': permissionsByModule,
    };
  }

  UserProfile copyWith({
    int? id,
    String? uuid,
    String? employeeCode,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    bool? isActive,
    bool? isVerified,
    DateTime? lastLoginAt,
    List<UserRole>? roles,
    List<String>? permissions,
    Map<String, List<String>>? permissionsByModule,
  }) {
    return UserProfile(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      employeeCode: employeeCode ?? this.employeeCode,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      permissionsByModule: permissionsByModule ?? this.permissionsByModule,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.uuid == uuid &&
        other.employeeCode == employeeCode &&
        other.name == name &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        uuid.hashCode ^
        employeeCode.hashCode ^
        name.hashCode ^
        email.hashCode;
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, uuid: $uuid, employeeCode: $employeeCode, name: $name, email: $email)';
  }
}

class UserRole {
  final int id;
  final String name;
  final String slug;
  final int outletId;
  final String outletName;

  const UserRole({
    required this.id,
    required this.name,
    required this.slug,
    required this.outletId,
    required this.outletName,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      outletId: json['outletId'] as int? ?? 0,
      outletName: json['outletName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'outletId': outletId,
      'outletName': outletName,
    };
  }

  UserRole copyWith({
    int? id,
    String? name,
    String? slug,
    int? outletId,
    String? outletName,
  }) {
    return UserRole(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      outletId: outletId ?? this.outletId,
      outletName: outletName ?? this.outletName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRole &&
        other.id == id &&
        other.name == name &&
        other.slug == slug &&
        other.outletId == outletId &&
        other.outletName == outletName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        slug.hashCode ^
        outletId.hashCode ^
        outletName.hashCode;
  }

  @override
  String toString() {
    return 'UserRole(id: $id, name: $name, slug: $slug, outletId: $outletId, outletName: $outletName)';
  }
}
