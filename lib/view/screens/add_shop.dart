import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddShop extends StatefulWidget {
  const AddShop({super.key});

  @override
  State<AddShop> createState() => _AddShopState();
}

class _AddShopState extends State<AddShop> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // List of predefined shop types
  final List<String> shopTypes = [
    'Grocery',
    'Clothing',
    'Electronics',
    'Furniture',
    'Bookstore',
    'Sports Equipment',
    'Pharmacy',
    'Restaurant',
    'Bakery',
    'Cosmetics',
  ];

  String? _selectedShopType;

  Future<void> _addShop() async {
    if (_formKey.currentState!.validate() && _selectedShopType != null) {
      String shopName = _nameController.text;
      String shopAddress = _addressController.text;
      String shopType = _selectedShopType!;

      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Create a new shop document under the user's collection
      var shopRef = await _firestore
          .collection('users') // Users collection
          .doc(userId) // Current user
          .collection('shops') // Shops subcollection under user
          .add({
        'name': shopName,
        'address': shopAddress,
        'type': shopType,
      });

      // Create the "Uncategorized" category for this shop
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('shops')
          .doc(shopRef.id)
          .collection('categories')
          .add({
        'name': 'Uncategorized',
        'shopId': shopRef.id,
      });

      // Go back to the previous screen after adding the shop
      Navigator.pop(context);
    } else {
      // Handle case where shop type is not selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop type')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Shop'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Shop Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the shop name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Shop Address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the shop address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Dropdown for shop type
              DropdownButtonFormField<String>(
                value: _selectedShopType,
                hint: const Text('Select Shop Type'),
                decoration: const InputDecoration(labelText: 'Shop Type'),
                items: shopTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedShopType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a shop type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addShop,
                child: const Text('Add Shop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
