import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class AlertsHistoryScreen extends StatefulWidget {
  const AlertsHistoryScreen({super.key});

  @override
  State<AlertsHistoryScreen> createState() => _AlertsHistoryScreenState();
}

class _AlertsHistoryScreenState extends State<AlertsHistoryScreen> {
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _filtered = [];
  String _filter = 'all';
  bool _loading = true;

  final List<String> _filterOptions = [
    'all', 'detected', 'registered', 'missing', 'unusual_activity'
  ];

  final Map<String, _AlertConfig> _configs = {
    'detected': _AlertConfig(
      label: 'Detected',
      icon: Icons.check_circle_outline,
      color: const Color(0xFF22C55E),
      bgColor: const Color(0xFFF0FDF4),
    ),
    'registered': _AlertConfig(
      label: 'Registered',
      icon: Icons.info_outline,
      color: const Color(0xFF3B82F6),
      bgColor: const Color(0xFFEFF6FF),
    ),
    'missing': _AlertConfig(
      label: 'Missing',
      icon: Icons.error_outline,
      color: const Color(0xFFEF4444),
      bgColor: const Color(0xFFFEF2F2),
    ),
    'unusual_activity': _AlertConfig(
      label: 'Unusual Activity',
      icon: Icons.warning_amber_outlined,
      color: const Color(0xFFF59E0B),
      bgColor: const Color(0xFFFFFBEB),
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final logs = await SupabaseService.getActivityLogs(user.id, limit: 100);
    setState(() {
      _logs = logs;
      _applyFilter(_filter);
      _loading = false;
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _filter = filter;
      _filtered = filter == 'all'
          ? _logs
          : _logs.where((l) => l['activity_type'] == filter).toList();
    });
  }

  Future<void> _deleteLog(String id) async {
    await SupabaseService.client
        .from('activity_logs')
        .delete()
        .eq('id', id);
    setState(() {
      _logs.removeWhere((l) => l['id'] == id);
      _filtered.removeWhere((l) => l['id'] == id);
    });
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alerts & History',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('View all detection events and alerts',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
              const SizedBox(height: 16),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filterOptions.map((f) {
                    final isActive = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f == 'all'
                            ? 'All'
                            : (_configs[f]?.label ?? f)),
                        selected: isActive,
                        onSelected: (_) => _applyFilter(f),
                        selectedColor:
                            const Color(0xFF3B82F6).withOpacity(0.15),
                        checkmarkColor: const Color(0xFF3B82F6),
                        labelStyle: TextStyle(
                          color: isActive
                              ? const Color(0xFF3B82F6)
                              : null,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadLogs,
            child: _filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) =>
                        _AlertCard(
                          log: _filtered[i],
                          config: _configs[_filtered[i]['activity_type']] ??
                              _AlertConfig(
                                label: 'Activity',
                                icon: Icons.notifications_outlined,
                                color: const Color(0xFF64748B),
                                bgColor: const Color(0xFFF8FAFC),
                              ),
                          timeAgo: _timeAgo(_filtered[i]['created_at']),
                          onDelete: () => _deleteLog(_filtered[i]['id']),
                        ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none,
              size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text('No alerts found',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            _filter == 'all'
                ? 'Detection events will appear here'
                : 'No ${_configs[_filter]?.label ?? _filter} events found',
            style:
                const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _AlertConfig {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _AlertConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final _AlertConfig config;
  final String timeAgo;
  final VoidCallback onDelete;

  const _AlertCard({
    required this.log,
    required this.config,
    required this.timeAgo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final location = log['location'] as String? ?? 'Unknown location';
    final confidence = (log['confidence'] as num?)?.toDouble() ?? 0.0;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: config.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(config.icon, color: config.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 6, top: 1),
                      decoration: BoxDecoration(
                        color: config.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      config.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: config.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF94A3B8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (confidence > 0)
                  Text(
                    'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeAgo,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
