import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/image_upload_service.dart';

const int _maxClaimImages = 5; // matches backend's @Size(max = 5)

class ClaimPaymentResult {
  final String paymentReference;
  final List<String> proofImageUrls;
  ClaimPaymentResult({required this.paymentReference, required this.proofImageUrls});
}

/// Pass [initialReference]/[initialImageUrls] when the bill is already
/// PAYMENT_CLAIMED and the user is updating it (matches the backend allowing
/// claimPayment to be called again before it's decided) - leave both null for
/// a brand-new claim.
Future<ClaimPaymentResult?> showClaimPaymentDialog(
  BuildContext context, {
  required String billLabel,
  String? initialReference,
  List<String>? initialImageUrls,
}) {
  return showDialog<ClaimPaymentResult>(
    context: context,
    builder: (dialogContext) => _ClaimPaymentDialog(
      billLabel: billLabel,
      initialReference: initialReference,
      initialImageUrls: initialImageUrls,
    ),
  );
}

class _ClaimPaymentDialog extends StatefulWidget {
  final String billLabel;
  final String? initialReference;
  final List<String>? initialImageUrls;

  const _ClaimPaymentDialog({required this.billLabel, this.initialReference, this.initialImageUrls});

  bool get isEditing => initialReference != null || (initialImageUrls?.isNotEmpty ?? false);

  @override
  State<_ClaimPaymentDialog> createState() => _ClaimPaymentDialogState();
}

class _ClaimPaymentDialogState extends State<_ClaimPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _referenceController;
  late final ImageUploadService _imageUploadService;
  final ImagePicker _imagePicker = ImagePicker();

  late List<String> _imageUrls;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _imageUploadService = ImageUploadService(apiClient: context.read<ApiClient>());
    _referenceController = TextEditingController(text: widget.initialReference ?? '');
    _imageUrls = List.of(widget.initialImageUrls ?? []);
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
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

    // Deliberately NOT passing maxWidth/imageQuality here (unlike the property
    // form's picker call) - a payment screenshot may need to be read for an
    // exact reference number or amount, so this keeps every picked image at
    // its original resolution/quality before it even reaches the upload step.
    final picked = await _imagePicker.pickImage(source: source);
    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      final url = await _imageUploadService.uploadPaymentProofImage(File(picked.path));
      if (!mounted) return;
      setState(() => _imageUrls.add(url));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red.shade600),
      );
//      setState(() => _pickedFile = null);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach at least one payment screenshot')),
      );
      return;
    }
    Navigator.of(context).pop(
      ClaimPaymentResult(paymentReference: _referenceController.text.trim(), proofImageUrls: _imageUrls),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Update ${widget.billLabel} Claim' : 'Claim ${widget.billLabel} Payment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(labelText: 'Transaction ID / UTR', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Text('Screenshots (${_imageUrls.length}/$_maxClaimImages)', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            // Wrap, not a horizontal ListView: AlertDialog sizes its content
            // via IntrinsicWidth internally, and a ListView's Viewport
            // explicitly refuses to report an intrinsic size - that combo is
            // exactly what crashed. Wrap has no Viewport, so it's immune.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < _imageUrls.length; i++) _ImageThumb(url: _imageUrls[i], onRemove: () => _removeImage(i)),
                if (_imageUrls.length < _maxClaimImages)
                  GestureDetector(
                    onTap: _uploading ? null : _pickAndUpload,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _uploading
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade500),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _uploading ? null : _submit,
          child: Text(widget.isEditing ? 'Save Changes' : 'Submit'),
        ),
      ],
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
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
