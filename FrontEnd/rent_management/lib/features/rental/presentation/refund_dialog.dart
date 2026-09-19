import 'package:flutter/material.dart';

class RefundResult {
  final String? refundReference;
  final String? adminNote;
  RefundResult({this.refundReference, this.adminNote});
}

Future<RefundResult?> showRefundDialog(BuildContext context) {
  final referenceController = TextEditingController();
  final noteController = TextEditingController();

  return showDialog<RefundResult>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Settle Deposit Refund'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: referenceController,
            decoration: const InputDecoration(labelText: 'Refund reference (optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(
            RefundResult(refundReference: referenceController.text.trim(), adminNote: noteController.text.trim()),
          ),
          child: const Text('Confirm Refund'),
        ),
      ],
    ),
  );
}
