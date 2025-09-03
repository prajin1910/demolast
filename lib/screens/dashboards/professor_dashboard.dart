import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/dashboard_layout.dart';
import '../../widgets/features/professor_profile_widget.dart';
import '../../widgets/features/my_assessments_widget.dart';
import '../../widgets/features/create_assessment_widget.dart';
import '../../widgets/features/attendance_management_widget.dart';
import '../../widgets/features/assessment_insights_widget.dart';
import '../../widgets/features/student_heatmap_widget.dart';
import '../../widgets/features/password_change_widget.dart';
import '../../widgets/features/events_widget.dart';
import '../../widgets/features/user_chat_widget.dart';
import '../dashboards/student_dashboard.dart';

class ProfessorDashboard extends StatefulWidget {
  const ProfessorDashboard({super.key});

  @override
  State<ProfessorDashboard> createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends State<ProfessorDashboard> {
  int _selectedIndex = 0;

  final List<DashboardTab> _tabs = [
    DashboardTab(
      id: 'profile',
      title: 'My Profile',
      icon: LucideIcons.user,
    ),
    DashboardTab(
      id: 'assessments',
      title: 'My Assessments',
      icon: LucideIcons.fileText,
    ),
    DashboardTab(
      id: 'create-assessment',
      title: 'Create Assessment',
      icon: LucideIcons.plus,
    ),
    DashboardTab(
      id: 'attendance',
      title: 'Attendance Management',
      icon: LucideIcons.users,
    ),
    DashboardTab(
      id: 'assessment-insights',
      title: 'Assessment Insights',
      icon: LucideIcons.barChart3,
    ),
    DashboardTab(
      id: 'student-activity',
      title: 'Student Activity',
      icon: LucideIcons.activity,
    ),
    DashboardTab(
      id: 'password',
      title: 'Change Password',
      icon: LucideIcons.lock,
    ),
    DashboardTab(
      id: 'events',
      title: 'Events',
      icon: LucideIcons.calendar,
    ),
    DashboardTab(
      id: 'chat',
      title: 'Chat with Students',
      icon: LucideIcons.messageCircle,
    ),
  ];

  Widget _buildActiveWidget() {
    final selectedTab = _tabs[_selectedIndex];
    
    switch (selectedTab.id) {
      case 'profile':
        return const ProfessorProfileWidget();
      case 'assessments':
        return const MyAssessmentsWidget();
      case 'create-assessment':
        return const CreateAssessmentWidget();
      case 'attendance':
        return const AttendanceManagementWidget();
      case 'assessment-insights':
        return const AssessmentInsightsWidget();
      case 'student-activity':
        return const StudentHeatmapWidget();
      case 'password':
        return const PasswordChangeWidget();
      case 'events':
        return const EventsWidget();
      case 'chat':
        return const UserChatWidget();
      default:
        return const ProfessorProfileWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return DashboardLayout(
      title: 'Professor Dashboard',
      selectedIndex: _selectedIndex,
      tabs: _tabs,
      onTabChanged: (index) => setState(() => _selectedIndex = index),
      headerWidget: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.successColor, Color(0xFF047857)],
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
                    'Welcome back, Professor!',
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
              'Create assessments, monitor student performance, and engage with your students.',
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