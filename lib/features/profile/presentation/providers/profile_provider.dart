import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/entities/entities.dart';

// Profile State
class ProfileState {
  final bool isLoading;
  final ProfileEntity? profile;
  final String? error;

  const ProfileState({
    this.isLoading = false,
    this.profile,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    ProfileEntity? profile,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileState &&
        other.isLoading == isLoading &&
        other.profile == profile &&
        other.error == error;
  }

  @override
  int get hashCode => isLoading.hashCode ^ profile.hashCode ^ error.hashCode;

  @override
  String toString() {
    return 'ProfileState(isLoading: $isLoading, profile: $profile, error: $error)';
  }
}

// Profile Notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(const ProfileState());

  /// Load current user profile
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _repository.getCurrentUserProfile();
      
      result.when(
        success: (userProfile, message) {
          state = state.copyWith(
            isLoading: false,
            profile: ProfileEntity.fromModel(userProfile),
          );
        },
        failure: (error, statusCode, dynamicError) {
          state = state.copyWith(
            isLoading: false,
            error: error,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh profile data
  Future<void> refreshProfile() async {
    await loadProfile();
  }

  /// Clear profile data (for logout)
  void clearProfile() {
    state = const ProfileState();
  }

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    return state.profile?.hasPermission(permission) ?? false;
  }

  /// Check if user has any permission in a module
  bool hasModulePermission(String module) {
    return state.profile?.hasModulePermission(module) ?? false;
  }

  /// Get permissions for a specific module
  List<String> getModulePermissions(String module) {
    return state.profile?.getModulePermissions(module) ?? [];
  }
}

// Providers
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository);
});

// Async provider for profile data
final profileAsyncProvider = Provider<AsyncValue<ProfileEntity?>>((ref) {
  final profileState = ref.watch(profileProvider);
  
  if (profileState.isLoading) {
    return const AsyncValue.loading();
  }
  
  if (profileState.error != null) {
    return AsyncValue.error(profileState.error!, StackTrace.current);
  }
  
  if (profileState.profile != null) {
    return AsyncValue.data(profileState.profile);
  }
  
  return const AsyncValue.data(null);
});

// Provider for user permissions
final permissionsProvider = Provider<List<String>>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.profile?.permissions ?? [];
});

// Provider for permissions by module
final permissionsByModuleProvider = Provider<Map<String, List<String>>>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.profile?.permissionsByModule ?? {};
});

// Provider for user roles
final rolesProvider = Provider<List<RoleEntity>>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.profile?.roles ?? [];
});

// Provider for primary role
final primaryRoleProvider = Provider<RoleEntity?>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.profile?.primaryRole;
});
