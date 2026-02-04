import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/user.dart';
import '../../data/services/real_auth_service.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/constants/app_colors.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isLoading = false;
  bool _isBackgroundRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final hasCachedData = await _loadFromCache();

    if (hasCachedData) {
      _refreshFromApiInBackground();
    } else {
      setState(() {
        _isLoading = true;
      });
      await _refreshFromApi();
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _loadFromCache() async {
    try {
      final cacheManager = ref.read(cacheManagerProvider);
      final cachedUserData = await cacheManager.getUser();

      if (cachedUserData != null) {
        final Map<String, dynamic> convertedData = {};
        cachedUserData.forEach((key, value) {
          if (value is Map && value is! Map<String, dynamic>) {
            convertedData[key.toString()] = Map<String, dynamic>.from(value);
          } else if (key == 'isActive' && value is bool) {
            convertedData[key.toString()] = value ? 1 : 0;
          } else if (key == 'isVerified' && value is bool) {
            convertedData[key.toString()] = value ? 1 : 0;
          } else {
            convertedData[key.toString()] = value;
          }
        });

        final cachedUser = User.fromJson(convertedData);

        final authNotifier = ref.read(authProvider.notifier);
        final currentAuthState = ref.read(authProvider);

        if (!currentAuthState.isAuthenticated || currentAuthState.user?.id != cachedUser.id) {
          authNotifier.setAuthenticatedState(
            cachedUser,
            'cached_token',
            'cached_refresh',
          );
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _refreshFromApi() async {
    try {
      final realAuthService = ref.read(realAuthServiceProvider);
      final response = await realAuthService.getCurrentUser();

      if (response.success && response.user != null) {
        final authNotifier = ref.read(authProvider.notifier);
        final currentAuthState = ref.read(authProvider);

        if (currentAuthState.isAuthenticated) {
          authNotifier.updateUser(response.user!);
        } else {
          authNotifier.setAuthenticatedState(response.user!, 'api_token', 'api_refresh');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refreshFromApiInBackground() async {
    if (_isBackgroundRefreshing) return;

    setState(() {
      _isBackgroundRefreshing = true;
    });

    try {
      final realAuthService = ref.read(realAuthServiceProvider);
      final response = await realAuthService.getCurrentUser();

      if (response.success && response.user != null) {
        final authNotifier = ref.read(authProvider.notifier);
        final currentAuthState = ref.read(authProvider);

        final apiUser = response.user!;
        final currentUser = currentAuthState.user;

        bool hasChanged = currentUser == null ||
            currentUser.id != apiUser.id ||
            currentUser.lastLoginAt != apiUser.lastLoginAt ||
            currentUser.name != apiUser.name;

        if (hasChanged) {
          if (currentAuthState.isAuthenticated) {
            authNotifier.updateUser(apiUser);
          } else {
            authNotifier.setAuthenticatedState(apiUser, 'api_token', 'api_refresh');
          }
        }
      }
    } catch (e) {
      // Silent fail for background refresh
    } finally {
      setState(() {
        _isBackgroundRefreshing = false;
      });
    }
  }

  Future<void> _forceRefresh() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final realAuthService = ref.read(realAuthServiceProvider);
      final response = await realAuthService.getCurrentUser();

      if (response.success && response.user != null) {
        final authNotifier = ref.read(authProvider.notifier);
        final currentAuthState = ref.read(authProvider);

        if (currentAuthState.isAuthenticated) {
          authNotifier.updateUser(response.user!);
        } else {
          authNotifier.setAuthenticatedState(response.user!, 'force_token', 'force_refresh');
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title:  Text('Profile'.toUpperCase()),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Loading profile...',
                style: TextStyle(color: Color(0xFF6C757D)),
              ),
            ],
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title:  Text('Profile'.toUpperCase()),
          backgroundColor: AppColors.primary,
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
                'No user data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6C757D),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadUserProfile,
                icon: const Icon(Icons.refresh),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Profile Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text("Profile".toUpperCase()),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _forceRefresh,
                tooltip: 'Refresh',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(user),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Quick Stats
                _buildQuickStats(user),

                const SizedBox(height: 16),

                // Account Details
                _buildAccountDetails(user),

                const SizedBox(height: 16),

                // Permissions
                _buildPermissionsSection(user),

                const SizedBox(height: 24),

                // Logout Button
                _buildLogoutButton(context, ref, authState),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [

            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: user.avatarUrl != null
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                  _getInitials(user.name),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color:AppColors.primary,
                  ),
                )
                    : null,
              ),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                user.primaryRole,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Employee Code
            Text(
              user.employeeCode,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.verified_user_rounded,
              value: '${user.permissions.length}',
              label: 'Permissions',
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.apps_rounded,
              value: '${user.permissionsByModule.length}',
              label: 'Modules',
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.store_rounded,
              value: '1',
              label: 'Outlet',
              color: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6C757D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetails(user) {
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_circle_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Account Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildDetailRow(
              icon: Icons.business_rounded,
              label: 'Outlet',
              value: user.outletName,
            ),
            _buildDetailRow(
              icon: Icons.badge_rounded,
              label: 'Employee Code',
              value: user.employeeCode,
            ),
            _buildDetailRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: user.email ?? 'Not provided',
            ),
            _buildDetailRow(
              icon: Icons.phone_rounded,
              label: 'Phone',
              value: user.phone ?? 'Not provided',
            ),
            _buildDetailRow(
              icon: Icons.schedule_rounded,
              label: 'Last Login',
              value: _formatLastLogin(user.lastLoginAt),
            ),
            _buildDetailRow(
              icon: Icons.circle,
              label: 'Status',
              value: user.isActive ? 'Active' : 'Inactive',
              valueColor: user.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
                    color: valueColor ?? AppColors.black,
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

  Widget _buildPermissionsSection(user) {
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Access Permissions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _buildPermissionCategories(user.permissionsByModule),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPermissionCategories(Map<String, List<String>> permissionsByModule) {
    final categoryTitles = {
      'table': 'Tables',
      'order': 'Orders',
      'kot': 'Kitchen',
      'billing': 'Billing',
      'payment': 'Payment',
      'discount': 'Discount',
      'tip': 'Tips',
      'item': 'Menu Items',
      'category': 'Categories',
      'report': 'Reports',
      'floor': 'Floor',
      'section': 'Section',
    };

    final categoryIcons = {
      'table': Icons.table_restaurant_rounded,
      'order': Icons.receipt_long_rounded,
      'kot': Icons.restaurant_rounded,
      'billing': Icons.payment_rounded,
      'payment': Icons.account_balance_wallet_rounded,
      'discount': Icons.local_offer_rounded,
      'tip': Icons.attach_money_rounded,
      'item': Icons.fastfood_rounded,
      'category': Icons.category_rounded,
      'report': Icons.assessment_rounded,
      'floor': Icons.layers_rounded,
      'section': Icons.dashboard_rounded,
    };

    return permissionsByModule.entries.map((entry) {
      final categoryName = categoryTitles[entry.key] ?? entry.key.toUpperCase();
      final categoryIcon = categoryIcons[entry.key] ?? Icons.check_circle_rounded;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  categoryIcon,
                  size: 16,
                  color: AppColors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value.map((permission) {
                return _buildPermissionChip(permission);
              }).toList(),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPermissionChip(String permission) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatPermissionName(permission),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPermissionName(String permission) {
    return permission
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, authState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          
          onPressed: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );

            if (shouldLogout == true) {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            }
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}