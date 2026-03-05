import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// dart:io is not available on web — only import on native
import 'dart:io' if (dart.library.html) 'dart:html' as html;

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/app_theme.dart';

class AddObjectScreen extends StatefulWidget {
  const AddObjectScreen({super.key});

  @override
  State<AddObjectScreen> createState() => _AddObjectScreenState();
}

class _AddObjectScreenState extends State<AddObjectScreen> {
  final _nameController     = TextEditingController();
  final _locationController = TextEditingController();
  final _idController       = TextEditingController();
  final _formKey            = GlobalKey<FormState>();

  // Store raw bytes so we can preview on ALL platforms (web + native)
  Uint8List? _imageBytes;
  String     _imageExt = 'jpg';
  bool       _loading  = false;
  String     _error    = '';

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked == null) return;

      // readAsBytes() works on BOTH web and native
      final bytes = await picked.readAsBytes();
      final ext   = picked.name.split('.').last.toLowerCase();

      if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
        if (mounted) {
          PulseSnackBar.show(context,
              'Unsupported format. Please choose a JPG or PNG image.',
              isError: true);
        }
        return;
      }

      setState(() {
        _imageBytes = bytes;
        _imageExt   = ext == 'jpeg' ? 'jpg' : ext;
      });
    } catch (e) {
      if (mounted) {
        PulseSnackBar.show(context, 'Could not load image: $e', isError: true);
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),

              // Camera — not available on web
              if (!kIsWeb)
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined,
                      color: context.primary),
                  title: Text('Take Photo',
                      style: AppTextStyles.body
                          .copyWith(color: context.textPrimary)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),

              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: context.primary),
                title: Text('Choose from Gallery',
                    style: AppTextStyles.body
                        .copyWith(color: context.textPrimary)),
                subtitle: Text('JPG, PNG, WebP supported',
                    style: AppTextStyles.caption
                        .copyWith(color: context.textMuted)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),

              if (_imageBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  title: Text('Remove Image',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.error)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _imageBytes = null);
                  },
                ),

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = ''; });

    try {
      final user = context.read<AuthProvider>().user!;
      String imageUrl = '';

      if (_imageBytes != null) {
        imageUrl = await SupabaseService.uploadObjectImage(
            user.id, _imageBytes!, _imageExt);
      }

      await SupabaseService.addObject(
        userId:        user.id,
        objectName:    _nameController.text.trim(),
        usualLocation: _locationController.text.trim(),
        objectId:      _idController.text.trim().isNotEmpty
            ? _idController.text.trim()
            : 'OBJ-${DateTime.now().millisecondsSinceEpoch}',
        imageUrl: imageUrl,
      );

      if (mounted) {
        PulseSnackBar.show(
          context,
          '${_nameController.text} has been registered for tracking.',
          isSuccess: true,
        );
        context.go('/dashboard/objects');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Object',
              style: AppTextStyles.display
                  .copyWith(color: context.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text('Register a new item to track',
              style: AppTextStyles.body.copyWith(color: context.textMuted)),
          const SizedBox(height: AppSpacing.xl2),

          GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Image picker preview ──────────────────────────────
                  GestureDetector(
                    onTap: _showImagePicker,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 180,
                      decoration: BoxDecoration(
                        color: context.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: _imageBytes != null
                              ? context.primary.withOpacity(0.40)
                              : context.primary.withOpacity(0.20),
                          width: _imageBytes != null ? 2 : 1,
                        ),
                      ),
                      child: _imageBytes != null
                          // ✅ Image.memory works on web AND native
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  child: Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                // Overlay tap hint
                                Positioned(
                                  bottom: AppSpacing.sm,
                                  right: AppSpacing.sm,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.full),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.edit,
                                            color: Colors.white, size: 12),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text('Change',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined,
                                    size: 40, color: context.primary),
                                const SizedBox(height: AppSpacing.sm),
                                Text('Tap to upload image',
                                    style: AppTextStyles.body.copyWith(
                                        color: context.primary,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  kIsWeb
                                      ? 'JPG, PNG, WebP — choose from files'
                                      : 'JPG, PNG, WebP — camera or gallery',
                                  style: AppTextStyles.caption
                                      .copyWith(color: context.textMuted),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Fields ────────────────────────────────────────────
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Object Name *',
                      prefixIcon: Icon(Icons.label_outline),
                      hintText: 'e.g. Keys, Wallet, Laptop',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Object name is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Usual Location *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'e.g. Bedroom, Kitchen counter',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Usual location is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  TextFormField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'Object ID (optional)',
                      prefixIcon: Icon(Icons.qr_code_outlined),
                      hintText: 'Auto-generated if blank',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  // ── Error ─────────────────────────────────────────────
                  if (_error.isNotEmpty) ...[
                    InfoBanner(
                      title: 'Error',
                      body: _error,
                      icon: Icons.error_outline,
                      variant: BadgeVariant.error,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  GradientButton(
                    label: 'Register Object',
                    icon: Icons.add_circle_outline,
                    onPressed: _handleSubmit,
                    loading: _loading,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}