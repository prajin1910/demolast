import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/dashboard_layout.dart';
import '../../widgets/features/dashboard_stats_widget.dart';
import '../../widgets/features/student_heatmap_widget.dart';
import '../../widgets/features/alumni_verification_widget.dart';
import '../../widgets/features/event_management_widget.dart';
import '../../widgets/features/alumni_event_invitation_widget.dart';
import '../../widgets/features/management_event_request_tracker_widget.dart';
import '../../widgets/features/password_change_widget.dart';
import '../../widgets/features/alumni_directory_widget.dart';
import '../../widgets/features/job_board_widget.dart';
import '../../widgets/features/user_chat_widget.dart';
import '../dashboards/student_dashboard.dart';

class ManagementDashboard extends StatefulWidget {
  const ManagementDashboard({super.key});

  @override
  State<ManagementDashboard> createState() => _ManagementDashboardState();
}

class _ManagementDashboardState extends State<ManagementDashboard> {
  int _selectedIndex = 0;
  int _eventTabIndex = 0;

  final List<DashboardTab> _tabs = [
    DashboardTab(
      id: 'dashboard-stats',
      title: 'Dashboard Overview',
      icon: LucideIcons.barChart3,
    ),
    DashboardTab(
      id: 'student-heatmap',
      title: 'Student Activity',
      icon: LucideIcons.activity,
    ),
    DashboardTab(
      id: 'alumni-verification',
      title: 'Alumni Verification',
      icon: LucideIcons.userCheck,
    ),
    DashboardTab(
      id: 'event-management',
      title: 'Event Management',
      icon: LucideIcons.calendar,
    ),
    DashboardTab(
      id: 'password',
      title: 'Change Password',
      icon: LucideIcons.lock,
    ),
    DashboardTab(
      id: 'alumni-network',
      title: 'Alumni Network',
      icon: LucideIcons.users,
    ),
    DashboardTab(
      id: 'job-portal',
      title: 'Job Portal',
      icon: LucideIcons.briefcase,
    ),
    DashboardTab(
      id: 'chat',
      title: 'Communication',
      icon: LucideIcons.messageCircle,
    ),
  ];

  final List<DashboardTab> _eventTabs = [
    DashboardTab(
      id: 'alumni-requests',
      title: 'Alumni Requests',
      icon: LucideIcons.calendar,
    ),
    DashboardTab(
      id: 'invite-alumni',
      title: 'Invite Alumni',
      icon: LucideIcons.send,
    ),
    DashboardTab(
      id: 'request-status',
      title: 'Request Status',
      icon: LucideIcons.eye,
    ),
  ];

  Widget _buildEventManagement() {
    return Column(
      children: [
        // Event Management Sub-Navigation
        Container(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _eventTabs.length,
            itemBuilder: (context, index) {
              final tab = _eventTabs[index];
              final isSelected = _eventTabIndex == index;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, size: 16),
                      const SizedBox(width: 4),
                      Text(tab.title),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() => _eventTabIndex = index);
                  },
                  selectedColor: AppTheme.secondaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.secondaryColor,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        
        // Event Management Content
        Expanded(
          child: _buildEventManagementContent(),
        ),
      ],
    );
  }

  Widget _buildEventManagementContent() {
    switch (_eventTabIndex) {
      case 0:
        return const EventManagementWidget();
      case 1:
        return const AlumniEventInvitationWidget();
      case 2:
        return const ManagementEventRequestTrackerWidget();
      default:
        return const EventManagementWidget();
    }
  }

  Widget _buildActiveWidget() {
    final selectedTab = _tabs[_selectedIndex];
    
    switch (selectedTab.id) {
      case 'dashboard-stats':
        return const DashboardStatsWidget();
      case 'student-heatmap':
        return const StudentHeatmapWidget();
      case 'alumni-verification':
        return const AlumniVerificationWidget();
      case 'event-management':
        return _buildEventManagement();
      case 'password':
        return const PasswordChangeWidget();
      case 'alumni-network':
        return const AlumniDirectoryWidget();
      case 'job-portal':
        return const JobBoardWidget();
      case 'chat':
        return const UserChatWidget();
      default:
        return const DashboardStatsWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Management Dashboard',
      selectedIndex: _selectedIndex,
      tabs: _tabs,
      onTabChanged: (index) => setState(() => _selectedIndex = index),
      headerWidget: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.secondaryColor, Color(0xFF5B21B6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Management Portal',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Monitor student performance, verify alumni, and oversee the entire assessment system.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
      body: _buildActiveWidget(),
    );
  }
}