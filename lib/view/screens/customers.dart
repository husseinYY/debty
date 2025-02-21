import '../../model/shop.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/customer.dart'; // Assuming this model is the one you provided

class Customers extends StatefulWidget {
  const Customers({super.key, required this.shop});
  final Shop shop;

  @override
  CustomersState createState() => CustomersState();
}

class CustomersState extends State<Customers> {
  late Future<List<Customer>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _customersFuture = fetchCustomers();
  }

  Future<List<Customer>> fetchCustomers() async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      final customerQuerySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('shops')
          .doc(widget.shop.id)
          .collection('customers')
          .get();

      final List<Customer> customers = [];
      for (var doc in customerQuerySnapshot.docs) {
        customers.add(
          Customer(
            id: doc.id,
            name: doc.data()['customerName'],
            phone: doc.data()['phone'],
          ),
        );
      }
      return customers;
    } catch (e) {
      throw Exception("Failed to fetch customers: ${e.toString()}");
    }
  }

  Future<void> _deleteCustomer(String customerId) async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      // Retrieve the customer document to be deleted
      final customerDocRef = firestore
          .collection('users')
          .doc(userId)
          .collection('shops')
          .doc(widget.shop.id)
          .collection('customers')
          .doc(customerId);

      // Delete the customer
      await customerDocRef.delete();

      setState(() {
        _customersFuture = fetchCustomers();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete customer: ${e.toString()}')),
      );
    }
  }

  void _showAddCustomerDialog() {
    final TextEditingController customerNameController =
        TextEditingController();
    final TextEditingController customerPhoneController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF29236A), // Dialog background color
        title: Text(
          'Add Customer',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customerNameController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Customer Name',
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
            TextField(
              controller: customerPhoneController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Phone Number',
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
              keyboardType: TextInputType.phone,
            ),
          ],
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
              final customerName = customerNameController.text;
              final customerPhone = customerPhoneController.text;
              await _addCustomer(customerName, customerPhone);
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

  Future<void> _addCustomer(String customerName, String customerPhone) async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      // Add the new customer to Firestore
      final newCustomerRef = firestore
          .collection('users')
          .doc(userId)
          .collection('shops')
          .doc(widget.shop.id)
          .collection('customers')
          .doc();

      await newCustomerRef.set({
        'customerName': customerName,
        'phone': customerPhone,
      });

      setState(() {
        _customersFuture = fetchCustomers();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add customer: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1B42), // Background color
      appBar: AppBar(
        title: Text(
          'Customers',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF29236A), // AppBar background color
        iconTheme:
            const IconThemeData(color: Colors.white), // Back button color
      ),
      body: FutureBuilder<List<Customer>>(
        future: _customersFuture,
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
                'No customers found.',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            );
          } else {
            final customers = snapshot.data!;
            return ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return GestureDetector(
                  onLongPress: () => _showDeleteConfirmationDialog(customer.id),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16), // Card margin
                    color: const Color(0xFF29236A), // Card background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                      title: Text(
                        customer.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Phone: ${customer.phone}',
                        style: GoogleFonts.poppins(color: Colors.white70),
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
        onPressed: () => _showAddCustomerDialog(),
        tooltip: 'Add Customer',
        backgroundColor: const Color(0xFF5B3E9A), // FAB background color
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(String customerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF29236A), // Dialog background color
        title: Text(
          'Delete Customer',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this customer?',
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
              await _deleteCustomer(customerId);
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
