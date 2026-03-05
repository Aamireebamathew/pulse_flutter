import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

// ─── Bell icon widget ─────────────────────────────────────────────────────────
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
    final user     = context.read<AuthProvider>().user;
    final email    = user?.email ?? '';
    // Show first part of email as display name e.g. "john" from "john@gmail.com"
    final username = email.contains('@') ? email.split('@').first : email;
    final isDark   = context.isDark;

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
              child: const Text('Clear all',
                  style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Welcome back banner ──────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A5F), const Color(0xFF1A2F4A)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: context.primary.withOpacity(isDark ? 0.25 : 0.20),
              ),
            ),
            child: Row(children: [
              // Avatar circle
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: context.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    username.isNotEmpty
                        ? username[0].toUpperCase()
                        : '👋',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back${username.isNotEmpty ? ', $username' : ''}! 👋',
                      style: AppTextStyles.h4.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notificationLog.isEmpty
                          ? 'You\'re all caught up — no new alerts.'
                          : '${notificationLog.length} notification${notificationLog.length == 1 ? '' : 's'} waiting for you.',
                      style: AppTextStyles.bodySm
                          .copyWith(color: context.textSecondary),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Notification list or empty state ─────────────────────────
          Expanded(
            child: notificationLog.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: context.primary.withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(AppRadius.xl),
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
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    itemCount: notificationLog.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) =>
                        _NotifCard(item: notificationLog[i]),
                  ),
          ),
        ],
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