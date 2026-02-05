import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_service.dart';
import '../models/profile_models.dart';

/// Repository for Profile operations
class ProfileRepository {
  final ApiService _api;

  ProfileRepository(this._api);

  /// Get current user profile
  Future<ApiResult<UserProfile>> getCurrentUserProfile() async {
    return _api.get(
      ApiEndpoints.me,
      parser: (json) => UserProfile.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Update user profile (if needed in future)
  Future<ApiResult<UserProfile>> updateProfile(Map<String, dynamic> profileData) async {
    // This would be implemented when profile update functionality is needed
    throw UnimplementedError('Profile update not yet implemented');
  }

  /// Update user avatar (if needed in future)
  Future<ApiResult<UserProfile>> updateAvatar(String avatarUrl) async {
    // This would be implemented when avatar update functionality is needed
    throw UnimplementedError('Avatar update not yet implemented');
  }

  /// Change password (if needed in future)
  Future<ApiResult<bool>> changePassword(String currentPassword, String newPassword) async {
    // This would be implemented when password change functionality is needed
    throw UnimplementedError('Password change not yet implemented');
  }
}

/// Provider for profile repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProfileRepository(apiService);
});
