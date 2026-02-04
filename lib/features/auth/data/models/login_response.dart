import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

class LoginResponse extends Equatable {
  final bool success;
  final String message;
  final LoginData? data;

  const LoginResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'Unknown error',
      data: json['data'] != null
          ? LoginData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

class LoginData extends Equatable {
  final UserDto user;
  final String accessToken;
  final String refreshToken;
  final String expiresIn;
  final String tokenType;

  const LoginData({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: json['expiresIn'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
    );
  }

  @override
  List<Object?> get props => [
    user,
    accessToken,
    refreshToken,
    expiresIn,
    tokenType,
  ];
}

class UserDto extends Equatable {
  final int id;
  final String uuid;
  final String employeeCode;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final int isActive;
  final int isVerified;
  final String? lastLoginAt;
  final List<String> roles;

  const UserDto({
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
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int? ?? 0,
      uuid: json['uuid'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as int? ?? 0,
      isVerified: json['isVerified'] as int? ?? 0,
      lastLoginAt: json['lastLoginAt'] as String?,
      roles: json['roles'] != null
          ? (json['roles'] as List<dynamic>)
                .map((e) => e as String? ?? '')
                .toList()
          : [],
    );
  }

  User toEntity() {
    return User(
      id: uuid,
      name: name,
      username: email,
      role: _mapRole(roles.isNotEmpty ? roles.first : 'captain'),
      pin: null,
      passcode: null,
      avatarUrl: avatarUrl,
      assignedFloors: [],
      assignedSections: [],
      isActive: isActive == 1,
      lastLoginAt: lastLoginAt != null ? DateTime.tryParse(lastLoginAt!) : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  UserRole _mapRole(String role) {
    switch (role.toLowerCase()) {
      case 'captain':
        return UserRole.captain;
      case 'cashier':
        return UserRole.cashier;
      case 'manager':
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.captain;
    }
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    employeeCode,
    name,
    email,
    phone,
    avatarUrl,
    isActive,
    isVerified,
    lastLoginAt,
    roles,
  ];
}
