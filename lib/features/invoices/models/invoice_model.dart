class InvoiceModel {
  final String id;
  final String communityId;
  final String residentId;
  final String billingTypeId;
  final double amount;
  final int month;
  final int year;
  final DateTime dueDate;
  final String status;
  final String? paymentLink;
  final String? paymentToken;
  final DateTime? waSentAt;
  final DateTime createdAt;
  final String billingTypeName;

  const InvoiceModel({
    required this.id,
    required this.communityId,
    required this.residentId,
    required this.billingTypeId,
    required this.amount,
    required this.month,
    required this.year,
    required this.dueDate,
    required this.status,
    this.paymentLink,
    this.paymentToken,
    this.waSentAt,
    required this.createdAt,
    this.billingTypeName = 'Iuran',
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> map) {
    String billingName = 'Iuran';
    if (map['billing_types'] != null && map['billing_types'] is Map) {
      billingName = map['billing_types']['name']?.toString() ?? 'Iuran';
    }

    return InvoiceModel(
      id: map['id']?.toString() ?? '',
      communityId: map['community_id']?.toString() ?? '',
      residentId: map['resident_id']?.toString() ?? '',
      billingTypeId: map['billing_type_id']?.toString() ?? '',
      amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0,
      month: map['month'] as int? ?? 1,
      year: map['year'] as int? ?? DateTime.now().year,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'].toString()) : DateTime.now(),
      status: map['status']?.toString() ?? 'pending',
      paymentLink: map['payment_link']?.toString(),
      paymentToken: map['payment_token']?.toString(),
      waSentAt: map['wa_sent_at'] != null ? DateTime.parse(map['wa_sent_at'].toString()) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
      billingTypeName: billingName,
    );
  }
}
