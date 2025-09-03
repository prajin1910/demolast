import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/dashboard_layout.dart';
import '../../widgets/features/student_profile_widget.dart';
import '../../widgets/features/ai_assessment_widget.dart';
import '../../widgets/features/class_assessments_widget.dart';
import '../../widgets/features/task_management_widget.dart';
import '../../widgets/features/events_widget.dart';
import '../../widgets/features/job_board_widget.dart';
import '../../widgets/features/alumni_directory_widget.dart';
import '../../widgets/features/ai_chat_widget.dart';
import '../../widgets/features/user_chat_widget.dart';
import '../../widgets/features/activity_heatmap_widget.dart';
import '../../widgets/features/student_attendance_widget.dart';
import '../../widgets/features/password_change_widget.dart';
import '../../services/api_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  Map<String, int> _stats = {
    'aiAssessments': 0,
    'classTests': 0,
    'activeTasks': 0,
    'alumniConnections': 0,
  };
  bool _statsLoading = true;

  final List<DashboardTab> _tabs = [
    DashboardTab(
      id: 'profile',
      title: 'My Profile',
      icon: LucideIcons.user,
    ),
    DashboardTab(
      id: 'activity',
      title: 'My Activity',
      icon: LucideIcons.activity,
    ),
    DashboardTab(
      id: 'attendance',
      title: 'My Attendance',
      icon: LucideIcons.calendar,
    ),
    DashboardTab(
      id: 'password',
      title: 'Change Password',
      icon: LucideIcons.lock,
    ),
    DashboardTab(
      id: 'ai-assessment',
      title: 'Practice with AI',
      icon: LucideIcons.brain,
    ),
    DashboardTab(
      id: 'class-assessments',
      title: 'Class Assessments',
      icon: LucideIcons.fileText,
    ),
    DashboardTab(
      id: 'task-management',
      title: 'Task Management',
      icon: LucideIcons.checkSquare,
    ),
    DashboardTab(
      id: 'events',
      title: 'Events',
      icon: LucideIcons.calendar,
    ),
    DashboardTab(
      id: 'job-board',
      title: 'Job Board',
      icon: LucideIcons.briefcase,
    ),
    DashboardTab(
      id: 'alumni-directory',
      title: 'Alumni Network',
      icon: LucideIcons.graduationCap,
    ),
    DashboardTab(
      id: 'ai-chat',
      title: 'AI Chatbot',
      icon: LucideIcons.messageCircle,
    ),
    DashboardTab(
      id: 'user-chat',
      title: 'Messages',
      icon: LucideIcons.users,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final profile = await ApiService.getStudentProfile();
      setState(() {
        _stats = {
          'aiAssessments': profile['aiAssessmentCount'] ?? 0,
          'classTests': 0, // Will be calculated from assessments
          'activeTasks': 0, // Will be calculated from tasks
          'alumniConnections': profile['connectionCount'] ?? 0,
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
              'AI Assessments',
              _stats['aiAssessments'].toString(),
              LucideIcons.brain,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Class Tests',
              _stats['classTests'].toString(),
              LucideIcons.fileText,
              AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Tasks',
              _stats['activeTasks'].toString(),
              LucideIcons.checkSquare,
              AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Connections',
              _stats['alumniConnections'].toString(),
              LucideIcons.graduationCap,
              AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
        return const StudentProfileWidget();
      case 'activity':
        return const ActivityHeatmapWidget();
      case 'attendance':
        return const StudentAttendanceWidget();
      case 'password':
        return const PasswordChangeWidget();
      case 'ai-assessment':
        return const AIAssessmentWidget();
      case 'class-assessments':
        return const ClassAssessmentsWidget();
      case 'task-management':
        return const TaskManagementWidget();
      case 'events':
        return const EventsWidget();
      case 'job-board':
        return const JobBoardWidget();
      case 'alumni-directory':
        return const AlumniDirectoryWidget();
      case 'ai-chat':
        return const AIChatWidget();
      case 'user-chat':
        return const UserChatWidget();
      default:
        return const StudentProfileWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return DashboardLayout(
      title: 'Student Dashboard',
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
                colors: [AppTheme.primaryColor, Color(0xFF4338CA)],
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
                        'Welcome back, ${user?.name ?? 'Student'}!',
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
                  'Ready to enhance your learning with AI-powered assessments, connect with alumni, and achieve your career goals.',
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

class DashboardTab {
  final String id;
  final String title;
  final IconData icon;

  const DashboardTab({
    required this.id,
    required this.title,
    required this.icon,
  });
}