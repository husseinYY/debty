import '../../model/shop.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        title: const Text('Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customerNameController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            TextField(
              controller: customerPhoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final customerName = customerNameController.text;
              final customerPhone = customerPhoneController.text;
              await _addCustomer(customerName, customerPhone);
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
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
      appBar: AppBar(title: const Text('Customers')),
      body: FutureBuilder<List<Customer>>(
        future: _customersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No customers found.'));
          } else {
            final customers = snapshot.data!;
            return ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return GestureDetector(
                  onLongPress: () => _showDeleteConfirmationDialog(customer.id),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.person), // User icon
                      title: Text(customer.name),
                      subtitle: Text('Phone: ${customer.phone}'),
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
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteCustomer(customerId);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
