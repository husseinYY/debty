import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/shop.dart';
import 'add_shop.dart';
import 'shop_details.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userId =
      FirebaseAuth.instance.currentUser?.uid; // Get current user's ID
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Management Solution'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(userId)
              .collection('shops')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No shops found"));
            }
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var shop = snapshot.data!.docs[index];
                final Shop shopModel = Shop(
                    id: shop.id,
                    name: shop['name'],
                    address: shop['address'],
                    type: shop['type']);

                return _buildShopCard(context, shopModel);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const AddShop())),
        tooltip: 'Add New Shop',
        child: const Icon(Icons.add),
      ),
    );
  }

  // -***************************************** TESTED ***********************************-;

  Widget _buildShopCard(BuildContext context, Shop shopData) {
    return GestureDetector(
      onTap: () {
        // Navigate to the shop details page on tap
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetails(shop: shopData),
          ),
        );
      },
      onLongPress: () {
        // On long press, delete the shop and its related data
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Shop"),
            content: const Text(
                "Are you sure you want to delete this shop and all its data?"),
            actions: [
              TextButton(
                onPressed: () {
                  // Close the dialog
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => deleteShop(context, shopData),
                child: const Text("Delete"),
              ),
            ],
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              shopData.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(shopData.address),
            Text(shopData.type),
          ],
        ),
      ),
    );
  }

  Future<void> deleteShop(BuildContext context, Shop shopData) async {
    Navigator.pop(context);
    final firestore = FirebaseFirestore.instance;

    final shopId = shopData.id; // Get shop ID to delete

    try {
      // Reference to the shop document
      final shopDocRef = firestore
          .collection('users') // Users collection
          .doc(userId) // Current user
          .collection('shops') // Shops subcollection
          .doc(shopId); // Shop ID to delete

      // Delete all related subcollections (products, categories, etc.) before deleting the shop
      final productsCollection = shopDocRef.collection('products');
      final categoriesCollection = shopDocRef.collection('categories');
      final customersCollection = shopDocRef.collection('customers');
      final debtsCollection = shopDocRef.collection('debts');

      // Delete all products in the shop
      final productsSnapshot = await productsCollection.get();
      for (var doc in productsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all categories in the shop
      final categoriesSnapshot = await categoriesCollection.get();
      for (var doc in categoriesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all customers in the shop
      final customersSnapshot = await customersCollection.get();
      for (var doc in customersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all debts in the shop
      final debtsSnapshot = await debtsCollection.get();
      for (var doc in debtsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Finally, delete the shop itself
      await shopDocRef.delete();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop deleted successfully')),
      );
      Navigator.of(context).pop(); // Close the dialog or navigate back
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

// -***************************************** TESTED ***********************************-;
