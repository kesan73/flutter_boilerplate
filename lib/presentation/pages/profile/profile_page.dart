import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../blocs/user/user_state.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../../core/constants/route_constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    // TODO: AuthBloc에서 현재 사용자 ID를 가져오는 방법을 구현
    // 예시: final currentUserId = context.read<AuthBloc>().state.user?.id;
    // 현재는 임시로 하드코딩된 값을 사용
    context.read<UserBloc>().add(const GetUserProfileEvent('current_user_id'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed(RouteConstants.editProfile);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const LoadingWidget(message: 'Loading profile...');
          } else if (state is UserError) {
            return CustomErrorWidget(
              message: state.message,
              onRetry: _loadUserProfile,
            );
          } else if (state is UserLoaded) {
            return _buildProfileContent(state.user);
          }
          return const Center(child: Text('No profile data available'));
        },
      ),
    );
  }

  Widget _buildProfileContent(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildProfileAvatar(user),
          const SizedBox(height: 24),
          _buildUserInfo(user),
          const SizedBox(height: 32),
          _buildPersonalInfoCard(user),
          const SizedBox(height: 16),
          _buildAccountInfoCard(user),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(User user) {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Theme.of(context).primaryColor,
      child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                user.profileImageUrl!,
                fit: BoxFit.cover,
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackAvatar(user);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  );
                },
              ),
            )
          : _buildFallbackAvatar(user),
    );
  }

  Widget _buildFallbackAvatar(User user) {
    return Text(
      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildUserInfo(User user) {
    return Column(
      children: [
        Text(
          user.name.isNotEmpty ? user.name : 'User',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(User user) {
    return _buildInfoCard('Personal Information', [
      _buildInfoTile(
        Icons.person,
        'Name',
        user.name.isNotEmpty ? user.name : 'Not set',
      ),
      _buildInfoTile(Icons.email, 'Email', user.email),
      _buildInfoTile(
        Icons.phone,
        'Phone',
        user.phoneNumber?.isNotEmpty == true ? user.phoneNumber! : 'Not set',
      ),
      if (user.birthdate != null)
        _buildInfoTile(
          Icons.cake,
          'Birthdate',
          _formatDate(user.birthdate!),
        ),
      if (user.gender?.isNotEmpty == true)
        _buildInfoTile(
          Icons.wc,
          'Gender',
          user.gender!,
        ),
    ]);
  }

  Widget _buildAccountInfoCard(User user) {
    return _buildInfoCard('Account Information', [
      _buildInfoTile(
        Icons.calendar_today,
        'Member Since',
        _formatDate(user.createdAt),
      ),
      _buildInfoTile(
        Icons.verified_user,
        'Account Status',
        user.isActive ? 'Active' : 'Inactive',
      ),
      if (user.updatedAt != user.createdAt)
        _buildInfoTile(
          Icons.update,
          'Last Updated',
          _formatDate(user.updatedAt),
        ),
    ]);
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 바깥 영역 터치로 닫히지 않도록
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // 로그아웃 처리
              context.read<AuthBloc>().add(LogoutEvent());
              // 네비게이션 스택을 완전히 비우고 로그인 페이지로 이동
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  RouteConstants.login,
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
