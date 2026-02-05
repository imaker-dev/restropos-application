import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'providers/profile_provider.dart';
import '../../../core/constants/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  Future<void> _forceRefresh() async {
    await ref.read(profileProvider.notifier).refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    if (profileState.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,color: Colors.black,),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("Profile".toUpperCase(),style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: Color(0xFF6C757D)),
              ),
            ],
          ),
        ),
      );
    }

    if (profileState.error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,color: Colors.black,),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("Profile".toUpperCase(),style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFF6C757D),
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading profile',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6C757D),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _forceRefresh,
                icon: const Icon(Icons.refresh,color: Colors.black,),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (profileState.profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,color: Colors.black,),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("Profile".toUpperCase(),style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFF6C757D),
              ),
              SizedBox(height: 16),
              Text(
                'No profile data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final profile = profileState.profile!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,color: Colors.black,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Profile".toUpperCase(),style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh,color: Colors.black,),
            onPressed: _forceRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(profile),

            const SizedBox(height: 12),

            // Quick Stats
            // _buildQuickStats(profile),
            //
            // const SizedBox(height: 16),

            // Account Details
            _buildAccountDetails(profile),

            const SizedBox(height: 16),

            // Permissions
            // _buildPermissionsSection(profile),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              backgroundImage: profile.avatarUrl != null
                  ? CachedNetworkImageProvider(profile.avatarUrl!)
                  : null,
              child: profile.avatarUrl == null
                  ? Text(
                      _getInitials(profile.name),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.secondaryDark,
            ),
          ),

          const SizedBox(height: 8),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondaryDark.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.secondaryDark.withOpacity(0.3)),
            ),
            child: Text(
              profile.primaryRole?.name ?? 'User',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryDark,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Employee Code
          Text(
            profile.employeeCode,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryDark.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),

          // const SizedBox(height: 24),
        ],
      ),
    );
  }

// Updated _buildQuickStats - Now in detail row style
  Widget _buildQuickStats(profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildStatRow(
              icon: Icons.verified_user_rounded,
              label: 'Permissions',
              value: '${profile.permissions.length}',
              color: const Color(0xFF10B981),
            ),
            _buildStatRow(
              icon: Icons.apps_rounded,
              label: 'Modules',
              value: '${profile.permissionsByModule.length}',
              color: const Color(0xFF3B82F6),
            ),
            _buildStatRow(
              icon: Icons.store_rounded,
              label: 'Roles',
              value: '${profile.roles.length}',
              color: const Color(0xFF8B5CF6),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C757D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 48),
      ],
    );
  }

  Widget _buildAccountDetails(profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryDark.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_circle_rounded,
                      color: AppColors.secondaryDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Account Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildDetailRow(
              icon: Icons.business_rounded,
              label: 'Primary Role',
              value: profile.primaryRole?.name ?? 'N/A',
            ),
            _buildDetailRow(
              icon: Icons.badge_rounded,
              label: 'Employee Code',
              value: profile.employeeCode,
            ),
            _buildDetailRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: profile.email,
            ),
            _buildDetailRow(
              icon: Icons.phone_rounded,
              label: 'Phone',
              value: profile.phone ?? 'Not provided',
            ),
            _buildDetailRow(
              icon: Icons.schedule_rounded,
              label: 'Last Login',
              value: _formatLastLogin(profile.lastLoginAt),
            ),
            _buildDetailRow(
              icon: Icons.circle,
              label: 'Status',
              value: profile.isActive ? 'Active' : 'Inactive',
              valueColor: profile.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF6C757D)),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C757D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 48),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatLastLogin(DateTime? lastLogin) {
    if (lastLogin == null) return 'N/A';

    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[lastLogin.month - 1]} ${lastLogin.day}, ${lastLogin.year}';
    }
  }
}
