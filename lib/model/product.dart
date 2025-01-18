class Product {
  final String id;
  final String name;
  final double price;
  final String categoryId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['productId'],
      name: json['productName'],
      price: json['price'].toDouble(),
      categoryId: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': id,
      'productName': name,
      'price': price,
      'category': categoryId,
    };
  }
}
