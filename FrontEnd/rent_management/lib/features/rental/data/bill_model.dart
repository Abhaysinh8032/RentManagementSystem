class BillModel {
  final int id;
  final int rentalRequestId;
  final String billType; // RENT | DEPOSIT
  final double amount;
  final String status; // PENDING_PAYMENT | PAYMENT_CLAIMED | PAID | REJECTED | REFUNDED
  final String? paymentReference;
  final List<String> proofImageUrls;
  final String? adminNote;

  BillModel({
    required this.id,
    required this.rentalRequestId,
    required this.billType,
    required this.amount,
    required this.status,
    this.paymentReference,
    required this.proofImageUrls,
    this.adminNote,
  });

  bool get isDeposit => billType == 'DEPOSIT';
  bool get isPendingPayment => status == 'PENDING_PAYMENT';
  bool get isClaimed => status == 'PAYMENT_CLAIMED';
  bool get isPaid => status == 'PAID';
  bool get isRefunded => status == 'REFUNDED';

  // Claim can be submitted OR updated any time before the admin decides it -
  // matches the backend's relaxed claimPayment guard.
  bool get canSubmitOrEditClaim => isPendingPayment || isClaimed;

  factory BillModel.fromJson(Map<String, dynamic> json) => BillModel(
        id: json['id'] as int,
        rentalRequestId: json['rentalRequestId'] as int,
        billType: json['billType'] as String,
        amount: (json['amount'] as num).toDouble(),
        status: json['status'] as String,
        paymentReference: json['paymentReference'] as String?,
        proofImageUrls: ((json['proofImageUrls'] as List?) ?? []).map((e) => e as String).toList(),
        adminNote: json['adminNote'] as String?,
      );
}
