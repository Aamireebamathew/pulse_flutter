import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../widgets/common_widgets.dart';
import '../../utils/app_theme.dart';

enum DeviceType { smartwatch, earbuds, tracker, other }

DeviceType _inferType(String name) {
  final n = name.toLowerCase();
  if (n.contains('watch')) return DeviceType.smartwatch;
  if (n.contains('airpod') || n.contains('earbud') ||
      n.contains('headphone') || n.contains('buds')) return DeviceType.earbuds;
  if (n.contains('tile') || n.contains('tracker') ||
      n.contains('tag') || n.contains('find')) return DeviceType.tracker;
  return DeviceType.other;
}

class _DeviceVM {
  final BluetoothDevice device;
  BluetoothConnectionState connectionState;
  bool alertsEnabled;
  int battery;

  _DeviceVM({
    required this.device,
    required this.connectionState,
    this.alertsEnabled = true,
    this.battery = 0,
  });

  String get id   => device.remoteId.str;
  String get name => device.platformName.isNotEmpty ? device.platformName : 'Unknown Device';
  DeviceType get type => _inferType(name);
  bool get isConnected => connectionState == BluetoothConnectionState.connected;
}

class BluetoothDevicesScreen extends StatefulWidget {
  const BluetoothDevicesScreen({super.key});

  @override
  State<BluetoothDevicesScreen> createState() => _BluetoothDevicesScreenState();
}

class _BluetoothDevicesScreenState extends State<BluetoothDevicesScreen> {
  final Map<String, _DeviceVM> _vms = {};
  final Map<String, StreamSubscription> _connSubs = {};

  bool _scanning = false;
  bool _btUnavailable = false;
  StreamSubscription? _scanSub;
  StreamSubscription? _btStateSub;
  StreamSubscription? _scanStateSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _btStateSub?.cancel();
    _scanStateSub?.cancel();
    for (final s in _connSubs.values) s.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _init() async {
    if (await FlutterBluePlus.isSupported == false) {
      if (mounted) setState(() => _btUnavailable = true);
      return;
    }

    _btStateSub = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off && mounted) {
        setState(() { _vms.clear(); _scanning = false; });
      }
    });

    _scanStateSub = FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) setState(() => _scanning = scanning);
    });

    await _loadConnectedDevices();
  }

  Future<void> _loadConnectedDevices() async {
    try {
      final systemDevices = await FlutterBluePlus.systemDevices([]);
      for (final d in systemDevices) {
        final state = await d.connectionState.first;
        _registerDevice(d, state);
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _registerDevice(BluetoothDevice device, BluetoothConnectionState state) {
    final id = device.remoteId.str;
    if (_vms.containsKey(id)) {
      _vms[id]!.connectionState = state;
      return;
    }
    _vms[id] = _DeviceVM(device: device, connectionState: state);
    _connSubs[id]?.cancel();
    _connSubs[id] = device.connectionState.listen((s) {
      if (!mounted) return;
      setState(() => _vms[id]?.connectionState = s);
    });
  }

  Future<void> _startScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (!mounted) return;
          setState(() => _registerDevice(
              r.device,
              r.device.isConnected
                  ? BluetoothConnectionState.connected
                  : BluetoothConnectionState.disconnected));
        }
      });
    } catch (e) {
      if (mounted) {
        PulseSnackBar.show(context, 'Scan failed: $e', isError: true);
      }
    }
  }

  Future<void> _connect(String id) async {
    final vm = _vms[id];
    if (vm == null) return;
    setState(() => vm.connectionState = BluetoothConnectionState.connecting);
    try {
      await vm.device.connect(timeout: const Duration(seconds: 10));
    } catch (e) {
      if (mounted) {
        PulseSnackBar.show(context, 'Could not connect: $e', isError: true);
        setState(() => vm.connectionState = BluetoothConnectionState.disconnected);
      }
    }
  }

  Future<void> _disconnect(String id) async {
    try { await _vms[id]?.device.disconnect(); } catch (_) {}
  }

  void _remove(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Remove Device',
            style: AppTextStyles.h2.copyWith(color: context.textPrimary)),
        content: Text('Remove this device from your list?',
            style: AppTextStyles.body.copyWith(color: context.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (_vms[id]?.isConnected == true) await _vms[id]?.device.disconnect();
              _connSubs[id]?.cancel();
              _connSubs.remove(id);
              if (mounted) setState(() => _vms.remove(id));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _toggleAlerts(String id) {
    if (!mounted) return;
    setState(() => _vms[id]?.alertsEnabled = !(_vms[id]?.alertsEnabled ?? true));
  }

  @override
  Widget build(BuildContext context) {
    if (_btUnavailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl3),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: context.textMuted.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(Icons.bluetooth_disabled,
                  size: 32, color: context.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Bluetooth not supported',
                style: AppTextStyles.h3.copyWith(color: context.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text('This device does not support Bluetooth',
                style: AppTextStyles.body.copyWith(color: context.textMuted),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    final connected    = _vms.values.where((v) => v.isConnected).toList();
    final disconnected = _vms.values.where((v) => !v.isConnected).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Device Connections',
                    style: AppTextStyles.display.copyWith(color: context.textPrimary)),
                Text('Manage your Bluetooth devices',
                    style: AppTextStyles.body.copyWith(color: context.textMuted)),
              ]),
            ),
            const SizedBox(width: AppSpacing.md),
            GradientButton(             // ✅ fullWidth: false — inside Row
              label: _scanning ? 'Scanning...' : 'Scan',
              icon: _scanning ? null : Icons.bluetooth_searching,
              onPressed: _scanning ? null : _startScan,
              loading: _scanning,
              height: 44,
              fullWidth: false,
            ),
          ]),
          const SizedBox(height: AppSpacing.xl2),

          // ── Summary chips ────────────────────────────────────────────
          Row(children: [
            _SummaryChip(
              icon: Icons.bluetooth_connected,
              label: '${connected.length} Connected',
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.md),
            _SummaryChip(
              icon: Icons.bluetooth_disabled,
              label: '${disconnected.length} Disconnected',
              color: context.textMuted,
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),

          // ── Connected ────────────────────────────────────────────────
          if (connected.isNotEmpty) ...[
            Text('Connected',
                style: AppTextStyles.h3.copyWith(color: context.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            ...connected.map((vm) => _DeviceCard(
                  vm: vm,
                  onConnect:      () => _connect(vm.id),
                  onDisconnect:   () => _disconnect(vm.id),
                  onRemove:       () => _remove(vm.id),
                  onToggleAlerts: () => _toggleAlerts(vm.id),
                )),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Disconnected ─────────────────────────────────────────────
          if (disconnected.isNotEmpty) ...[
            Text('Disconnected',
                style: AppTextStyles.h3.copyWith(color: context.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            ...disconnected.map((vm) => _DeviceCard(
                  vm: vm,
                  onConnect:      () => _connect(vm.id),
                  onDisconnect:   () => _disconnect(vm.id),
                  onRemove:       () => _remove(vm.id),
                  onToggleAlerts: () => _toggleAlerts(vm.id),
                )),
          ],

          // ── Empty state ──────────────────────────────────────────────
          if (_vms.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl4),
                child: Column(children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: context.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Icon(Icons.bluetooth_searching,
                        size: 32, color: context.primary.withOpacity(0.5)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('No devices found',
                      style: AppTextStyles.h3.copyWith(color: context.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Tap Scan to find nearby devices',
                      style: AppTextStyles.body.copyWith(color: context.textMuted)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Device card ──────────────────────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final _DeviceVM vm;
  final VoidCallback onConnect, onDisconnect, onRemove, onToggleAlerts;

  const _DeviceCard({
    required this.vm,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRemove,
    required this.onToggleAlerts,
  });

  IconData _iconFor(DeviceType t) => switch (t) {
    DeviceType.smartwatch => Icons.watch_outlined,
    DeviceType.earbuds    => Icons.headphones_outlined,
    DeviceType.tracker    => Icons.location_on_outlined,
    _                     => Icons.devices_other_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final isConnected  = vm.connectionState == BluetoothConnectionState.connected;
    final isConnecting = vm.connectionState == BluetoothConnectionState.connecting;

    final iconBg    = isConnected
        ? context.primary.withOpacity(0.12)
        : context.textMuted.withOpacity(0.08);
    final iconColor = isConnected ? context.primary : context.textMuted;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Icon(_iconFor(vm.type), color: iconColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(vm.name,
                  style: AppTextStyles.h4.copyWith(color: context.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              _StatusDot(state: vm.connectionState),
            ]),
          ),
          if (vm.battery > 0) ...[
            Icon(Icons.battery_full,
                size: 16,
                color: vm.battery > 20 ? AppColors.success : AppColors.error),
            const SizedBox(width: 2),
            Text('${vm.battery}%',
                style: AppTextStyles.caption.copyWith(color: context.textSecondary)),
            const SizedBox(width: AppSpacing.sm),
          ],
        ]),

        const SizedBox(height: AppSpacing.md),
        Divider(color: context.border, height: 1),
        const SizedBox(height: AppSpacing.md),

        Row(children: [
          if (isConnected)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDisconnect,
                icon: const Icon(Icons.bluetooth_disabled, size: 16),
                label: const Text('Disconnect'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            )
          else if (isConnecting)
            Expanded(
              child: Center(
                child: Text('Connecting…',
                    style: AppTextStyles.body.copyWith(color: AppColors.warning)),
              ),
            )
          else
            Expanded(
              child: GradientButton(   // ✅ fullWidth: true is fine here — Expanded gives it width
                label: 'Connect',
                icon: Icons.bluetooth,
                onPressed: onConnect,
                height: 40,
              ),
            ),

          const SizedBox(width: AppSpacing.sm),

          IconButton(
            onPressed: onToggleAlerts,
            icon: Icon(
              vm.alertsEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: vm.alertsEnabled ? context.primary : context.textMuted,
            ),
            tooltip: vm.alertsEnabled ? 'Mute alerts' : 'Enable alerts',
          ),

          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Remove device',
          ),
        ]),
      ]),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Text(label,
            style: AppTextStyles.label.copyWith(
                color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final BluetoothConnectionState state;
  const _StatusDot({required this.state});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (state) {
      BluetoothConnectionState.connected    => (AppColors.success, 'Connected'),
      BluetoothConnectionState.connecting   => (AppColors.warning, 'Connecting…'),
      BluetoothConnectionState.disconnecting=> (AppColors.warning, 'Disconnecting…'),
      _                                     => (context.textMuted, 'Disconnected'),
    };

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 7, height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: AppSpacing.xs),
      Text(label,
          style: AppTextStyles.caption.copyWith(
              color: color, fontWeight: FontWeight.w500)),
    ]);
  }
}