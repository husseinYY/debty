import '../../model/shop.dart';
import '../../view/screens/category_products.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../model/category.dart';

class Categories extends StatefulWidget {
  const Categories({super.key, required this.shop});
  final Shop shop;
  @override
  CategoriesState createState() => CategoriesState();
}

class CategoriesState extends State<Categories> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = fetchCategories();
  }

  Future<List<Category>> fetchCategories() async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      final categoryQuerySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('shops')
          .doc(widget.shop.id)
          .collection('categories')
          .get();
      final List<Category> categories = [];
      for (var doc in categoryQuerySnapshot.docs) {
        categories.add(
            Category(categoryID: doc.id, categoryName: doc.data()['name']));
      }

      return categories;
    } catch (e) {
      throw Exception("Failed to fetch categories: ${e.toString()}");
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (category.categoryName == 'Uncategorized') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You cannot delete the Uncategorized category')),
      );
      return;
    }

    try {
      // Retrieve the "Uncategorized" category by name
      final uncategorizedQuerySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('shops')
          .doc(widget.shop.id)
          .collection('categories')
          .where('name', isEqualTo: 'Uncategorized')
          .get();

      final uncategorizedDocRef =
          uncategorizedQuerySnapshot.docs.first.reference;

      // Reference to the category to be deleted
      final categoryDocRef = firestore
          .collection('users')
          .doc(userId)
          .collection('shops')
          .doc(widget.shop.id)
          .collection('categories')
          .doc(category.categoryID);

      // Move all products from the specified category to "Uncategorized"
      final productsQuerySnapshot =
          await categoryDocRef.collection('products').get();

      for (var productDoc in productsQuerySnapshot.docs) {
        final productData = productDoc.data();
        await uncategorizedDocRef
            .collection('products')
            .doc(productDoc.id)
            .set(productData);
        await productDoc.reference.delete();
      }

      // Delete the category after moving all products
      await categoryDocRef.delete();

      setState(() {
        _categoriesFuture = fetchCategories();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Category was deleted successfully, and products were moved to Uncategorized')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete category: ${e.toString()}')),
      );
    }
  }

  void _showAddCategoryDialog() {
    final TextEditingController categoryNameController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: categoryNameController,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final categoryName = categoryNameController.text;
              await _addCategory(categoryName);
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory(String categoryName) async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      // Check if the category already exists
      final categoryQuerySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('shops')
          .doc(widget.shop.id)
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .get();

      if (categoryQuerySnapshot.docs.isNotEmpty) {
        // If a category with the same name exists, show a message and do not add it
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category already exists')),
        );
        return;
      }

      // If no category with the same name exists, proceed to add the new category
      final newCategoryRef = firestore
          .collection('users')
          .doc(userId)
          .collection('shops')
          .doc(widget.shop.id)
          .collection('categories')
          .doc();
      await newCategoryRef.set({
        'categoryID': newCategoryRef.id,
        'name': categoryName,
      });

      setState(() {
        _categoriesFuture = fetchCategories();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add category: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories found.'));
          } else {
            final categories = snapshot.data!;
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryProducts(
                        category: category,
                        shop: widget.shop,
                      ),
                    ),
                  ),
                  onLongPress: () => _showDeleteConfirmationDialog(category),
                  child: Card(
                    child: ListTile(
                      title: Text(category.categoryName),
                      subtitle: Text('ID: ${category.categoryID}'),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteCategory(category);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
