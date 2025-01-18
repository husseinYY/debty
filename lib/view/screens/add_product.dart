import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            FutureBuilder<List<Category>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No categories found.');
                }

                final categories = snapshot.data!;
                return DropdownButton<String>(
                  value: _selectedCategoryId,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategoryId = newValue;
                    });
                  },
                  items: categories.map((Category category) {
                    return DropdownMenuItem<String>(
                      value: category.categoryID,
                      child: Text(category.categoryName),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _addProduct(),
              child: const Text('Add Product'),
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
