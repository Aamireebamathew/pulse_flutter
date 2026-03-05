import 'package:flutter/material.dart';

// ─── Web-compatible NotificationService ──────────────────────────────────────
// flutter_local_notifications does NOT support web/Windows.
// This service manages in-app notifications only (badge counter + history log).
// On mobile (Android/iOS) you can later add firebase_messaging on top of this.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Badge count shown on the bell icon in the AppBar.
  final ValueNotifier<int> badgeCount = ValueNotifier(0);

  Future<void> init() async {
    // No-op on web. Add firebase_messaging init here for mobile push later.
  }

  void _bump() => badgeCount.value++;

  // ── Public API — each method logs to in-app history + bumps badge ──────────

  Future<void> showUnusualLocationAlert({
    required String objectName,
    required String foundLocation,
    required String usualLocation,
  }) async {
    logNotification(
      type: NotifType.unusual,
      title: '⚠️ Unusual Location Detected',
      body: '$objectName found in $foundLocation — usually in $usualLocation',
    );
  }

  Future<void> showBluetoothAlert({
    required String deviceName,
    required bool connected,
  }) async {
    logNotification(
      type: NotifType.bluetooth,
      title: connected ? '🔵 Device Connected' : '⚪ Device Disconnected',
      body: '$deviceName has ${connected ? 'connected' : 'disconnected'}',
    );
  }

  Future<void> showPhoneRecoveryAlert({
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    logNotification(
      type: NotifType.recovery,
      title: '📍 Phone Location Updated',
      body:
          'Located at ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)} '
          '(±${accuracy.toStringAsFixed(0)}m)',
    );
  }

  Future<void> showGeneral({
    required String title,
    required String body,
  }) async {
    logNotification(type: NotifType.general, title: title, body: body);
  }

  /// Clear the bell badge (call when user opens the notifications screen).
  void clearBadge() => badgeCount.value = 0;

  /// Clear all notifications.
  Future<void> cancelAll() async {
    notificationLog.clear();
    badgeCount.value = 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION LOG  (global in-memory list, max 50 entries)
// ═══════════════════════════════════════════════════════════════════════════════

enum NotifType { unusual, bluetooth, recovery, general }

class NotifItem {
  final NotifType type;
  final String title;
  final String body;
  final DateTime time;
  NotifItem({
    required this.type,
    required this.title,
    required this.body,
    required this.time,
  });
}

final List<NotifItem> notificationLog = [];

/// Call this from anywhere to add a notification to the in-app log.
void logNotification({
  required NotifType type,
  required String title,
  required String body,
}) {
  notificationLog.insert(
      0, NotifItem(type: type, title: title, body: body, time: DateTime.now()));
  if (notificationLog.length > 50) notificationLog.removeLast();
  NotificationService.instance.badgeCount.value++;
}