import 'package:flutter/foundation.dart';
import '../../data/models/auth_models.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

enum LoginMode { email, pin, passcode, credentials, cardSwipe }

@immutable
class AuthState {
  final AuthStatus status;
  final ApiUser? user;
  final String? accessToken;
  final List<String> permissions;
  final int? outletId;
  final String? errorMessage;
  final LoginMode loginMode;
  final bool isSessionRestoring;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.accessToken,
    this.permissions = const [],
    this.outletId,
    this.errorMessage,
    this.loginMode = LoginMode.credentials,
    this.isSessionRestoring = false,
  });

  factory AuthState.initial() => const AuthState();

  factory AuthState.authenticated({
    required ApiUser user,
    required String accessToken,
    List<String> permissions = const [],
    int? outletId,
  }) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      accessToken: accessToken,
      permissions: permissions,
      outletId: outletId ?? user.primaryOutletId,
    );
  }

  factory AuthState.unauthenticated({String? message}) {
    return AuthState(status: AuthStatus.unauthenticated, errorMessage: message);
  }

  AuthState copyWith({
    AuthStatus? status,
    ApiUser? user,
    String? accessToken,
    List<String>? permissions,
    int? outletId,
    String? errorMessage,
    LoginMode? loginMode,
    bool? isSessionRestoring,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      permissions: permissions ?? this.permissions,
      outletId: outletId ?? this.outletId,
      errorMessage: errorMessage,
      loginMode: loginMode ?? this.loginMode,
      isSessionRestoring: isSessionRestoring ?? this.isSessionRestoring,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;

  bool hasPermission(String permission) => permissions.contains(permission);

  bool get canViewTables => hasPermission(Permissions.tableView);
  bool get canCreateOrder => hasPermission(Permissions.orderCreate);
  bool get canSendKot => hasPermission(Permissions.kotSend);
  bool get canReprintKot => hasPermission(Permissions.kotReprint);
  bool get canGenerateBill => hasPermission(Permissions.billGenerate);
  bool get canCollectPayment => hasPermission(Permissions.paymentCollect);
  bool get canApplyDiscount => hasPermission(Permissions.discountApply);
  bool get canCancelOrder => hasPermission(Permissions.orderCancel);
  bool get canCancelItem => hasPermission(Permissions.itemCancel);
  bool get canTransferTable => hasPermission(Permissions.tableTransfer);
  bool get canMergeTables => hasPermission(Permissions.tableMerge);
}
