import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

// ─── Bell icon widget ─────────────────────────────────────────────────────────
/// Add to any AppBar:
///   actions: [ const NotificationBell() ]
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.instance.badgeCount,
      builder: (context, count, _) {
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            NotificationService.instance.clearBadge();
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const NotificationsScreen()),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_outlined,
                  size: 24, color: context.textSecondary),
              if (count > 0)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Notifications screen ─────────────────────────────────────────────────────
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationLog.isNotEmpty)
            TextButton(
              onPressed: () {
                NotificationService.instance.cancelAll();
                setState(() {});
              },
              child: Text('Clear all',
                  style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: notificationLog.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: context.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Icon(Icons.notifications_off_outlined,
                        size: 32,
                        color: context.primary.withOpacity(0.5)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('No notifications yet',
                      style: AppTextStyles.h3
                          .copyWith(color: context.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Alerts will appear here',
                      style: AppTextStyles.body
                          .copyWith(color: context.textMuted)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: notificationLog.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) =>
                  _NotifCard(item: notificationLog[i]),
            ),
    );
  }
}

// ─── Single notification card ─────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final NotifItem item;
  const _NotifCard({required this.item});

  Color get _color {
    switch (item.type) {
      case NotifType.unusual:   return AppColors.error;
      case NotifType.bluetooth: return AppColors.blue500;
      case NotifType.recovery:  return AppColors.success;
      case NotifType.general:   return AppColors.warning;
    }
  }

  IconData get _icon {
    switch (item.type) {
      case NotifType.unusual:   return Icons.warning_amber_rounded;
      case NotifType.bluetooth: return Icons.bluetooth;
      case NotifType.recovery:  return Icons.location_on;
      case NotifType.general:   return Icons.notifications;
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(item.time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(context.isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _color.withOpacity(0.25), width: 1),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: _color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon, color: _color, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title,
                  style: AppTextStyles.h4
                      .copyWith(color: context.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(item.body,
                  style: AppTextStyles.bodySm
                      .copyWith(color: context.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(_timeAgo,
            style: AppTextStyles.caption
                .copyWith(color: context.textMuted)),
      ]),
    );
  }
}