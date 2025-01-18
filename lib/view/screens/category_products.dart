import '../../model/shop.dart';
import '../../view/screens/add_product.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../model/category.dart';
import '../../model/product.dart';

class CategoryProducts extends StatefulWidget {
  final Category category;
  final Shop shop;
  const CategoryProducts(
      {required this.category, required this.shop, super.key});

  @override
  CategoryProductsState createState() => CategoryProductsState();
}

class CategoryProductsState extends State<CategoryProducts> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProductsByCategory();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = _fetchProductsByCategory();
    });
  }

  Future<List<Product>> _fetchProductsByCategory() async {
    final productsQuerySnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('shops')
        .doc(widget.shop.id) // Use the shop ID
        .collection('categories')
        .doc(widget.category.categoryID) // Use the category ID
        .collection('products') // Navigate to products collection
        .get(); // Use get() for a one-time fetch

    final List<Product> products = productsQuerySnapshot.docs.map((doc) {
      return Product(
        id: doc.id,
        name: doc.data()['productName'],
        categoryId: widget.category.categoryID,
        price: doc.data()['price'],
      );
    }).toList();

    return products;
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
        _productsFuture = _fetchProductsByCategory();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products in ${widget.category.categoryName}'),
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
                      category: widget.category,
                      shop: widget.shop,
                      onProductAdded: _refreshProducts,
                    ))),
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
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
