import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:liankhawpui/core/providers/app_preferences_provider.dart';
import 'package:liankhawpui/core/services/image_service.dart';
import 'package:liankhawpui/core/widgets/glass_card.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageService = ImageService();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  DateTime? _selectedDob;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  File? _selectedImage;
  String? _uploadedPhotoUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _fullNameController = TextEditingController(text: user.fullName);
    _phoneController = TextEditingController(text: user.phoneNumber ?? '+91');
    _addressController = TextEditingController(text: user.address);
    _selectedDob = user.dob;
    _uploadedPhotoUrl = user.photoUrl;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            dob: _selectedDob,
            address: _addressController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() => _isUploadingPhoto = true);
    final lowDataMode = ref.read(lowDataModeEnabledProvider);

    try {
      final File? imageFile = source == ImageSource.gallery
          ? await _imageService.pickImageFromGallery(lowDataMode: lowDataMode)
          : await _imageService.pickImageFromCamera(lowDataMode: lowDataMode);

      if (imageFile == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      final compressedData = await _imageService.compressForUpload(
        imageFile,
        lowDataMode: lowDataMode,
      );
      if (compressedData == null) {
        throw Exception('Failed to compress image');
      }

      final sizeKb = _imageService.getFileSizeInKb(compressedData);
      final photoUrl = await ref
          .read(authRepositoryProvider)
          .uploadProfilePhoto(compressedData);

      setState(() {
        _selectedImage = imageFile;
        _uploadedPhotoUrl = photoUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Photo uploaded (${sizeKb.toStringAsFixed(1)} KB${lowDataMode ? ', low-data' : ''})',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 56,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (_uploadedPhotoUrl != null
                                        ? CachedNetworkImageProvider(
                                            _uploadedPhotoUrl!,
                                          )
                                        : null),
                              child:
                                  _selectedImage == null &&
                                      _uploadedPhotoUrl == null
                                  ? const Icon(Icons.person_rounded, size: 56)
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: IconButton.filled(
                                onPressed: _isUploadingPhoto
                                    ? null
                                    : _pickAndUploadPhoto,
                                icon: _isUploadingPhoto
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.camera_alt_rounded),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GlassCard(
                          child: TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: InputBorder.none,
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please enter name'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GlassCard(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              helperText: 'Start with +91',
                              border: InputBorder.none,
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please enter phone'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GlassCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.cake_rounded),
                            title: Text(
                              _selectedDob == null
                                  ? 'Select Date of Birth'
                                  : DateFormat.yMMMd().format(_selectedDob!),
                            ),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GlassCard(
                          child: TextFormField(
                            controller: _addressController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _save,
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
