class AdminUserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status;

  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) => AdminUserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String,
        status: json['status'] as String,
      );
}
