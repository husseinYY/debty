class Category {
  final String categoryID;
  final String categoryName;

  Category({required this.categoryID, required this.categoryName});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryID: json['categoryID'],
      categoryName: json['name'],
    );
  }
}
