class ExpenseModel {
  final String id;
  final String communityId;
  final double amount;
  final String category;
  final String description;
  final String? receiptUrl;
  final DateTime expenseDate;
  final String? createdBy;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.communityId,
    required this.amount,
    required this.category,
    required this.description,
    this.receiptUrl,
    required this.expenseDate,
    this.createdBy,
    required this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id']?.toString() ?? '',
      communityId: map['community_id']?.toString() ?? '',
      amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0,
      category: map['category']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      receiptUrl: map['receipt_url'] as String?,
      expenseDate: map['expense_date'] != null
          ? DateTime.tryParse(map['expense_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'description': description,
      'receipt_url': receiptUrl,
      'expense_date': expenseDate.toIso8601String().split('T').first,
    };
  }

  static const List<String> categories = [
    'Kebersihan',
    'Keamanan',
    'Infrastruktur',
    'Sosial',
    'Operasional',
    'Lain-lain',
  ];
}
