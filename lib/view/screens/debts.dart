import '../../model/shop.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFF1D1B42), // Background color
      appBar: AppBar(
        title: Text(
          'Debts',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF29236A), // AppBar background color
        iconTheme:
            const IconThemeData(color: Colors.white), // Back button color
      ),
      body: FutureBuilder<List<Debt>>(
        future: _debtsFuture,
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
                'No debts found.',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            );
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
                    margin: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16), // Card margin
                    color: const Color(0xFF29236A), // Card background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        debt.customerName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '\$${debt.amountDue.toStringAsFixed(2)}',
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
    );
  }

  void _showDeleteConfirmationDialog(String debtID) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF29236A), // Dialog background color
        title: Text(
          'Delete Debt',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this debt?',
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
              await _deleteDebt(debtID);
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
