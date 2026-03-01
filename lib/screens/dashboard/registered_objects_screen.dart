import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class RegisteredObjectsScreen extends StatefulWidget {
  const RegisteredObjectsScreen({super.key});

  @override
  State<RegisteredObjectsScreen> createState() =>
      _RegisteredObjectsScreenState();
}

class _RegisteredObjectsScreenState extends State<RegisteredObjectsScreen> {
  List<Map<String, dynamic>> _objects = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';
  String? _deleteId;

  @override
  void initState() {
    super.initState();
    _loadObjects();
  }

  Future<void> _loadObjects() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final data = await SupabaseService.getObjects(user.id);
    setState(() {
      _objects = data;
      _filtered = data;
      _loading = false;
    });
  }

  void _applySearch(String query) {
    setState(() {
      _search = query;
      _filtered = query.isEmpty
          ? _objects
          : _objects.where((o) {
              final name = (o['object_name'] as String? ?? '').toLowerCase();
              final loc =
                  (o['usual_location'] as String? ?? '').toLowerCase();
              return name.contains(query.toLowerCase()) ||
                  loc.contains(query.toLowerCase());
            }).toList();
    });
  }

  Future<void> _deleteObject(String id) async {
    await SupabaseService.deleteObject(id);
    final deleted = _objects.firstWhere((o) => o['id'] == id,
        orElse: () => {});
    setState(() {
      _objects.removeWhere((o) => o['id'] == id);
      _filtered.removeWhere((o) => o['id'] == id);
      _deleteId = null;
    });
    if (mounted) {
      PulseSnackBar.show(
        context,
        '${deleted['object_name'] ?? 'Object'} has been removed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                    Text('Registered Objects',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    Text('Manage your tracked belongings',
                        style: TextStyle(
                            color: Color(0xFF64748B), fontSize: 15)),
                  ],
                ),
              ),
              GradientButton(
                label: 'Add',
                icon: Icons.add,
                onPressed: () => context.go('/dashboard/add-object'),
                height: 44,
              ),
            ],
          ),
          const SizedBox(height: 20),

          GlassCard(
            child: Column(
              children: [
                // Search bar
                TextField(
                  onChanged: _applySearch,
                  decoration: const InputDecoration(
                    hintText: 'Search objects...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 12),

                if (_filtered.isEmpty)
                  _buildEmpty()
                else
                  ..._filtered.map((obj) => _ObjectCard(
                        obj: obj,
                        onDelete: () =>
                            _showDeleteDialog(obj['id'] as String),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String id) {
    final obj =
        _objects.firstWhere((o) => o['id'] == id, orElse: () => {});
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Object'),
        content: Text(
            'Remove "${obj['object_name'] ?? 'this object'}" from tracking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteObject(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text('No objects registered yet',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Tap Add to register your first object.',
              style: TextStyle(color: Color(0xFF94A3B8))),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Add Object',
            icon: Icons.add,
            onPressed: () => context.go('/dashboard/add-object'),
            height: 44,
          ),
        ],
      ),
    );
  }
}

class _ObjectCard extends StatelessWidget {
  final Map<String, dynamic> obj;
  final VoidCallback onDelete;

  const _ObjectCard({required this.obj, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = obj['image_url'] as String? ?? '';
    final name = obj['object_name'] as String? ?? 'Unknown';
    final location = obj['usual_location'] as String? ?? '';
    final lastDetected = obj['last_detected_time'] as String?;
    final createdAt = obj['created_at'] as String? ?? '';

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr = DateFormat.yMMMd().format(dt);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // Object image / placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF3B82F6).withOpacity(0.1),
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  )
                : const Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF3B82F6), size: 28),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                if (location.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(location,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF94A3B8))),
                    ],
                  ),
                if (lastDetected != null)
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        'Last: $lastDetected',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  )
                else
                  Text('Added $dateStr',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ),

          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
