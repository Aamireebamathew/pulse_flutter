import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/app_theme.dart';

class RegisteredObjectsScreen extends StatefulWidget {
  const RegisteredObjectsScreen({super.key});

  @override
  State<RegisteredObjectsScreen> createState() =>
      _RegisteredObjectsScreenState();
}

class _RegisteredObjectsScreenState extends State<RegisteredObjectsScreen> {
  List<Map<String, dynamic>> _objects  = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

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
      _objects  = data;
      _filtered = data;
      _loading  = false;
    });
  }

  void _applySearch(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? _objects
          : _objects.where((o) {
              final name = (o['object_name'] as String? ?? '').toLowerCase();
              final loc  = (o['usual_location'] as String? ?? '').toLowerCase();
              return name.contains(query.toLowerCase()) ||
                  loc.contains(query.toLowerCase());
            }).toList();
    });
  }

  Future<void> _deleteObject(String id) async {
    await SupabaseService.deleteObject(id);
    final deleted =
        _objects.firstWhere((o) => o['id'] == id, orElse: () => {});
    setState(() {
      _objects.removeWhere((o) => o['id'] == id);
      _filtered.removeWhere((o) => o['id'] == id);
    });
    if (mounted) {
      PulseSnackBar.show(
          context, '${deleted['object_name'] ?? 'Object'} has been removed.');
    }
  }

  void _showDeleteDialog(String id) {
    final obj = _objects.firstWhere((o) => o['id'] == id, orElse: () => {});
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Delete Object',
            style: AppTextStyles.h2.copyWith(color: context.textPrimary)),
        content: Text(
            'Remove "${obj['object_name'] ?? 'this object'}" from tracking?',
            style: AppTextStyles.body.copyWith(color: context.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteObject(id);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registered Objects',
                        style: AppTextStyles.display
                            .copyWith(color: context.textPrimary)),
                    Text('Manage your tracked belongings',
                        style: AppTextStyles.body
                            .copyWith(color: context.textMuted)),
                  ]),
            ),
            const SizedBox(width: AppSpacing.md),
            GradientButton(               // ✅ fullWidth: false — inside Row
              label: 'Add',
              icon: Icons.add,
              onPressed: () => context.go('/dashboard/add-object'),
              height: 44,
              fullWidth: false,
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),

          // ── Card with search + list ──────────────────────────────────
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: _applySearch,
                  decoration: InputDecoration(
                    hintText: 'Search objects…',
                    prefixIcon: Icon(Icons.search, color: context.textMuted),
                    filled: true,
                    fillColor: context.surfaceAlt,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: context.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

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

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl4),
      child: Center(
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: context.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 30, color: context.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('No objects registered yet',
              style: AppTextStyles.h3.copyWith(color: context.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text('Tap Add to register your first object.',
              style: AppTextStyles.body.copyWith(color: context.textMuted)),
          const SizedBox(height: AppSpacing.xl2),
          GradientButton(               // ✅ fullWidth: false — not in a Row but constrained context
            label: 'Add Object',
            icon: Icons.add,
            onPressed: () => context.go('/dashboard/add-object'),
            height: 44,
            fullWidth: false,
          ),
        ]),
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
    final imageUrl     = obj['image_url'] as String? ?? '';
    final name         = obj['object_name'] as String? ?? 'Unknown';
    final location     = obj['usual_location'] as String? ?? '';
    final lastDetected = obj['last_detected_time'] as String?;
    final createdAt    = obj['created_at'] as String? ?? '';

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        dateStr = DateFormat.yMMMd()
            .format(DateTime.parse(createdAt).toLocal());
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: context.primary.withOpacity(0.10),
          ),
          child: imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                )
              : Icon(Icons.inventory_2_outlined,
                  color: context.primary, size: 26),
        ),
        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: AppTextStyles.h4.copyWith(color: context.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            if (location.isNotEmpty)
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 13, color: context.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Text(location,
                    style: AppTextStyles.bodySm
                        .copyWith(color: context.textMuted)),
              ]),
            if (lastDetected != null)
              Row(children: [
                Icon(Icons.access_time, size: 13, color: context.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Text('Last: $lastDetected',
                    style: AppTextStyles.caption
                        .copyWith(color: context.textMuted)),
              ])
            else
              Text('Added $dateStr',
                  style: AppTextStyles.caption
                      .copyWith(color: context.textMuted)),
          ]),
        ),

        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          tooltip: 'Delete',
        ),
      ]),
    );
  }
}