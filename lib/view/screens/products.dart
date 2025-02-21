import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFF1D1B42), // Background color
      appBar: AppBar(
        title: Text(
          'All Products',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF29236A), // AppBar background color
        iconTheme:
            const IconThemeData(color: Colors.white), // Back button color
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
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
                'No products found.',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            );
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
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16), // Card margin
                  color: const Color(0xFF29236A), // Card background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.shopping_bag,
                      color: Colors.white,
                    ),
                    title: Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Price: \$${product.price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
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
            ),
          ),
        ),
        tooltip: 'Add Product',
        backgroundColor: const Color(0xFF5B3E9A), // FAB background color
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
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
        backgroundColor: const Color(0xFF29236A), // Dialog background color
        title: Text(
          'Delete Product',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this product?',
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
            onPressed: () {
              _deleteProduct(product);
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
