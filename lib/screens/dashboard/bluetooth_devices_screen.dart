import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../widgets/common_widgets.dart';
import '../../utils/app_theme.dart';

// ─── Device type inference ────────────────────────────────────────────────────
enum DeviceType { smartwatch, earbuds, tracker, phone, laptop, other }

DeviceType _inferType(String name) {
  final n = name.toLowerCase();
  if (n.contains('watch') || n.contains('galaxy watch') ||
      n.contains('fitbit') || n.contains('garmin')) return DeviceType.smartwatch;
  if (n.contains('airpod') || n.contains('earbud') ||
      n.contains('headphone') || n.contains('buds') ||
      n.contains('wf-') || n.contains('wh-') ||
      n.contains('jabra') || n.contains('bose')) return DeviceType.earbuds;
  if (n.contains('tile') || n.contains('tracker') ||
      n.contains('tag') || n.contains('find') ||
      n.contains('airtag')) return DeviceType.tracker;
  if (n.contains('phone') || n.contains('iphone') ||
      n.contains('samsung') || n.contains('pixel') ||
      n.contains('oneplus') || n.contains('xiaomi')) return DeviceType.phone;
  if (n.contains('laptop') || n.contains('macbook') ||
      n.contains('thinkpad') || n.contains('surface') ||
      n.contains('dell') || n.contains('hp ')) return DeviceType.laptop;
  return DeviceType.other;
}

// Classic BR/EDR devices can't be connected via flutter_blue_plus BLE API.
// We show them as "System Paired" and open system settings for management.
bool _isClassicOnly(DeviceType t) =>
    t == DeviceType.smartwatch ||
    t == DeviceType.earbuds    ||
    t == DeviceType.phone      ||
    t == DeviceType.laptop;

// ─── View model ───────────────────────────────────────────────────────────────
class _DeviceVM {
  final BluetoothDevice device;
  BluetoothConnectionState connectionState;
  bool alertsEnabled;
  int  rssi; // signal strength, 0 = unknown

  _DeviceVM({
    required this.device,
    required this.connectionState,
    this.alertsEnabled = true,
    this.rssi = 0,
  });

  String get id   => device.remoteId.str;
  String get name => device.platformName.isNotEmpty
      ? device.platformName
      : 'Unknown Device';
  DeviceType get type       => _inferType(name);
  bool       get isConnected => connectionState == BluetoothConnectionState.connected;
  bool       get isClassic   => _isClassicOnly(type);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class BluetoothDevicesScreen extends StatefulWidget {
  const BluetoothDevicesScreen({super.key});

  @override
  State<BluetoothDevicesScreen> createState() => _BluetoothDevicesScreenState();
}

class _BluetoothDevicesScreenState extends State<BluetoothDevicesScreen> {
  final Map<String, _DeviceVM>          _vms      = {};
  final Map<String, StreamSubscription> _connSubs = {};

  bool  _scanning      = false;
  bool  _btUnavailable = false;
  String? _btOffMessage;

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

  // ── Init ────────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    if (await FlutterBluePlus.isSupported == false) {
      if (mounted) setState(() => _btUnavailable = true);
      return;
    }

    _btStateSub = FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) return;
      if (state == BluetoothAdapterState.off) {
        setState(() {
          _vms.clear();
          _scanning = false;
          _btOffMessage = 'Bluetooth is turned off. Enable it in Settings.';
        });
      } else if (state == BluetoothAdapterState.on) {
        setState(() => _btOffMessage = null);
        _loadSystemDevices();
      }
    });

    _scanStateSub = FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) setState(() => _scanning = scanning);
    });

    // Check current adapter state
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState == BluetoothAdapterState.on) {
      await _loadSystemDevices();
    } else {
      if (mounted) setState(() =>
          _btOffMessage = 'Bluetooth is turned off. Enable it in Settings.');
    }
  }

  // ── Load already-paired / system-known devices ───────────────────────────
  Future<void> _loadSystemDevices() async {
    try {
      // systemDevices returns ALL paired devices regardless of BLE/Classic
      final systemDevices = await FlutterBluePlus.systemDevices([]);
      for (final d in systemDevices) {
        BluetoothConnectionState state;
        try {
          state = await d.connectionState.first
              .timeout(const Duration(seconds: 2));
        } catch (_) {
          state = BluetoothConnectionState.disconnected;
        }
        _registerDevice(d, state);
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('loadSystemDevices error: $e');
    }
  }

  void _registerDevice(
      BluetoothDevice device, BluetoothConnectionState state) {
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

  // ── Scan for NEW BLE devices ─────────────────────────────────────────────
  Future<void> _startScan() async {
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 6),
        androidUsesFineLocation: true,
      );
      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.onScanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          for (final r in results) {
            _registerDevice(
              r.device,
              r.device.isConnected
                  ? BluetoothConnectionState.connected
                  : BluetoothConnectionState.disconnected,
            );
            // Update RSSI
            if (_vms.containsKey(r.device.remoteId.str)) {
              _vms[r.device.remoteId.str]!.rssi = r.rssi;
            }
          }
        });
      });
    } catch (e) {
      if (mounted) PulseSnackBar.show(context, 'Scan failed: $e', isError: true);
    }
  }

  // ── Connect (BLE only) ───────────────────────────────────────────────────
  Future<void> _connect(String id) async {
    final vm = _vms[id];
    if (vm == null) return;

    // Classic devices: can't connect via BLE API — guide user to system settings
    if (vm.isClassic) {
      _showClassicInfo(vm);
      return;
    }

    setState(() => vm.connectionState = BluetoothConnectionState.connecting);
    try {
      await vm.device.connect(
        timeout: const Duration(seconds: 12),
        autoConnect: false,
      );
      if (mounted) {
        PulseSnackBar.show(context, '${vm.name} connected ✓');
      }
    } on FlutterBluePlusException catch (e) {
      if (mounted) {
        setState(() =>
            vm.connectionState = BluetoothConnectionState.disconnected);
        final msg = _friendlyBtError(e.code);
        PulseSnackBar.show(context, msg, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            vm.connectionState = BluetoothConnectionState.disconnected);
        PulseSnackBar.show(context,
            'Could not connect to ${vm.name}', isError: true);
      }
    }
  }

  Future<void> _disconnect(String id) async {
    try {
      await _vms[id]?.device.disconnect();
      if (mounted) PulseSnackBar.show(context, '${_vms[id]?.name} disconnected');
    } catch (_) {}
  }

  void _remove(String id) {
    final name = _vms[id]?.name ?? 'device';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Remove Device',
            style: AppTextStyles.h2.copyWith(color: context.textPrimary)),
        content: Text('Remove "$name" from your list?',
            style: AppTextStyles.body.copyWith(color: context.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (_vms[id]?.isConnected == true) {
                await _vms[id]?.device.disconnect();
              }
              _connSubs[id]?.cancel();
              _connSubs.remove(id);
              if (mounted) setState(() => _vms.remove(id));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _toggleAlerts(String id) {
    if (!mounted) return;
    setState(() =>
        _vms[id]?.alertsEnabled = !(_vms[id]?.alertsEnabled ?? true));
  }

  // ── Info dialog for classic devices ─────────────────────────────────────
  void _showClassicInfo(_DeviceVM vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Row(children: [
          Icon(_iconFor(vm.type), color: context.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(vm.name,
                style: AppTextStyles.h3.copyWith(color: context.textPrimary)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.info_outline,
              text: '${vm.name} uses Classic Bluetooth (BR/EDR).',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.settings_outlined,
              text: 'To connect, pair it via your device\'s Bluetooth Settings.',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              text: vm.isConnected
                  ? 'Currently connected via system Bluetooth.'
                  : 'Currently disconnected. Connect from system settings.',
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _friendlyBtError(int? code) {
    switch (code) {
      case 133: return 'Connection failed (GATT error 133). Try again.';
      case 8:   return 'Connection timed out. Move closer and retry.';
      case 22:  return 'Device rejected the connection.';
      default:  return 'Connection failed (code $code). Try again.';
    }
  }

  IconData _iconFor(DeviceType t) => switch (t) {
    DeviceType.smartwatch => Icons.watch_outlined,
    DeviceType.earbuds    => Icons.headphones_outlined,
    DeviceType.tracker    => Icons.location_on_outlined,
    DeviceType.phone      => Icons.smartphone_outlined,
    DeviceType.laptop     => Icons.laptop_outlined,
    _                     => Icons.devices_other_outlined,
  };

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_btUnavailable) return _buildUnsupported();
    if (_btOffMessage != null) return _buildBtOff();

    final connected    = _vms.values.where((v) => v.isConnected).toList();
    final disconnected = _vms.values.where((v) => !v.isConnected).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Device Connections',
                    style: AppTextStyles.display
                        .copyWith(color: context.textPrimary)),
                Text('Paired & nearby Bluetooth devices',
                    style: AppTextStyles.body
                        .copyWith(color: context.textMuted)),
              ]),
            ),
            const SizedBox(width: AppSpacing.md),
            GradientButton(
              label: _scanning ? 'Scanning…' : 'Scan',
              icon: _scanning ? null : Icons.bluetooth_searching,
              onPressed: _scanning ? null : _startScan,
              loading: _scanning,
              height: 44,
              fullWidth: false,
            ),
          ]),
          const SizedBox(height: AppSpacing.xl2),

          // ── Summary chips ────────────────────────────────────────
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
          const SizedBox(height: AppSpacing.md),

          // ── Classic BT notice ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.primary.withOpacity(0.18)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, size: 16, color: context.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Watches, earbuds & phones use Classic Bluetooth — '
                  'tap them to see pairing instructions.',
                  style: AppTextStyles.caption
                      .copyWith(color: context.textSecondary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Connected ─────────────────────────────────────────────
          if (connected.isNotEmpty) ...[
            Text('Connected',
                style: AppTextStyles.h3
                    .copyWith(color: context.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            ...connected.map((vm) => _DeviceCard(
                  vm: vm,
                  iconData:       _iconFor(vm.type),
                  onConnect:      () => _connect(vm.id),
                  onDisconnect:   () => _disconnect(vm.id),
                  onRemove:       () => _remove(vm.id),
                  onToggleAlerts: () => _toggleAlerts(vm.id),
                  onInfo:         vm.isClassic ? () => _showClassicInfo(vm) : null,
                )),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Disconnected ──────────────────────────────────────────
          if (disconnected.isNotEmpty) ...[
            Text('Disconnected',
                style: AppTextStyles.h3
                    .copyWith(color: context.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            ...disconnected.map((vm) => _DeviceCard(
                  vm: vm,
                  iconData:       _iconFor(vm.type),
                  onConnect:      () => _connect(vm.id),
                  onDisconnect:   () => _disconnect(vm.id),
                  onRemove:       () => _remove(vm.id),
                  onToggleAlerts: () => _toggleAlerts(vm.id),
                  onInfo:         vm.isClassic ? () => _showClassicInfo(vm) : null,
                )),
          ],

          // ── Empty state ───────────────────────────────────────────
          if (_vms.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xl4),
                child: Column(children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: context.primary.withOpacity(0.08),
                      borderRadius:
                          BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Icon(Icons.bluetooth_searching,
                        size: 32,
                        color: context.primary.withOpacity(0.5)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('No devices found',
                      style: AppTextStyles.h3
                          .copyWith(color: context.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tap Scan to find nearby BLE devices.\n'
                    'Paired devices appear automatically.',
                    style: AppTextStyles.body
                        .copyWith(color: context.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnsupported() => Center(
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

  Widget _buildBtOff() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl3),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: const Icon(Icons.bluetooth_disabled,
              size: 32, color: AppColors.error),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Bluetooth is Off',
            style: AppTextStyles.h3.copyWith(color: context.textPrimary)),
        const SizedBox(height: AppSpacing.xs),
        Text(_btOffMessage!,
            style: AppTextStyles.body.copyWith(color: context.textMuted),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ─── Device card ──────────────────────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final _DeviceVM       vm;
  final IconData        iconData;
  final VoidCallback    onConnect, onDisconnect, onRemove, onToggleAlerts;
  final VoidCallback?   onInfo;

  const _DeviceCard({
    required this.vm,
    required this.iconData,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRemove,
    required this.onToggleAlerts,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected  = vm.connectionState == BluetoothConnectionState.connected;
    final isConnecting = vm.connectionState == BluetoothConnectionState.connecting;
    final isClassic    = vm.isClassic;

    final iconBg    = isConnected
        ? context.primary.withOpacity(0.12)
        : context.textMuted.withOpacity(0.08);
    final iconColor = isConnected ? context.primary : context.textMuted;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(children: [
        Row(children: [
          // Device icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),

          // Name + status
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(
                  child: Text(vm.name,
                      style: AppTextStyles.h4
                          .copyWith(color: context.textPrimary)),
                ),
                // Classic BT badge
                if (isClassic)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Classic BT',
                        style: AppTextStyles.caption.copyWith(
                            color: context.primary,
                            fontWeight: FontWeight.w600)),
                  ),
              ]),
              const SizedBox(height: AppSpacing.xs),
              _StatusDot(state: vm.connectionState),
            ]),
          ),

          // RSSI signal
          if (vm.rssi != 0) ...[
            const SizedBox(width: AppSpacing.sm),
            _SignalIcon(rssi: vm.rssi),
          ],
        ]),

        const SizedBox(height: AppSpacing.md),
        Divider(color: context.border, height: 1),
        const SizedBox(height: AppSpacing.md),

        Row(children: [
          // Primary action button
          Expanded(child: _buildPrimaryButton(
              context, isConnected, isConnecting, isClassic)),

          const SizedBox(width: AppSpacing.sm),

          // Info button for classic devices
          if (onInfo != null)
            IconButton(
              onPressed: onInfo,
              icon: Icon(Icons.info_outline, color: context.primary),
              tooltip: 'How to connect',
            ),

          // Alerts toggle
          IconButton(
            onPressed: onToggleAlerts,
            icon: Icon(
              vm.alertsEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: vm.alertsEnabled
                  ? context.primary
                  : context.textMuted,
            ),
            tooltip: vm.alertsEnabled ? 'Mute alerts' : 'Enable alerts',
          ),

          // Remove
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Remove device',
          ),
        ]),
      ]),
    );
  }

  Widget _buildPrimaryButton(BuildContext context,
      bool isConnected, bool isConnecting, bool isClassic) {
    if (isConnecting) {
      return Container(
        height: 40,
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: context.primary),
          ),
          const SizedBox(width: 8),
          Text('Connecting…',
              style: AppTextStyles.body
                  .copyWith(color: context.primary)),
        ]),
      );
    }

    if (isConnected) {
      return OutlinedButton.icon(
        onPressed: onDisconnect,
        icon: const Icon(Icons.bluetooth_disabled, size: 16),
        label: const Text('Disconnect'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm + 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
    }

    if (isClassic) {
      // Classic BT: can't connect via BLE API — show info instead
      return OutlinedButton.icon(
        onPressed: onInfo,
        icon: Icon(Icons.settings_bluetooth, size: 16,
            color: context.primary),
        label: Text('How to connect',
            style: TextStyle(color: context.primary)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.primary.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm + 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
    }

    // BLE device — normal connect
    return GradientButton(
      label: 'Connect',
      icon: Icons.bluetooth,
      onPressed: onConnect,
      height: 40,
    );
  }
}

// ─── Signal strength icon ─────────────────────────────────────────────────────
class _SignalIcon extends StatelessWidget {
  final int rssi;
  const _SignalIcon({required this.rssi});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;

    if (rssi >= -60) {
      color = AppColors.success; icon = Icons.signal_wifi_4_bar; label = 'Strong';
    } else if (rssi >= -80) {
      color = AppColors.warning; icon = Icons.network_wifi_3_bar; label = 'Fair';
    } else {
      color = AppColors.error; icon = Icons.network_wifi_1_bar; label = 'Weak';
    }

    return Tooltip(
      message: '$label ($rssi dBm)',
      child: Icon(icon, color: color, size: 18),
    );
  }
}

// ─── Summary chip ─────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _SummaryChip(
      {required this.icon, required this.label, required this.color});

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

// ─── Status dot ───────────────────────────────────────────────────────────────
class _StatusDot extends StatelessWidget {
  final BluetoothConnectionState state;
  const _StatusDot({required this.state});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (state) {
      BluetoothConnectionState.connected     => (AppColors.success, 'Connected'),
      BluetoothConnectionState.connecting    => (AppColors.warning, 'Connecting…'),
      BluetoothConnectionState.disconnecting => (AppColors.warning, 'Disconnecting…'),
      _                                      => (context.textMuted, 'Disconnected'),
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

// ─── Info row (used in classic dialog) ───────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  final Color?   color;
  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.textSecondary;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: c),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: AppTextStyles.body.copyWith(color: c)),
      ),
    ]);
  }
}