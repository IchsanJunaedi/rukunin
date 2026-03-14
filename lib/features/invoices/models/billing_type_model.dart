class BillingTypeModel {
  final String id;
  final String communityId;
  final String name;
  final double amount;
  final int billingDay;
  final bool isActive;
  final double costPerMotorcycle;
  final double costPerCar;
  final DateTime createdAt;

  const BillingTypeModel({
    required this.id,
    required this.communityId,
    required this.name,
    required this.amount,
    required this.billingDay,
    required this.isActive,
    this.costPerMotorcycle = 0,
    this.costPerCar = 0,
    required this.createdAt,
  });

  factory BillingTypeModel.fromMap(Map<String, dynamic> map) {
    return BillingTypeModel(
      id: map['id']?.toString() ?? '',
      communityId: map['community_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0,
      billingDay: map['billing_day'] as int? ?? 10,
      isActive: map['is_active'] as bool? ?? true,
      costPerMotorcycle: double.tryParse(map['cost_per_motorcycle']?.toString() ?? '0') ?? 0,
      costPerCar: double.tryParse(map['cost_per_car']?.toString() ?? '0') ?? 0,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'billing_day': billingDay,
      'is_active': isActive,
      'cost_per_motorcycle': costPerMotorcycle,
      'cost_per_car': costPerCar,
    };
  }

  BillingTypeModel copyWith({
    String? id,
    String? communityId,
    String? name,
    double? amount,
    int? billingDay,
    bool? isActive,
    double? costPerMotorcycle,
    double? costPerCar,
    DateTime? createdAt,
  }) {
    return BillingTypeModel(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingDay: billingDay ?? this.billingDay,
      isActive: isActive ?? this.isActive,
      costPerMotorcycle: costPerMotorcycle ?? this.costPerMotorcycle,
      costPerCar: costPerCar ?? this.costPerCar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
