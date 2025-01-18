class Customer {
  final String id;
  final String name;
  final String phone;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
  });

  // Override equality to compare based on `id`
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['customerId'],
      name: json['customerName'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': id,
      'customerName': name,
      'phone': phone,
    };
  }
}
