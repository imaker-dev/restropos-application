import 'package:equatable/equatable.dart';

enum UserRole {
  captain,
  cashier,
  manager,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.captain:
        return 'Captain';
      case UserRole.cashier:
        return 'Cashier';
      case UserRole.manager:
        return 'Manager';
      case UserRole.admin:
        return 'Admin';
    }
  }

  bool get canAccessBilling => this != UserRole.captain;
  bool get canAccessReports => this == UserRole.manager || this == UserRole.admin;
  bool get canManageUsers => this == UserRole.admin;
  bool get canModifyMenu => this == UserRole.manager || this == UserRole.admin;
  bool get canVoidOrders => this != UserRole.captain;
  bool get canApplyDiscounts => this != UserRole.captain;
}

class User extends Equatable {
  final String id;
  final String name;
  final String username;
  final UserRole role;
  final String? pin;
  final String? passcode;
  final String? avatarUrl;
  final List<String> assignedFloors;
  final List<String> assignedSections;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.pin,
    this.passcode,
    this.avatarUrl,
    this.assignedFloors = const [],
    this.assignedSections = const [],
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? username,
    UserRole? role,
    String? pin,
    String? passcode,
    String? avatarUrl,
    List<String>? assignedFloors,
    List<String>? assignedSections,
    bool? isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      passcode: passcode ?? this.passcode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      assignedFloors: assignedFloors ?? this.assignedFloors,
      assignedSections: assignedSections ?? this.assignedSections,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'role': role.name,
      'pin': pin,
      'passcode': passcode,
      'avatarUrl': avatarUrl,
      'assignedFloors': assignedFloors,
      'assignedSections': assignedSections,
      'isActive': isActive,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.captain,
      ),
      pin: json['pin'] as String?,
      passcode: json['passcode'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      assignedFloors: (json['assignedFloors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      assignedSections: (json['assignedSections'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        username,
        role,
        pin,
        passcode,
        avatarUrl,
        assignedFloors,
        assignedSections,
        isActive,
        lastLoginAt,
        createdAt,
        updatedAt,
      ];
}
