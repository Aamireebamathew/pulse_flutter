import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class AddObjectScreen extends StatefulWidget {
  const AddObjectScreen({super.key});

  @override
  State<AddObjectScreen> createState() => _AddObjectScreenState();
}

class _AddObjectScreenState extends State<AddObjectScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _idController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _imageFile;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final user = context.read<AuthProvider>().user!;
      String imageUrl = '';

      if (_imageFile != null) {
        final Uint8List bytes = await _imageFile!.readAsBytes();
        final ext = _imageFile!.path.split('.').last;
        imageUrl =
            await SupabaseService.uploadObjectImage(user.id, bytes, ext);
      }

      await SupabaseService.addObject(
        userId: user.id,
        objectName: _nameController.text.trim(),
        usualLocation: _locationController.text.trim(),
        objectId: _idController.text.trim().isNotEmpty
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
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Object',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text('Register a new item to track',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
          const SizedBox(height: 24),

          GlassCard(
            child: Material(                      // ← FIX: wrap with Material
              color: Colors.transparent,          // ← keeps GlassCard styling
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image picker
                    GestureDetector(
                      onTap: _showImagePicker,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.2),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_imageFile!,
                                    fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined,
                                      size: 40, color: Color(0xFF3B82F6)),
                                  SizedBox(height: 8),
                                  Text('Tap to upload image',
                                      style: TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontWeight: FontWeight.w500)),
                                  Text('Supports JPG, PNG',
                                      style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

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
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Object ID (optional)',
                        prefixIcon: Icon(Icons.qr_code_outlined),
                        hintText: 'Auto-generated if blank',
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_error.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error,
                            style: const TextStyle(color: Colors.red)),
                      ),

                    GradientButton(
                      label: 'Register Object',
                      onPressed: _handleSubmit,
                      loading: _loading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}