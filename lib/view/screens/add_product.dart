import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/category.dart';
import '../../model/product.dart';
import '../../model/shop.dart';

class AddProduct extends StatefulWidget {
  final Category? category;
  final Shop shop;
  final VoidCallback onProductAdded; // Callback function

  const AddProduct({
    super.key,
    this.category,
    required this.shop,
    required this.onProductAdded, // Receive the callback
  });

  @override
  AddProductState createState() => AddProductState();
}

class AddProductState extends State<AddProduct> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  late Future<List<Category>> _categoriesFuture;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategories();
    _selectedCategoryId =
        widget.category?.categoryID; // Use ID instead of object
  }

  Future<List<Category>> _fetchCategories() async {
    final categoriesSnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('shops')
        .doc(widget.shop.id)
        .collection('categories')
        .get();

    return categoriesSnapshot.docs.map((doc) {
      return Category(categoryID: doc.id, categoryName: doc['name']);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1B42), // Background color
      appBar: AppBar(
        title: Text(
          'Add Product',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF29236A), // AppBar background color
        iconTheme:
            const IconThemeData(color: Colors.white), // Back button color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Product Name Field
            TextField(
              controller: _nameController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Product Name',
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
            const SizedBox(height: 20),

            // Price Field
            TextField(
              controller: _priceController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Price',
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
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            FutureBuilder<List<Category>>(
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
                }

                final categories = snapshot.data!;
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF29236A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCategoryId,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategoryId = newValue;
                      });
                    },
                    dropdownColor: const Color(0xFF29236A),
                    style: GoogleFonts.poppins(color: Colors.white),
                    items: categories.map((Category category) {
                      return DropdownMenuItem<String>(
                        value: category.categoryID,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            category.categoryName,
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                    hint: Text(
                      'Select Category',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Add Product Button
            ElevatedButton(
              onPressed: () => _addProduct(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3E9A), // Button color
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Add Product',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProduct() async {
    final name = _nameController.text;
    final price = double.tryParse(_priceController.text);

    if (name.isEmpty || price == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }
    final newProduct = Product(
      id: _firestore.collection('products').doc().id,
      name: name,
      price: price,
      categoryId: _selectedCategoryId!, // Using categoryID
    );

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('shops')
        .doc(widget.shop.id)
        .collection('categories')
        .doc(_selectedCategoryId)
        .collection('products')
        .doc(newProduct.id)
        .set(newProduct.toJson());

    widget.onProductAdded(); // Invoke the callback before popping
    Navigator.of(context).pop(); // Pop the screen after adding product
  }
}
