import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  int _totalObjects = 0;
  int _recentDetections = 0;
  int _activeAlerts = 0;
  int _detectionRate = 0;
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

    final since =
        DateTime.now().subtract(const Duration(hours: 24));
    final recentLogs = await SupabaseService.getActivityLogs(
      user.id,
      limit: 0,
      since: since,
    );
    final allLogs = await SupabaseService.getActivityLogs(
      user.id,
      limit: 5,
    );

    final activeAlerts = recentLogs
        .where((l) =>
            l['activity_type'] == 'unusual_activity' ||
            l['activity_type'] == 'missing')
        .length;

    setState(() {
      _totalObjects = objects.length;
      _recentDetections = recentLogs.length;
      _activeAlerts = activeAlerts;
      _detectionRate = objects.isNotEmpty
          ? (recentLogs.length / objects.length * 100).round()
          : 0;
      _recentActivity = allLogs;
      _loading = false;
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Overview',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Track your belongings and monitor their activity',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
            const SizedBox(height: 24),

            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Total Objects',
                  value: '$_totalObjects',
                  iconBgColor: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF3B82F6),
                ),
                StatCard(
                  icon: Icons.multiline_chart,
                  label: 'Recent Detections',
                  value: '$_recentDetections',
                  iconBgColor: const Color(0xFFF0FDF4),
                  iconColor: const Color(0xFF22C55E),
                  subtitle: 'Last 24 hours',
                ),
                StatCard(
                  icon: Icons.notifications_active_outlined,
                  label: 'Active Alerts',
                  value: '$_activeAlerts',
                  iconBgColor: const Color(0xFFFDF2F8),
                  iconColor: const Color(0xFFEC4899),
                ),
                StatCard(
                  icon: Icons.trending_up,
                  label: 'Detection Rate',
                  value: '$_detectionRate%',
                  iconBgColor: const Color(0xFFF5F3FF),
                  iconColor: const Color(0xFF8B5CF6),
                ),
              ],
            ),

            const SizedBox(height: 20),

            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (_recentActivity.isEmpty)
                    _buildEmptyActivity()
                  else
                    ..._recentActivity.map((activity) =>
                        _ActivityRow(activity: activity)),
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
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.timeline, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text('No recent activity',
              style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text('Start tracking objects to see activity here',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = activity['activity_type'] as String? ?? '';
    final location = activity['location'] as String? ?? 'Unknown location';
    final createdAt = activity['created_at'] as String? ?? '';

    Color dotColor = const Color(0xFF22C55E);
    if (type == 'missing') dotColor = Colors.red;
    if (type == 'unusual_activity') dotColor = Colors.orange;

    String timeStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        timeStr = DateFormat.jm().format(dt);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  location,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}