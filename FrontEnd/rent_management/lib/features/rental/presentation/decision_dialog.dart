import 'package:flutter/material.dart';

class DecisionResult {
  final bool approve;
  final bool damaged;
  final String? adminNote;
  DecisionResult({required this.approve, this.damaged = false, this.adminNote});
}

/// One reusable dialog for every admin approve/reject action: rental request
/// decisions, payment verification, and return decisions. [includeDamagedToggle]
/// only applies to the return-decision screen.
Future<DecisionResult?> showDecisionDialog(
  BuildContext context, {
  required String title,
  String approveLabel = 'Approve',
  String rejectLabel = 'Reject',
  bool includeDamagedToggle = false,
}) {
  final noteController = TextEditingController();
  bool damaged = false;

  return showDialog<DecisionResult>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
            ),
            if (includeDamagedToggle) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Item returned damaged'),
                value: damaged,
                onChanged: (v) => setState(() => damaged = v),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              DecisionResult(approve: false, damaged: damaged, adminNote: noteController.text.trim()),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
            child: Text(rejectLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              DecisionResult(approve: true, damaged: damaged, adminNote: noteController.text.trim()),
            ),
            child: Text(approveLabel),
          ),
        ],
      ),
    ),
  );
}
