import '../../model/shop.dart';
import '../../view/screens/category_products.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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
        backgroundColor: const Color(0xFF29236A), // Dialog background color
        title: Text(
          'Add Category',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: TextField(
          controller: categoryNameController,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Category Name',
            labelStyle: GoogleFonts.poppins(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white70),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              final categoryName = categoryNameController.text;
              await _addCategory(categoryName);
              Navigator.of(context).pop();
            },
            child: Text(
              'Add',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
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
      backgroundColor: const Color(0xFF1D1B42), // Background color
      appBar: AppBar(
        title: Text(
          'Categories',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF29236A), // AppBar background color
        iconTheme:
            const IconThemeData(color: Colors.white), // Back button color
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No categories found.',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            );
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
                    margin: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16), // Card margin
                    color: const Color(0xFF29236A), // Card background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        category.categoryName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${category.categoryID}',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
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
        backgroundColor: const Color(0xFF5B3E9A), // FAB background color
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF29236A), // Dialog background color
        title: Text(
          'Delete Category',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this category?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _deleteCategory(category);
              Navigator.of(context).pop();
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
