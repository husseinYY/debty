import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';

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

      Phoenix.rebirth(context);
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
      backgroundColor: const Color(0xFF1D1B42), // Background color
      appBar: AppBar(
        title: Text(
          'Add New Shop',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF29236A), // AppBar background color
        iconTheme:
            const IconThemeData(color: Colors.white), // Back button color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Shop Name Field
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Shop Name',
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the shop name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Shop Address Field
              TextFormField(
                controller: _addressController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Shop Address',
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the shop address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Shop Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedShopType,
                hint: Text(
                  'Select Shop Type',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                dropdownColor:
                    const Color(0xFF29236A), // Dropdown background color
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Shop Type',
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
              const SizedBox(height: 30),

              // Add Shop Button
              ElevatedButton(
                onPressed: _addShop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3E9A), // Button color
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Add Shop',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
