import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/image_upload_service.dart';
import '../../property/data/property_model.dart';
import '../../property/data/property_repository.dart';

const int _maxPropertyImages = 6; // matches backend's @Size(max = 6)

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
  late final TextEditingController _totalQuantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _depositController;

  // Full-replace semantics on submit, matching the backend: this list IS the
  // complete image set sent with the request, not an incremental diff.
  late List<String> _imageUrls;
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
    _totalQuantityController = TextEditingController(text: p?.totalQuantity.toString() ?? '');
    _priceController = TextEditingController(text: p?.pricePerUnitPerDay.toString() ?? '');
    _depositController = TextEditingController(text: p?.depositPerUnit.toString() ?? '');
    _imageUrls = List.of(p?.imageUrls ?? []);
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

    setState(() => _uploadingImage = true);

    try {
      final uploadedUrl = await _imageUploadService.uploadPropertyImage(File(picked.path));
      if (!mounted) return;
      setState(() => _imageUrls.add(uploadedUrl));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade600),
      );
      //      setState(() => _pickedFile = null);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final body = {
      'name': _nameController.text.trim(),
      'category': _categoryController.text.trim(),
      'description': _descriptionController.text.trim(),
      //      'imageUrl': _imageUrlController.text.trim(),
      'imageUrls': _imageUrls,
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
            Text('Photos (${_imageUrls.length}/$_maxPropertyImages)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (int i = 0; i < _imageUrls.length; i++) _ImageThumb(url: _imageUrls[i], onRemove: () => _removeImage(i)),
                  if (_imageUrls.length < _maxPropertyImages)
                    GestureDetector(
                      onTap: _uploadingImage ? null : _pickAndUploadImage,
                      child: Container(
                        width: 88,
                        height: 88,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.indigo.shade100),
                        ),
                        child: _uploadingImage
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 26, color: Colors.indigo.shade300),
                                  const SizedBox(height: 4),
                                  Text('Add', style: TextStyle(color: Colors.indigo.shade300, fontSize: 11)),
                                ],
                              ),
                      ),
                    ),
                ],
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

class _ImageThumb extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;
  const _ImageThumb({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 88,
          height: 88,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2,
          right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
