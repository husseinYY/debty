import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/product.dart';
import '../../model/transaction.dart'; // Import your TransactionModel

class TransactionDetails extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetails({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1B42),
      appBar: AppBar(
        backgroundColor: const Color(0xFF29236A),
        elevation: 0,
        title: Text(
          "Transaction Details",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Section
            _buildSectionTitle("Customer"),
            _buildDetailCard(
              children: [
                _buildDetailRow("Name", transaction.customer.name),
                _buildDetailRow("Phone", transaction.customer.phone),
              ],
            ),

            const SizedBox(height: 20),

            // Products Section
            _buildSectionTitle("Products Purchased"),
            _buildDetailCard(
              children: transaction.products.map((product) {
                return _buildDetailRow(
                  product.name,
                  "\$${product.price.toStringAsFixed(2)} x ${_getProductQuantity(transaction, product)}",
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Payment Section
            _buildSectionTitle("Payment Details"),
            _buildDetailCard(
              children: [
                _buildDetailRow("Total Price",
                    "\$${transaction.totalPrice.toStringAsFixed(2)}"),
                _buildDetailRow("Amount Paid",
                    "\$${transaction.amountPaid.toStringAsFixed(2)}"),
                _buildDetailRow(
                  "Amount Due",
                  "\$${transaction.amountDue.toStringAsFixed(2)}",
                  isAmountDue: true,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Timestamp Section
            _buildSectionTitle("Transaction Date"),
            _buildDetailCard(
              children: [
                _buildDetailRow(
                  "Date",
                  "${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year}",
                ),
                _buildDetailRow(
                  "Time",
                  "${transaction.timestamp.hour}:${transaction.timestamp.minute}",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get the quantity of a product in the transaction
  int _getProductQuantity(TransactionModel transaction, Product product) {
    final productMap =
        transaction.products.where((p) => p.id == product.id).toList();
    return productMap.length;
  }

  // Section Title Widget
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Detail Card Widget
  Widget _buildDetailCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF29236A),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Detail Row Widget
  Widget _buildDetailRow(String label, String value,
      {bool isAmountDue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: isAmountDue ? Colors.red : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
