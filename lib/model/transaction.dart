import 'customer.dart';
import 'product.dart';

class TransactionModel {
  final String id;
  final String shopId;
  final Customer customer;
  final List<Product> products;
  final double totalPrice;
  final double amountPaid;
  final double amountDue;
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.shopId,
    required this.customer,
    required this.products,
    required this.totalPrice,
    required this.amountPaid,
    required this.amountDue,
    required this.timestamp,
  });

  // Convert TransactionModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'customer': customer.toJson(),
      'products': products.map((product) => product.toJson()).toList(),
      'totalPrice': totalPrice,
      'amountPaid': amountPaid,
      'amountDue': amountDue,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create TransactionModel from JSON (e.g., from Firestore)
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      shopId: json['shopId'],
      customer: Customer.fromJson(json['customer']),
      products: List<Product>.from(
        json['products'].map((productJson) =>
            Product.fromJson(productJson)), // Convert each JSON to Product
      ),
      totalPrice: json['totalPrice'].toDouble(),
      amountPaid: json['amountPaid'].toDouble(),
      amountDue: json['amountDue'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
