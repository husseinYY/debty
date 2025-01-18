class Shop {
  final String id;
  final String name;
  final String address;
  final String type;

  Shop(
      {required this.id,
      required this.name,
      required this.address,
      required this.type});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'type': type,
    };
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      type: json['type'] as String,
    );
  }
}
