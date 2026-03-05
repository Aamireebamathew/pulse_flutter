import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/app_theme.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  int _totalObjects     = 0;
  int _recentDetections = 0;
  int _activeAlerts     = 0;
  int _detectionRate    = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final objects = await SupabaseService.getObjects(user.id);
    final since   = DateTime.now().subtract(const Duration(hours: 24));
    final recentLogs = await SupabaseService.getActivityLogs(
        user.id, limit: 0, since: since);
    final allLogs = await SupabaseService.getActivityLogs(user.id, limit: 5);

    final activeAlerts = recentLogs
        .where((l) =>
            l['activity_type'] == 'unusual_activity' ||
            l['activity_type'] == 'missing')
        .length;

    setState(() {
      _totalObjects     = objects.length;
      _recentDetections = recentLogs.length;
      _activeAlerts     = activeAlerts;
      _detectionRate    = objects.isNotEmpty
          ? (recentLogs.length / objects.length * 100).round()
          : 0;
      _recentActivity = allLogs;
      _loading        = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard Overview',
                style: AppTextStyles.display
                    .copyWith(color: context.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text('Track your belongings and monitor their activity',
                style: AppTextStyles.body
                    .copyWith(color: context.textMuted)),
            const SizedBox(height: AppSpacing.xl2),

            // ── Stats grid ──────────────────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Total Objects',
                  value: '$_totalObjects',
                  iconBgColor: AppColors.blue500.withOpacity(0.12),
                  iconColor: AppColors.blue500,
                ),
                StatCard(
                  icon: Icons.multiline_chart,
                  label: 'Recent Detections',
                  value: '$_recentDetections',
                  iconBgColor: AppColors.success.withOpacity(0.12),
                  iconColor: AppColors.success,
                  subtitle: 'Last 24 hours',
                ),
                StatCard(
                  icon: Icons.notifications_active_outlined,
                  label: 'Active Alerts',
                  value: '$_activeAlerts',
                  iconBgColor: AppColors.error.withOpacity(0.12),
                  iconColor: AppColors.error,
                ),
                StatCard(
                  icon: Icons.trending_up,
                  label: 'Detection Rate',
                  value: '$_detectionRate%',
                  iconBgColor: AppColors.purple500.withOpacity(0.12),
                  iconColor: AppColors.purple500,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Recent activity ─────────────────────────────────────────────
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Activity',
                      style: AppTextStyles.h2
                          .copyWith(color: context.textPrimary)),
                  const SizedBox(height: AppSpacing.lg),

                  if (_recentActivity.isEmpty)
                    _buildEmptyActivity()
                  else
                    ..._recentActivity.map(
                        (a) => _ActivityRow(activity: a)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl3),
      child: Column(
        children: [
          Icon(Icons.timeline, size: 48, color: context.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text('No recent activity',
              style: AppTextStyles.body
                  .copyWith(color: context.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Text('Start tracking objects to see activity here',
              style: AppTextStyles.bodySm
                  .copyWith(color: context.textMuted)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final type      = activity['activity_type'] as String? ?? '';
    final location  = activity['location'] as String? ?? 'Unknown location';
    final createdAt = activity['created_at'] as String? ?? '';

    Color dotColor = AppColors.success;
    if (type == 'missing') dotColor = AppColors.error;
    if (type == 'unusual_activity') dotColor = AppColors.warning;

    String timeStr = '';
    if (createdAt.isNotEmpty) {
      try {
        timeStr = DateFormat.jm().format(DateTime.parse(createdAt).toLocal());
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.025),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration:
              BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.h4
                    .copyWith(color: context.textPrimary),
              ),
              Text(location,
                  style: AppTextStyles.bodySm
                      .copyWith(color: context.textMuted)),
            ],
          ),
        ),
        Text(timeStr,
            style:
                AppTextStyles.caption.copyWith(color: context.textMuted)),
      ]),
    );
  }
}