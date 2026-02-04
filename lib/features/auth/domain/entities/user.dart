import 'package:equatable/equatable.dart';

class Role extends Equatable {
  final int id;
  final String name;
  final String slug;
  final int outletId;
  final String outletName;

  const Role({
    required this.id,
    required this.name,
    required this.slug,
    required this.outletId,
    required this.outletName,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      outletId: json['outletId'] as int,
      outletName: json['outletName'] as String,
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

  @override
  List<Object?> get props => [id, name, slug, outletId, outletName];
}

class PermissionModule extends Equatable {
  final String module;
  final List<String> permissions;

  const PermissionModule({
    required this.module,
    required this.permissions,
  });

  factory PermissionModule.fromJson(String key, List<dynamic> permissions) {
    return PermissionModule(
      module: key,
      permissions: permissions.cast<String>(),
    );
  }

  @override
  List<Object?> get props => [module, permissions];
}

class User extends Equatable {
  final int id;
  final String uuid;
  final String employeeCode;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final bool isVerified;
  final DateTime? lastLoginAt;
  final List<Role> roles;
  final List<String> permissions;
  final Map<String, List<String>> permissionsByModule;

  const User({
    required this.id,
    required this.uuid,
    required this.employeeCode,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.isActive,
    required this.isVerified,
    this.lastLoginAt,
    this.roles = const [],
    this.permissions = const [],
    this.permissionsByModule = const {},
  });

  User copyWith({
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
    List<Role>? roles,
    List<String>? permissions,
    Map<String, List<String>>? permissionsByModule,
  }) {
    return User(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'employeeCode': employeeCode,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'isVerified': isVerified,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'roles': roles.map((r) => r.toJson()).toList(),
      'permissions': permissions,
      'permissionsByModule': permissionsByModule,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final rolesList = (json['roles'] as List<dynamic>? ?? [])
        .map((e) => Role.fromJson(e as Map<String, dynamic>))
        .toList();
    
    final permissionsList = (json['permissions'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();
    
    final permissionsByModuleMap = <String, List<String>>{};
    final permissionsByModuleJson = json['permissionsByModule'] as Map<String, dynamic>? ?? {};
    permissionsByModuleJson.forEach((key, value) {
      if (value is List) {
        permissionsByModuleMap[key] = value.cast<String>();
      }
    });

    return User(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      employeeCode: json['employeeCode'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isActive: (json['isActive'] as int?) == 1,
      isVerified: (json['isVerified'] as int?) == 1,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      roles: rolesList,
      permissions: permissionsList,
      permissionsByModule: permissionsByModuleMap,
    );
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
        permissions,
        permissionsByModule,
      ];

  // Permission helpers
  bool hasPermission(String permission) => permissions.contains(permission);
  
  bool hasModulePermission(String module, String permission) {
    return permissionsByModule[module]?.contains(permission) ?? false;
  }
  
  bool get canViewTables => hasPermission('TABLE_VIEW');
  bool get canMergeTables => hasPermission('TABLE_MERGE');
  bool get canTransferTables => hasPermission('TABLE_TRANSFER');
  bool get canViewOrders => hasPermission('ORDER_VIEW');
  bool get canCreateOrders => hasPermission('ORDER_CREATE');
  bool get canModifyOrders => hasPermission('ORDER_MODIFY');
  bool get canSendKOT => hasPermission('KOT_SEND');
  bool get canModifyKOT => hasPermission('KOT_MODIFY');
  bool get canReprintKOT => hasPermission('KOT_REPRINT');
  bool get canViewBills => hasPermission('BILL_VIEW');
  bool get canGenerateBills => hasPermission('BILL_GENERATE');
  bool get canReprintBills => hasPermission('BILL_REPRINT');
  bool get canCollectPayments => hasPermission('PAYMENT_COLLECT');
  bool get canSplitPayments => hasPermission('PAYMENT_SPLIT');
  bool get canApplyDiscounts => hasPermission('DISCOUNT_APPLY');
  bool get canAddTips => hasPermission('TIP_ADD');
  bool get canViewItems => hasPermission('ITEM_VIEW');
  bool get canCancelItems => hasPermission('ITEM_CANCEL');
  bool get canViewCategories => hasPermission('CATEGORY_VIEW');
  bool get canViewReports => hasPermission('REPORT_VIEW');
  bool get canViewFloors => hasPermission('FLOOR_VIEW');
  bool get canViewSections => hasPermission('SECTION_VIEW');
  
  String get displayName => name;
  String get primaryRole => roles.isNotEmpty ? roles.first.name : 'Unknown';
  String get outletName => roles.isNotEmpty ? roles.first.outletName : 'Unknown';
}
