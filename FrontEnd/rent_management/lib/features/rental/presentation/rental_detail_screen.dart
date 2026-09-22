import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../data/bill_model.dart';
import '../data/bill_repository.dart';
import '../data/rental_model.dart';
import '../data/rental_repository.dart';
import 'claim_payment_dialog.dart';
import 'decision_dialog.dart';
import 'refund_dialog.dart';

/// Shared by both roles: [isAdmin] controls which action buttons render.
/// Kept as one screen (rather than separate customer/admin screens) since the
/// read layout is identical and the only difference is which buttons show.
class RentalDetailScreen extends StatefulWidget {
  final int rentalRequestId;
  final bool isAdmin;
  const RentalDetailScreen({super.key, required this.rentalRequestId, required this.isAdmin});

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  late final RentalRepository _rentalRepository;
  late final BillRepository _billRepository;
  late Future<RentalRequestModel> _future;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _rentalRepository = RentalRepository(apiClient: apiClient);
    _billRepository = BillRepository(apiClient: apiClient);
    _future = _rentalRepository.getById(widget.rentalRequestId);
  }

  void _refresh() => setState(() => _future = _rentalRepository.getById(widget.rentalRequestId));

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _actionInProgress = true);
    try {
      await action();
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade600));
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _claimPayment(BillModel bill) async {
    final result = await showClaimPaymentDialog(context, billLabel: bill.billType == 'RENT' ? 'Rent' : 'Deposit');
    if (result == null) return;
    await _runAction(() => _billRepository.claimPayment(
          bill.id,
          paymentReference: result.paymentReference,
          paymentProofUrl: result.paymentProofUrl,
        ));
  }

  Future<void> _verifyPayment(BillModel bill) async {
    final result = await showDecisionDialog(
      context,
      title: 'Verify ${bill.billType == 'RENT' ? 'Rent' : 'Deposit'} Payment',
      approveLabel: 'Mark Paid',
      rejectLabel: 'False Claim',
    );
    if (result == null) return;
    await _runAction(() => _billRepository.verify(bill.id, approve: result.approve, adminNote: result.adminNote));
  }

  Future<void> _refundDeposit(BillModel bill) async {
    final result = await showRefundDialog(context);
    if (result == null) return;
    await _runAction(() => _billRepository.refund(bill.id, refundReference: result.refundReference, adminNote: result.adminNote));
  }

  Future<void> _decideRequest() async {
    final result = await showDecisionDialog(context, title: 'Review Rental Request');
    if (result == null) return;
    await _runAction(() => _rentalRepository.decide(widget.rentalRequestId, approve: result.approve, adminNote: result.adminNote));
  }

  Future<void> _submitReturn() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit Return Request'),
        content: const Text('Let the admin know you\'re returning this property?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(() => _rentalRepository.requestReturn(widget.rentalRequestId));
  }

  Future<void> _decideReturn() async {
    final result = await showDecisionDialog(
      context,
      title: 'Verify Return',
      approveLabel: 'Confirm Returned',
      rejectLabel: 'Not Actually Returned',
      includeDamagedToggle: true,
    );
    if (result == null) return;
    await _runAction(() => _rentalRepository.decideReturn(
          widget.rentalRequestId,
          approve: result.approve,
          damaged: result.damaged,
          adminNote: result.adminNote,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental Request')),
      body: FutureBuilder<RentalRequestModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Failed to load';
            return Center(child: Text(message));
          }

          final rental = snapshot.data!;

          return AbsorbPointer(
            absorbing: _actionInProgress,
            child: Opacity(
              opacity: _actionInProgress ? 0.6 : 1,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(rental.propertyName ?? 'Property #${rental.propertyId}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      _StatusBadge(status: rental.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (widget.isAdmin && rental.userName != null)
                    Text('Requested by ${rental.userName}', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Quantity', value: '${rental.quantity}'),
                  _DetailRow(label: 'Start date', value: _formatDate(rental.startDate)),
                  _DetailRow(label: 'End date', value: _formatDate(rental.endDate)),
                  if (rental.adminNote != null && rental.adminNote!.isNotEmpty)
                    _DetailRow(label: 'Admin note', value: rental.adminNote!),
                  if (rental.returnCondition != null)
                    _DetailRow(label: 'Return condition', value: rental.returnCondition!),
                  if (rental.returnNote != null && rental.returnNote!.isNotEmpty)
                    _DetailRow(label: 'Return note', value: rental.returnNote!),
                  const SizedBox(height: 24),
                  const Text('Bills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final bill in rental.bills) _BillCard(
                        bill: bill,
                        isAdmin: widget.isAdmin,
                        rentalReturned: rental.status == 'RETURNED',
                        onClaim: () => _claimPayment(bill),
                        onVerify: () => _verifyPayment(bill),
                        onRefund: () => _refundDeposit(bill),
                      ),
                  const SizedBox(height: 24),
                  if (widget.isAdmin && rental.status == 'PENDING')
                    FilledButton.icon(
                      onPressed: _decideRequest,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Review Request'),
                    ),
                  if (widget.isAdmin && rental.status == 'RETURN_REQUESTED')
                    FilledButton.icon(
                      onPressed: _decideReturn,
                      icon: const Icon(Icons.assignment_return_outlined),
                      label: const Text('Verify Return'),
                    ),
                  if (!widget.isAdmin && rental.status == 'APPROVED')
                    OutlinedButton.icon(
                      onPressed: _submitReturn,
                      icon: const Icon(Icons.keyboard_return),
                      label: const Text('Request Return'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'APPROVED':
      case 'RETURNED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'RETURN_REQUESTED':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status.replaceAll('_', ' '), style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillModel bill;
  final bool isAdmin;
  final bool rentalReturned;
  final VoidCallback onClaim;
  final VoidCallback onVerify;
  final VoidCallback onRefund;

  const _BillCard({
    required this.bill,
    required this.isAdmin,
    required this.rentalReturned,
    required this.onClaim,
    required this.onVerify,
    required this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    final canClaim = !isAdmin && bill.isPendingPayment;
    final canVerify = isAdmin && bill.isClaimed;
    final canRefund = isAdmin && bill.isDeposit && bill.isPaid && rentalReturned;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bill.billType == 'RENT' ? 'Rent' : 'Security Deposit', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${bill.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(bill.status.replaceAll('_', ' '), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            if (bill.paymentReference != null) Text('Ref: ${bill.paymentReference}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            if (bill.paymentProofUrl != null && bill.paymentProofUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => showFullScreenImage(context, bill.paymentProofUrl!),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        bill.paymentProofUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('View payment proof', style: TextStyle(color: Colors.indigo.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            if (bill.adminNote != null && bill.adminNote!.isNotEmpty)
              Text('Note: ${bill.adminNote}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            if (canClaim || canVerify || canRefund) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (canClaim) FilledButton.tonal(onPressed: onClaim, child: const Text('Claim Payment')),
                    if (canVerify) FilledButton.tonal(onPressed: onVerify, child: const Text('Verify Payment')),
                    if (canRefund) FilledButton.tonal(onPressed: onRefund, child: const Text('Refund Deposit')),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
