import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../widgets/common_widgets.dart';

enum DeviceStatus { connected, disconnected, pairing }

enum DeviceType { smartwatch, earbuds, tracker, other }

class ConnectedDevice {
  final String id;
  final String name;
  final DeviceType type;
  DeviceStatus status;
  final int battery;
  bool alertsEnabled;
  final String lastSeen;

  ConnectedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.battery,
    this.alertsEnabled = true,
    required this.lastSeen,
  });
}

class BluetoothDevicesScreen extends StatefulWidget {
  const BluetoothDevicesScreen({super.key});

  @override
  State<BluetoothDevicesScreen> createState() =>
      _BluetoothDevicesScreenState();
}

class _BluetoothDevicesScreenState extends State<BluetoothDevicesScreen> {
  bool _scanning = false;
  Timer? _scanTimer;

  final List<ConnectedDevice> _devices = [
    ConnectedDevice(
      id: '1',
      name: 'My Smartwatch',
      type: DeviceType.smartwatch,
      status: DeviceStatus.connected,
      battery: 78,
      lastSeen: 'Now',
    ),
    ConnectedDevice(
      id: '2',
      name: 'AirPods Pro',
      type: DeviceType.earbuds,
      status: DeviceStatus.disconnected,
      battery: 45,
      lastSeen: '2 hours ago',
    ),
    ConnectedDevice(
      id: '3',
      name: 'Tile Tracker',
      type: DeviceType.tracker,
      status: DeviceStatus.connected,
      battery: 92,
      lastSeen: 'Now',
    ),
  ];

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  void _startScan() {
    setState(() => _scanning = true);
    _scanTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        // Simulate finding a new device
        _devices.add(ConnectedDevice(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Unknown Device ${Random().nextInt(99)}',
          type: DeviceType.other,
          status: DeviceStatus.disconnected,
          battery: 0,
          lastSeen: 'Just found',
        ));
      });
    });
  }

  void _disconnect(String id) {
    setState(() {
      final d = _devices.firstWhere((d) => d.id == id);
      d.status = DeviceStatus.disconnected;
    });
  }

  void _remove(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Device'),
        content: const Text('Remove this device from your list?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _devices.removeWhere((d) => d.id == id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _toggleAlerts(String id) {
    setState(() {
      final d = _devices.firstWhere((d) => d.id == id);
      d.alertsEnabled = !d.alertsEnabled;
    });
  }

  void _pairDevice(String id) {
    setState(() {
      final d = _devices.firstWhere((d) => d.id == id);
      d.status = DeviceStatus.pairing;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        final d = _devices.firstWhere((d) => d.id == id);
        d.status = DeviceStatus.connected;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final connected = _devices.where((d) =>
        d.status == DeviceStatus.connected ||
        d.status == DeviceStatus.pairing).toList();
    final disconnected =
        _devices.where((d) => d.status == DeviceStatus.disconnected).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Device Connections',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    Text('Manage your Bluetooth devices',
                        style: TextStyle(
                            color: Color(0xFF64748B), fontSize: 15)),
                  ],
                ),
              ),
              GradientButton(
                label: _scanning ? 'Scanning...' : 'Scan',
                icon: _scanning ? null : Icons.bluetooth_searching,
                onPressed: _scanning ? null : _startScan,
                loading: _scanning,
                height: 44,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary row
          Row(
            children: [
              _SummaryChip(
                icon: Icons.bluetooth_connected,
                label: '${connected.length} Connected',
                color: const Color(0xFF22C55E),
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                icon: Icons.bluetooth_disabled,
                label: '${disconnected.length} Disconnected',
                color: const Color(0xFF94A3B8),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (connected.isNotEmpty) ...[
            const Text('Connected',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...connected.map((d) => _DeviceCard(
                  device: d,
                  onDisconnect: () => _disconnect(d.id),
                  onRemove: () => _remove(d.id),
                  onToggleAlerts: () => _toggleAlerts(d.id),
                  onPair: () => _pairDevice(d.id),
                )),
            const SizedBox(height: 16),
          ],

          if (disconnected.isNotEmpty) ...[
            const Text('Disconnected',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...disconnected.map((d) => _DeviceCard(
                  device: d,
                  onDisconnect: () => _disconnect(d.id),
                  onRemove: () => _remove(d.id),
                  onToggleAlerts: () => _toggleAlerts(d.id),
                  onPair: () => _pairDevice(d.id),
                )),
          ],

          if (_devices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    const Icon(Icons.bluetooth_searching,
                        size: 56, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    const Text('No devices found',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    const Text('Tap Scan to find nearby devices',
                        style: TextStyle(color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final ConnectedDevice device;
  final VoidCallback onDisconnect;
  final VoidCallback onRemove;
  final VoidCallback onToggleAlerts;
  final VoidCallback onPair;

  const _DeviceCard({
    required this.device,
    required this.onDisconnect,
    required this.onRemove,
    required this.onToggleAlerts,
    required this.onPair,
  });

  IconData _iconFor(DeviceType t) {
    switch (t) {
      case DeviceType.smartwatch:
        return Icons.watch_outlined;
      case DeviceType.earbuds:
        return Icons.headphones_outlined;
      case DeviceType.tracker:
        return Icons.location_on_outlined;
      default:
        return Icons.devices_other_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = device.status == DeviceStatus.connected;
    final isPairing = device.status == DeviceStatus.pairing;

    Color iconBg = isConnected
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFF1F5F9);
    Color iconColor = isConnected
        ? const Color(0xFF3B82F6)
        : const Color(0xFF94A3B8);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFor(device.type),
                    color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    _StatusBadge(status: device.status),
                  ],
                ),
              ),
              if (device.battery > 0) ...[
                Icon(Icons.battery_full,
                    size: 16,
                    color: device.battery > 20
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444)),
                const SizedBox(width: 2),
                Text('${device.battery}%',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              if (isConnected)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDisconnect,
                    icon: const Icon(Icons.bluetooth_disabled, size: 16),
                    label: const Text('Disconnect'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else if (!isPairing)
                Expanded(
                  child: GradientButton(
                    label: 'Connect',
                    icon: Icons.bluetooth,
                    onPressed: onPair,
                    height: 40,
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text('Pairing...',
                        style: TextStyle(color: Color(0xFFF59E0B))),
                  ),
                ),

              const SizedBox(width: 8),

              IconButton(
                onPressed: onToggleAlerts,
                icon: Icon(
                  device.alertsEnabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  color: device.alertsEnabled
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF94A3B8),
                ),
                tooltip:
                    device.alertsEnabled ? 'Mute alerts' : 'Enable alerts',
              ),

              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Remove device',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DeviceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    bool pulse = false;

    switch (status) {
      case DeviceStatus.connected:
        color = const Color(0xFF22C55E);
        label = 'Connected';
        pulse = true;
        break;
      case DeviceStatus.pairing:
        color = const Color(0xFFF59E0B);
        label = 'Pairing…';
        break;
      default:
        color = const Color(0xFF94A3B8);
        label = 'Disconnected';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
