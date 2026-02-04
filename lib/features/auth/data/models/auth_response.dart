import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

class AuthResponse extends Equatable {
  final bool success;
  final User? user;
  final String? token;
  final String? refreshToken;
  final String? message;

  const AuthResponse({
    required this.success,
    this.user,
    this.token,
    this.refreshToken,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      user: json['data'] != null ? User.fromJson(json['data'] as Map<String, dynamic>) : null,
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': user?.toJson(),
      'token': token,
      'refreshToken': refreshToken,
      'message': message,
    };
  }

  @override
  List<Object?> get props => [success, user, token, refreshToken, message];
}
