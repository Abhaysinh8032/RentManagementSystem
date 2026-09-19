import 'package:flutter/material.dart';

class ClaimPaymentResult {
  final String paymentReference;
  final String paymentProofUrl;
  ClaimPaymentResult({required this.paymentReference, required this.paymentProofUrl});
}

/// NOTE on paymentProofUrl: this backend never receives raw image bytes (see
/// backend README) - the real app should upload the screenshot to Supabase
/// Storage first and paste the resulting public URL here. Wiring that upload
/// is a follow-up task once your Supabase project/bucket exists; for now this
/// is a plain text field so the claim-payment flow is fully testable end to end.
Future<ClaimPaymentResult?> showClaimPaymentDialog(BuildContext context, {required String billLabel}) {
  final formKey = GlobalKey<FormState>();
  final referenceController = TextEditingController();
  final proofUrlController = TextEditingController();

  return showDialog<ClaimPaymentResult>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Claim $billLabel Payment'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: referenceController,
              decoration: const InputDecoration(labelText: 'Transaction ID / UTR', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: proofUrlController,
              decoration: const InputDecoration(
                labelText: 'Payment screenshot URL',
                helperText: 'Upload the screenshot to your storage first, paste the link here',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(dialogContext).pop(
                ClaimPaymentResult(
                  paymentReference: referenceController.text.trim(),
                  paymentProofUrl: proofUrlController.text.trim(),
                ),
              );
            }
          },
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}
