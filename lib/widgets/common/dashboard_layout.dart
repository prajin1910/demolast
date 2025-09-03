import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../features/notification_bell_widget.dart';
import '../../screens/dashboards/student_dashboard.dart';

class DashboardLayout extends StatelessWidget {
  final String title;
  final int selectedIndex;
  final List<DashboardTab> tabs;
  final Function(int) onTabChanged;
  final Widget? headerWidget;
  final Widget body;

  const DashboardLayout({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.tabs,
    required this.onTabChanged,
    this.headerWidget,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          const NotificationBellWidget(),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    user?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'User',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user?.role ?? '',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronDown, size: 16),
              ],
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: const Row(
                  children: [
                    Icon(LucideIcons.logOut, size: 16),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.logout();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Header Widget
          if (headerWidget != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: headerWidget,
            ),
          ],

          // Tab Navigation
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isSelected = selectedIndex == index;
                
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
                    onSelected: (selected) => onTabChanged(index),
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  ),
                );
              },
            ),
          ),

          // Body
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}