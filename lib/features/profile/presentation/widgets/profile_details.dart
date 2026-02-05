import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';

class ProfileDetails extends StatelessWidget {
  final ProfileEntity profile;

  const ProfileDetails({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Basic Information
            _buildDetailSection(
              context,
              'Basic Information',
              [
                _buildDetailItem(context, 'Employee Code', profile.employeeCode, Icons.badge),
                _buildDetailItem(context, 'UUID', profile.uuid, Icons.fingerprint),
                _buildDetailItem(context, 'Phone', profile.phone ?? 'Not provided', Icons.phone),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Account Information
            _buildDetailSection(
              context,
              'Account Information',
              [
                _buildDetailItem(context, 'User ID', profile.id.toString(), Icons.person),
                _buildDetailItem(context, 'Email', profile.email, Icons.email),
                _buildDetailItem(context, 'Status', profile.isActive ? 'Active' : 'Inactive', 
                  profile.isActive ? Icons.check_circle : Icons.cancel,
                  textColor: profile.isActive ? Colors.green : Colors.red),
                _buildDetailItem(context, 'Verification', profile.isVerified ? 'Verified' : 'Not Verified',
                  profile.isVerified ? Icons.verified : Icons.verified_user,
                  textColor: profile.isVerified ? Colors.blue : Colors.orange),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Session Information
            if (profile.lastLoginAt != null)
              _buildDetailSection(
                context,
                'Session Information',
                [
                  _buildDetailItem(context, 'Last Login', 
                    _formatDateTime(profile.lastLoginAt!), Icons.access_time),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
