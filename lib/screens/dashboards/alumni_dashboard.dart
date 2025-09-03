import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/dashboard_layout.dart';
import '../../widgets/features/alumni_profile_widget.dart';
import '../../widgets/features/alumni_directory_widget.dart';
import '../../widgets/features/connection_requests_widget.dart';
import '../../widgets/features/password_change_widget.dart';
import '../../widgets/features/job_board_widget.dart';
import '../../widgets/features/events_widget.dart';
import '../../widgets/features/alumni_event_request_widget.dart';
import '../../widgets/features/alumni_management_requests_widget.dart';
import '../../widgets/features/user_chat_widget.dart';
import '../../services/api_service.dart';
import '../dashboards/student_dashboard.dart';

class AlumniDashboard extends StatefulWidget {
  const AlumniDashboard({super.key});

  @override
  State<AlumniDashboard> createState() => _AlumniDashboardState();
}

class _AlumniDashboardState extends State<AlumniDashboard> {
  int _selectedIndex = 0;
  Map<String, int> _stats = {
    'networkConnections': 0,
    'studentsHelped': 0,
    'jobsPosted': 0,
  };
  bool _statsLoading = true;

  final List<DashboardTab> _tabs = [
    DashboardTab(
      id: 'profile',
      title: 'My Profile',
      icon: LucideIcons.user,
    ),
    DashboardTab(
      id: 'directory',
      title: 'Alumni Directory',
      icon: LucideIcons.users,
    ),
    DashboardTab(
      id: 'connections',
      title: 'Connection Requests',
      icon: LucideIcons.userCheck,
    ),
    DashboardTab(
      id: 'password',
      title: 'Change Password',
      icon: LucideIcons.lock,
    ),
    DashboardTab(
      id: 'jobs',
      title: 'Job Board',
      icon: LucideIcons.briefcase,
    ),
    DashboardTab(
      id: 'events',
      title: 'Events',
      icon: LucideIcons.calendar,
    ),
    DashboardTab(
      id: 'request-event',
      title: 'Request Event',
      icon: LucideIcons.plus,
    ),
    DashboardTab(
      id: 'management-requests',
      title: 'Management Requests',
      icon: LucideIcons.messageSquare,
    ),
    DashboardTab(
      id: 'chat',
      title: 'Messages',
      icon: LucideIcons.messageCircle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await ApiService.getAlumniStats();
      setState(() {
        _stats = {
          'networkConnections': response['networkConnections'] ?? 0,
          'studentsHelped': response['studentsHelped'] ?? 0,
          'jobsPosted': response['jobsPosted'] ?? 0,
        };
        _statsLoading = false;
      });
    } catch (e) {
      setState(() => _statsLoading = false);
    }
  }

  Widget _buildStatsCards() {
    if (_statsLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Network',
              _stats['networkConnections'].toString(),
              'Connections',
              LucideIcons.users,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Mentoring',
              _stats['studentsHelped'].toString(),
              'Students Helped',
              LucideIcons.messageCircle,
              AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Opportunities',
              _stats['jobsPosted'].toString(),
              'Jobs Posted',
              LucideIcons.briefcase,
              AppTheme.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWidget() {
    final selectedTab = _tabs[_selectedIndex];
    
    switch (selectedTab.id) {
      case 'profile':
        return const AlumniProfileWidget();
      case 'directory':
        return const AlumniDirectoryWidget(excludeCurrentUser: true);
      case 'connections':
        return const ConnectionRequestsWidget();
      case 'password':
        return const PasswordChangeWidget();
      case 'jobs':
        return const JobBoardWidget();
      case 'events':
        return const EventsWidget();
      case 'request-event':
        return const AlumniEventRequestWidget();
      case 'management-requests':
        return const AlumniManagementRequestsWidget();
      case 'chat':
        return const UserChatWidget();
      default:
        return const AlumniProfileWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return DashboardLayout(
      title: 'Alumni Dashboard',
      selectedIndex: _selectedIndex,
      tabs: _tabs,
      onTabChanged: (index) => setState(() => _selectedIndex = index),
      headerWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentColor, Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.graduationCap,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Welcome back, Alumni!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect with current students and fellow alumni. Share your experience, find opportunities, and give back to the community.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Cards (only show on profile tab)
          if (_selectedIndex == 0) ...[
            _buildStatsCards(),
            const SizedBox(height: 24),
          ],
        ],
      ),
      body: _buildActiveWidget(),
    );
  }
}