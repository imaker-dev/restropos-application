/// API Models for Authentication Module

class LoginRequest {
  final String email;
  final String password;
  final String deviceType;

  const LoginRequest({
    required this.email,
    required this.password,
    this.deviceType = 'captain_app',
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'deviceType': deviceType,
  };
}

class PinLoginRequest {
  final String employeeCode;
  final String pin;
  dynamic outletId;
  final String deviceType;

   PinLoginRequest({
    required this.employeeCode,
    required this.pin,
     this.outletId,
    this.deviceType = 'captain_app',
  });

  Map<String, dynamic> toJson() => {
    'employeeCode': employeeCode,
    'pin': pin,
    'outletId': outletId,
    'deviceType': deviceType,
  };
}

class LoginResponse {
  final String accessToken;
  final String? refreshToken;
  final dynamic expiresIn;
  final ApiUser user;

  const LoginResponse({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] ,
      user: ApiUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class PinLoginResponse {
  final String accessToken;
  final String? refreshToken;
  final dynamic expiresIn;
  final ApiUser? user;

  const PinLoginResponse({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.user,
  });

  factory PinLoginResponse.fromJson(Map<String, dynamic> json) {
    return PinLoginResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] ,
      user: json['user'] != null
          ? ApiUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ApiUser {
  final dynamic id;
  final String? uuid;
  final String? firstName;
  final String? lastName;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? employeeCode;
  final List<UserRole> roles;
  final dynamic outletId;
  final String? outletName;
  final List<int> assignedFloors;
  final List<int> assignedSections;
  final List<String> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ApiUser({
    required this.id,
    this.uuid,
    this.firstName,
    this.lastName,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    this.employeeCode,
    this.roles = const [],
    this.outletId,
    this.outletName,
    this.assignedFloors = const [],
    this.assignedSections = const [],
    this.permissions = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    // Handle roles - can be array of strings or array of objects
    List<UserRole> parseRoles(dynamic rolesData) {
      if (rolesData == null) return [];
      if (rolesData is! List) return [];
      return rolesData.map((e) {
        if (e is String) return UserRole(slug: e);
        if (e is Map<String, dynamic>) return UserRole.fromJson(e);
        return UserRole(slug: e.toString());
      }).toList();
    }

    // Handle assigned floors/sections - can be list of ints
    List<int> parseIntList(dynamic data) {
      if (data == null) return [];
      if (data is! List) return [];
      return data
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .toList();
    }

    // Handle permissions - can be list of strings or objects with slug
    List<String> parsePermissions(dynamic data) {
      if (data == null) return [];
      if (data is! List) return [];
      return data
          .map((e) {
            if (e is String) return e;
            if (e is Map<String, dynamic>) return e['slug']?.toString() ?? '';
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Build name from firstName + lastName if name not provided
    final firstName = json['firstName'] as String?;
    final lastName = json['lastName'] as String?;
    String name = json['name'] as String? ?? '';
    if (name.isEmpty && (firstName != null || lastName != null)) {
      name = [
        firstName,
        lastName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');
    }

    return ApiUser(
      id: json['id'] ,
      uuid: json['uuid'] as String?,
      firstName: firstName,
      lastName: lastName,
      name: name,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatarUrl'] as String? ?? json['avatar'] as String?,
      employeeCode: json['employeeCode'] as String?,
      roles: parseRoles(json['roles']),
      outletId: json['outletId'] ,
      outletName: json['outletName'] as String?,
      assignedFloors: parseIntList(json['assignedFloors']),
      assignedSections: parseIntList(json['assignedSections']),
      permissions: parsePermissions(json['permissions']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'firstName': firstName,
    'lastName': lastName,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar': avatar,
    'employeeCode': employeeCode,
    'roles': roles.map((e) => e.toJson()).toList(),
    'outletId': outletId,
    'outletName': outletName,
    'assignedFloors': assignedFloors,
    'assignedSections': assignedSections,
  };

  dynamic get primaryOutletId =>
      outletId ?? (roles.isNotEmpty ? roles.first.outletId : null);

  bool get isCaptain => roles.any((r) => r.slug == 'captain');

  bool hasPermission(String permission) => permissions.contains(permission);
}

class UserRole {
  final String slug;
  final dynamic outletId;
  final String? name;

  const UserRole({required this.slug, this.outletId, this.name});

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      slug: json['slug'] as String? ?? '',
      outletId: json['outletId'] ,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'outletId': outletId,
    'name': name,
  };
}

class PermissionsResponse {
  final List<String> permissions;

  const PermissionsResponse({required this.permissions});

  factory PermissionsResponse.fromJson(Map<String, dynamic> json) {
    return PermissionsResponse(
      permissions:
          (json['permissions'] as List?)?.map((e) => e as String).toList() ??
          [],
    );
  }

  bool hasPermission(String permission) => permissions.contains(permission);
}

/// Common permission constants
class Permissions {
  Permissions._();

  static const String tableView = 'TABLE_VIEW';
  static const String orderCreate = 'ORDER_CREATE';
  static const String kotSend = 'KOT_SEND';
  static const String kotReprint = 'KOT_REPRINT';
  static const String billGenerate = 'BILL_GENERATE';
  static const String paymentCollect = 'PAYMENT_COLLECT';
  static const String discountApply = 'DISCOUNT_APPLY';
  static const String orderCancel = 'ORDER_CANCEL';
  static const String itemCancel = 'ITEM_CANCEL';
  static const String tableTransfer = 'TABLE_TRANSFER';
  static const String tableMerge = 'TABLE_MERGE';
}
