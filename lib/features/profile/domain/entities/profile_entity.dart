import '../../data/models/profile_models.dart';

/// Domain entity for User Profile
/// This represents the clean business object used throughout the app
class ProfileEntity {
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
  final List<RoleEntity> roles;
  final List<String> permissions;
  final Map<String, List<String>> permissionsByModule;

  const ProfileEntity({
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

  /// Create from API model
  factory ProfileEntity.fromModel(UserProfile model) {
    return ProfileEntity(
      id: model.id,
      uuid: model.uuid,
      employeeCode: model.employeeCode,
      name: model.name,
      email: model.email,
      phone: model.phone,
      avatarUrl: model.avatarUrl,
      isActive: model.isActive,
      isVerified: model.isVerified,
      lastLoginAt: model.lastLoginAt,
      roles: model.roles.map((role) => RoleEntity.fromModel(role)).toList(),
      permissions: model.permissions,
      permissionsByModule: model.permissionsByModule,
    );
  }

  /// Convert to API model
  UserProfile toModel() {
    return UserProfile(
      id: id,
      uuid: uuid,
      employeeCode: employeeCode,
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      isActive: isActive,
      isVerified: isVerified,
      lastLoginAt: lastLoginAt,
      roles: roles.map((role) => role.toModel()).toList(),
      permissions: permissions,
      permissionsByModule: permissionsByModule,
    );
  }

  /// Get primary role (first role in the list)
  RoleEntity? get primaryRole => roles.isNotEmpty ? roles.first : null;

  /// Get display name
  String get displayName => name.isNotEmpty ? name : email;

  /// Get initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return parts[0][0] + parts[1][0];
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0];
    }
    return email[0].toUpperCase();
  }

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  /// Check if user has any permission in a module
  bool hasModulePermission(String module) {
    return permissionsByModule.containsKey(module) && 
           permissionsByModule[module]!.isNotEmpty;
  }

  /// Get permissions for a specific module
  List<String> getModulePermissions(String module) {
    return permissionsByModule[module] ?? [];
  }

  ProfileEntity copyWith({
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
    List<RoleEntity>? roles,
    List<String>? permissions,
    Map<String, List<String>>? permissionsByModule,
  }) {
    return ProfileEntity(
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
    return other is ProfileEntity &&
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
    return 'ProfileEntity(id: $id, uuid: $uuid, employeeCode: $employeeCode, name: $name, email: $email)';
  }
}

/// Domain entity for User Role
class RoleEntity {
  final int id;
  final String name;
  final String slug;
  final int outletId;
  final String outletName;

  const RoleEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.outletId,
    required this.outletName,
  });

  /// Create from API model
  factory RoleEntity.fromModel(UserRole model) {
    return RoleEntity(
      id: model.id,
      name: model.name,
      slug: model.slug,
      outletId: model.outletId,
      outletName: model.outletName,
    );
  }

  /// Convert to API model
  UserRole toModel() {
    return UserRole(
      id: id,
      name: name,
      slug: slug,
      outletId: outletId,
      outletName: outletName,
    );
  }

  /// Get display name
  String get displayName => name.isNotEmpty ? name : slug;

  RoleEntity copyWith({
    int? id,
    String? name,
    String? slug,
    int? outletId,
    String? outletName,
  }) {
    return RoleEntity(
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
    return other is RoleEntity &&
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
    return 'RoleEntity(id: $id, name: $name, slug: $slug, outletId: $outletId, outletName: $outletName)';
  }
}
