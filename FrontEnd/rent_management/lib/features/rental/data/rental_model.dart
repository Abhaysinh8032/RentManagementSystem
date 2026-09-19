import 'bill_model.dart';

class RentalRequestModel {
  final int id;
  final int propertyId;
  final String? propertyName;
  final int userId;
  final String? userName;
  final int quantity;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // PENDING | APPROVED | REJECTED | RETURN_REQUESTED | RETURNED
  final String? adminNote;
  final String? returnCondition;
  final String? returnNote;
  final List<BillModel> bills;

  RentalRequestModel({
    required this.id,
    required this.propertyId,
    this.propertyName,
    required this.userId,
    this.userName,
    required this.quantity,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.adminNote,
    this.returnCondition,
    this.returnNote,
    required this.bills,
  });

  BillModel? get rentBill => bills.where((b) => b.billType == 'RENT').firstOrNull;
  BillModel? get depositBill => bills.where((b) => b.billType == 'DEPOSIT').firstOrNull;

  factory RentalRequestModel.fromJson(Map<String, dynamic> json) => RentalRequestModel(
        id: json['id'] as int,
        propertyId: json['propertyId'] as int,
        propertyName: json['propertyName'] as String?,
        userId: json['userId'] as int,
        userName: json['userName'] as String?,
        quantity: json['quantity'] as int,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        status: json['status'] as String,
        adminNote: json['adminNote'] as String?,
        returnCondition: json['returnCondition'] as String?,
        returnNote: json['returnNote'] as String?,
        bills: ((json['bills'] as List?) ?? [])
            .map((b) => BillModel.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
