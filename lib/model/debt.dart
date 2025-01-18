class Debt {
  final String customerId;
  final String customerName;
  final double amountDue;

  Debt({
    required this.customerId,
    required this.customerName,
    required this.amountDue,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      customerId: json['customerId'],
      customerName: json['customerName'],
      amountDue: json['amountDue'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'amountDue': amountDue,
    };
  }
}
