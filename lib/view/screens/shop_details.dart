import '../../view/screens/customers.dart';
import '../../view/screens/debts.dart';
import '../../view/screens/products.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/shop.dart';
import 'categories.dart';
import 'pos.dart';

class ShopDetails extends StatelessWidget {
  final Shop shop;

  const ShopDetails({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1B42), // Background color
      appBar: AppBar(
        title: Text(
          'Shop Details',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF29236A), // AppBar background color
        iconTheme:
            const IconThemeData(color: Colors.white), // Back button color
      ),
      body: ListView(
        children: [
          _buildSectionCard(context, 'Categories', () {
            // Navigate to categories page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Categories(shop: shop),
              ),
            );
          }),
          _buildSectionCard(context, 'Products', () {
            // Navigate to products page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Products(shop: shop),
              ),
            );
          }),
          _buildSectionCard(context, 'Customers', () {
            // Navigate to customers page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Customers(shop: shop),
              ),
            );
          }),
          _buildSectionCard(context, 'Debts', () {
            // Navigate to debts page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Debts(shop: shop),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => POS(shop: shop)),
        ),
        tooltip: 'POS page',
        backgroundColor: const Color(0xFF5B3E9A), // FAB background color
        child: const Icon(
          Icons.point_of_sale,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context, String title, VoidCallback onTap) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF29236A), // Card background color
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
        ),
        onTap: onTap,
      ),
    );
  }
}
