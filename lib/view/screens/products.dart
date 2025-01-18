import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../model/product.dart';
import '../../model/shop.dart';
import 'add_product.dart';

class Products extends StatefulWidget {
  final Shop shop;
  const Products({super.key, required this.shop});

  @override
  ProductsState createState() => ProductsState();
}

class ProductsState extends State<Products> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchAllProducts();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = _fetchAllProducts();
    });
  }

  Future<List<Product>> _fetchAllProducts() async {
    List<Product> allProducts = [];
    try {
      // Fetch all categories for the specified shop
      final categoriesQuerySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('shops')
          .doc(widget.shop.id) // Use the shop from the widget
          .collection('categories')
          .get();

      // Iterate through each category
      for (var categoryDoc in categoriesQuerySnapshot.docs) {
        final categoryId = categoryDoc.id;

        // Fetch all products in the category
        final productsSnapshot = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('shops')
            .doc(widget.shop.id)
            .collection('categories')
            .doc(categoryId)
            .collection('products')
            .get();

        // Add products to the allProducts list
        allProducts.addAll(productsSnapshot.docs
            .map((doc) => Product.fromJson(doc.data()))
            .toList());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: ${e.toString()}')),
      );
    }
    return allProducts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onLongPress: () =>
                    _showDeleteConfirmationDialog(context, product),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: Text(product.name),
                    subtitle:
                        Text('Price: \$${product.price.toStringAsFixed(2)}'),
                  ),
                ),
              );
            },
          );
        },
      ),
      // FAB to add a new product to the current category
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddProduct(
                      shop: widget.shop,
                      onProductAdded: _refreshProducts,
                    ))),
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('shops')
          .doc(widget.shop.id)
          .collection('categories')
          .doc(product.categoryId)
          .collection('products')
          .doc(product.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product ${product.name} deleted successfully')),
      );
      setState(() {
        _productsFuture = _fetchAllProducts();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e')),
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteProduct(product);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
