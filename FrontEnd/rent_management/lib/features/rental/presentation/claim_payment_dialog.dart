import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/image_upload_service.dart';

class ClaimPaymentResult {
  final String paymentReference;
  final String paymentProofUrl;
  ClaimPaymentResult({required this.paymentReference, required this.paymentProofUrl});
}

Future<ClaimPaymentResult?> showClaimPaymentDialog(BuildContext context, {required String billLabel}) {
  return showDialog<ClaimPaymentResult>(
    context: context,
    builder: (dialogContext) => _ClaimPaymentDialog(billLabel: billLabel),
  );
}

class _ClaimPaymentDialog extends StatefulWidget {
  final String billLabel;
  const _ClaimPaymentDialog({required this.billLabel});

  @override
  State<_ClaimPaymentDialog> createState() => _ClaimPaymentDialogState();
}

class _ClaimPaymentDialogState extends State<_ClaimPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  late final ImageUploadService _imageUploadService;
  final ImagePicker _imagePicker = ImagePicker();

  File? _pickedFile;
  String? _uploadedUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _imageUploadService = ImageUploadService(apiClient: context.read<ApiClient>());
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
    // exact reference number or amount, so this keeps the picked image at its
    // original resolution/quality before it even reaches the upload step.
    final picked = await _imagePicker.pickImage(source: source);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _pickedFile = file;
      _uploading = true;
      _uploadedUrl = null;
    });

    try {
      final url = await _imageUploadService.uploadPaymentProofImage(file);
      if (!mounted) return;
      setState(() => _uploadedUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red.shade600),
      );
      setState(() => _pickedFile = null);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a payment screenshot')),
      );
      return;
    }
    Navigator.of(context).pop(
      ClaimPaymentResult(paymentReference: _referenceController.text.trim(), paymentProofUrl: _uploadedUrl!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Claim ${widget.billLabel} Payment'),
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
            GestureDetector(
              onTap: _uploading ? null : _pickAndUpload,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  image: _pickedFile != null
                      ? DecorationImage(image: FileImage(_pickedFile!), fit: BoxFit.cover)
                      : null,
                ),
                child: _uploading
                    ? const Center(child: CircularProgressIndicator())
                    : _pickedFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file_outlined, color: Colors.grey.shade500),
                              const SizedBox(height: 6),
                              Text('Attach payment screenshot', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          )
                        : (_uploadedUrl != null
                            ? Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                                ),
                              )
                            : null),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _uploading ? null : _submit,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
