import '../../model/shop.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../model/debt.dart';

class Debts extends StatefulWidget {
  const Debts({super.key, required this.shop});
  final Shop shop;

  @override
  DebtsState createState() => DebtsState();
}

class DebtsState extends State<Debts> {
  late Future<List<Debt>> _debtsFuture;

  @override
  void initState() {
    super.initState();
    _debtsFuture = fetchDebts();
  }

  Future<List<Debt>> fetchDebts() async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      final debtQuerySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('shops')
          .doc(widget.shop.id)
          .collection('debts')
          .get();

      final List<Debt> debts = [];
      for (var doc in debtQuerySnapshot.docs) {
        debts.add(Debt(
            customerId: doc.id,
            amountDue: doc.data()['amountDue'],
            customerName: doc.data()['customerName']));
      }

      return debts;
    } catch (e) {
      throw Exception("Failed to fetch debts: ${e.toString()}");
    }
  }

  Future<void> _deleteDebt(String debtID) async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('shops')
          .doc(widget.shop.id)
          .collection('debts')
          .doc(debtID)
          .delete();

      setState(() {
        _debtsFuture = fetchDebts();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debt deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete debt: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debts')),
      body: FutureBuilder<List<Debt>>(
        future: _debtsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No debts found.'));
          } else {
            final debts = snapshot.data!;
            return ListView.builder(
              itemCount: debts.length,
              itemBuilder: (context, index) {
                final debt = debts[index];
                return GestureDetector(
                  onLongPress: () =>
                      _showDeleteConfirmationDialog(debt.customerId),
                  child: Card(
                    child: ListTile(
                      title: Text(debt.customerName),
                      subtitle: Text('\$${debt.amountDue}'),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(String debtID) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Debt'),
        content: const Text('Are you sure you want to delete this debt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteDebt(debtID);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
