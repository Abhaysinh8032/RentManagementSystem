import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/image_upload_service.dart';
import '../../property/data/property_model.dart';
import '../../property/data/property_repository.dart';

/// Pass [existing] to edit, or leave null to create. Both cases share one
/// form since the fields and validation are identical.
class AdminPropertyFormScreen extends StatefulWidget {
  final PropertyModel? existing;
  const AdminPropertyFormScreen({super.key, this.existing});

  @override
  State<AdminPropertyFormScreen> createState() => _AdminPropertyFormScreenState();
}

class _AdminPropertyFormScreenState extends State<AdminPropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PropertyRepository _repository;
  late final ImageUploadService _imageUploadService;
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
//  late final TextEditingController _imageUrlController;
  late final TextEditingController _totalQuantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _depositController;

  // Replaces the old plain "Image URL" text field. _imageUrl holds either the
  // existing property's image (when editing) or the freshly uploaded one;
  // _pickedFile is only used for showing an instant local preview while the
  // upload is in flight.
  String? _imageUrl;
  File? _pickedFile;
  bool _uploadingImage = false;

  bool _submitting = false;
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _repository = PropertyRepository(apiClient: context.read<ApiClient>());
    _imageUploadService = ImageUploadService(apiClient: context.read<ApiClient>());
    final p = widget.existing;
    _nameController = TextEditingController(text: p?.name ?? '');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
//    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _totalQuantityController = TextEditingController(text: p?.totalQuantity.toString() ?? '');
    _priceController = TextEditingController(text: p?.pricePerUnitPerDay.toString() ?? '');
    _depositController = TextEditingController(text: p?.depositPerUnit.toString() ?? '');
    _imageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
//    _imageUrlController.dispose();
    _totalQuantityController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _imagePicker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _pickedFile = file;
      _uploadingImage = true;
    });

    try {
      final uploadedUrl = await _imageUploadService.uploadPropertyImage(file);
      if (!mounted) return;
      setState(() => _imageUrl = uploadedUrl);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Deliberately not using ApiException here - this hits Supabase Storage
      // directly, not our own backend, so DioException shapes differ.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Image upload failed - check ImageUploadService has your real Supabase URL/key filled in.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      setState(() => _pickedFile = null);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final body = {
      'name': _nameController.text.trim(),
      'category': _categoryController.text.trim(),
      'description': _descriptionController.text.trim(),
//      'imageUrl': _imageUrlController.text.trim(),
      'imageUrl': _imageUrl ?? '',
      'totalQuantity': int.parse(_totalQuantityController.text.trim()),
      'pricePerUnitPerDay': double.parse(_priceController.text.trim()),
      'depositPerUnit': double.parse(_depositController.text.trim()),
    };

    try {
      if (_isEditing) {
        await _repository.update(widget.existing!.id, body);
      } else {
        await _repository.create(body);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade600));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Property' : 'New Property')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: _uploadingImage ? null : _pickAndUploadImage,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                    image: _pickedFile != null
                        ? DecorationImage(image: FileImage(_pickedFile!), fit: BoxFit.cover)
                        : (_imageUrl != null && _imageUrl!.isNotEmpty)
                            ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover)
                            : null,
                  ),
                  child: _uploadingImage
                      ? const Center(child: CircularProgressIndicator())
                      : (_pickedFile == null && (_imageUrl == null || _imageUrl!.isEmpty))
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.indigo.shade300),
                                const SizedBox(height: 6),
                                Text('Add Photo', style: TextStyle(color: Colors.indigo.shade300, fontSize: 12)),
                              ],
                            )
                          : Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.edit, size: 16, color: Colors.white),
                              ),
                            ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder(), hintText: 'e.g. decor, seating'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
//            ),
//            const SizedBox(height: 14),
//            TextFormField(
//              controller: _imageUrlController,
//              decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _totalQuantityController,
              decoration: const InputDecoration(labelText: 'Total quantity', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = int.tryParse(v.trim());
                if (n == null || n < 1) return 'Must be at least 1';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price per unit per day (₹)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _depositController,
              decoration: const InputDecoration(labelText: 'Deposit per unit (₹)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v.trim());
                if (n == null || n < 0) return 'Cannot be negative';
                return null;
              },
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              Text(
                'Changing total quantity adjusts available stock by the same delta - it won\'t retroactively cancel active rentals.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
//              onPressed: _submitting ? null : _submit,
              onPressed: (_submitting || _uploadingImage) ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Save Changes' : 'Create Property'),
            ),
          ],
        ),
      ),
    );
  }
}
