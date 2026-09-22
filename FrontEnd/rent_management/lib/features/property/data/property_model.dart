class PropertyModel {
  final int id;
  final String name;
  final String? category;
  final String? description;
  final String? imageUrl;
  final int totalQuantity;
  final int availableQuantity;
  final double pricePerUnitPerDay;
  final double depositPerUnit;
  final bool active;

  PropertyModel({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.imageUrl,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.pricePerUnitPerDay,
    required this.depositPerUnit,
    required this.active,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) => PropertyModel(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String?,
        description: json['description'] as String?,
        imageUrl: json['imageUrl'] as String?,
        totalQuantity: json['totalQuantity'] as int,
        availableQuantity: json['availableQuantity'] as int,
        pricePerUnitPerDay: (json['pricePerUnitPerDay'] as num).toDouble(),
        depositPerUnit: (json['depositPerUnit'] as num).toDouble(),
        active: json['active'] as bool? ?? true,
      );

  // Used for the optimistic toggle on AdminPropertiesScreen - flips `active`
  // locally without waiting for a full re-fetch.
  PropertyModel copyWith({bool? active}) => PropertyModel(
        id: id,
        name: name,
        category: category,
        description: description,
        imageUrl: imageUrl,
        totalQuantity: totalQuantity,
        availableQuantity: availableQuantity,
        pricePerUnitPerDay: pricePerUnitPerDay,
        depositPerUnit: depositPerUnit,
        active: active ?? this.active,
      );
}
