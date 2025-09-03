import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class ActivityHeatmapWidget extends StatefulWidget {
  final String? userId;
  final String? userName;

  const ActivityHeatmapWidget({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  State<ActivityHeatmapWidget> createState() => _ActivityHeatmapWidgetState();
}

class _ActivityHeatmapWidgetState extends State<ActivityHeatmapWidget> {
  Map<String, dynamic>? _heatmapData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  Future<void> _loadHeatmapData() async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final targetUserId = widget.userId ?? user?.id;
      
      if (targetUserId != null) {
        final response = await ApiService.getHeatmapData(targetUserId);
        setState(() {
          _heatmapData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      final toastProvider = Provider.of<ToastProvider>(context, listen: false);
      toastProvider.showToast('Failed to load activity data', ToastType.error);
    }
  }

  Color _getIntensityColor(int count) {
    if (count == 0) return Colors.grey.shade100;
    if (count <= 2) return Colors.green.shade200;
    if (count <= 4) return Colors.green.shade400;
    if (count <= 6) return Colors.green.shade600;
    return Colors.green.shade800;
  }

  List<List<String?>> _generateCalendarGrid() {
    final weeks = <List<String?>>[];
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 364));
    
    // Start from Sunday of the week containing startDate
    final startDay = startDate.weekday % 7;
    final adjustedStartDate = startDate.subtract(Duration(days: startDay));
    
    for (int week = 0; week < 53; week++) {
      final weekDays = <String?>[];
      for (int day = 0; day < 7; day++) {
        final currentDate = adjustedStartDate.add(Duration(days: (week * 7) + day));
        
        if (currentDate.isBefore(today.add(const Duration(days: 1)))) {
          weekDays.add(DateFormat('yyyy-MM-dd').format(currentDate));
        } else {
          weekDays.add(null);
        }
      }
      weeks.add(weekDays);
    }
    
    return weeks;
  }

  Widget _buildHeatmapGrid() {
    if (_heatmapData == null) return const SizedBox.shrink();

    final dailyTotals = Map<String, int>.from(_heatmapData!['dailyTotals'] ?? {});
    final calendarGrid = _generateCalendarGrid();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${dailyTotals.values.fold(0, (a, b) => a + b)} activities in the last year',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Less',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ...List.generate(5, (index) {
                    return Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: _getIntensityColor(index * 2),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(
                    'More',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calendar Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day labels
                Column(
                  children: [
                    const SizedBox(height: 20), // Space for month labels
                    ...['Mon', '', 'Wed', '', 'Fri', '', ''].map((day) => Container(
                      height: 12,
                      margin: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    )),
                  ],
                ),
                const SizedBox(width: 8),

                // Calendar
                Column(
                  children: [
                    // Month labels
                    SizedBox(
                      height: 20,
                      child: Row(
                        children: calendarGrid.asMap().entries.map((entry) {
                          final weekIndex = entry.key;
                          final week = entry.value;
                          final firstDay = week.firstWhere((day) => day != null, orElse: () => null);
                          
                          if (firstDay != null) {
                            final date = DateTime.parse(firstDay);
                            final isFirstWeekOfMonth = date.day <= 7;
                            
                            return Container(
                              width: 12,
                              margin: const EdgeInsets.only(right: 2),
                              child: isFirstWeekOfMonth
                                  ? Text(
                                      DateFormat('MMM').format(date),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppTheme.textTertiary,
                                      ),
                                    )
                                  : null,
                            );
                          }
                          
                          return Container(
                            width: 12,
                            margin: const EdgeInsets.only(right: 2),
                          );
                        }).toList(),
                      ),
                    ),

                    // Heatmap grid
                    Row(
                      children: calendarGrid.map((week) {
                        return Column(
                          children: week.map((date) {
                            if (date == null) {
                              return Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(bottom: 2),
                              );
                            }
                            
                            final count = dailyTotals[date] ?? 0;
                            
                            return Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(bottom: 2, right: 2),
                              decoration: BoxDecoration(
                                color: _getIntensityColor(count),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_heatmapData == null) return const SizedBox.shrink();

    final dailyTotals = Map<String, int>.from(_heatmapData!['dailyTotals'] ?? {});
    final totalActivities = dailyTotals.values.fold(0, (a, b) => a + b);
    final activeDays = dailyTotals.values.where((count) => count > 0).length;
    final maxDaily = dailyTotals.values.isNotEmpty ? dailyTotals.values.reduce((a, b) => a > b ? a : b) : 0;
    final avgDaily = totalActivities / 365;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            totalActivities.toString(),
            'Total Activities',
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            activeDays.toString(),
            'Active Days',
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            maxDaily.toString(),
            'Max Daily',
            AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            avgDaily.toStringAsFixed(1),
            'Daily Average',
            AppTheme.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final targetUserName = widget.userName ?? user?.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(LucideIcons.activity, color: AppTheme.successColor),
            const SizedBox(width: 8),
            Text(
              'Activity Heatmap',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (targetUserName != null) ...[
              const SizedBox(width: 8),
              Text(
                '- $targetUserName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Daily activity over the past year',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_heatmapData == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.activity,
                    size: 48,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activity data available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Statistics Cards
          _buildStatsCards(),
          const SizedBox(height: 16),

          // Heatmap
          _buildHeatmapGrid(),
        ],
      ],
    );
  }
}