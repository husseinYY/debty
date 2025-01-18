import '../../view/screens/customers.dart';
import '../../view/screens/debts.dart';
import '../../view/screens/products.dart';
import 'package:flutter/material.dart';

import '../../model/shop.dart';
import 'categories.dart';
import 'pos.dart';

class ShopDetails extends StatelessWidget {
  final Shop shop;

  const ShopDetails({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop Details')),
      body: ListView(
        children: [
          _buildSectionCard(context, 'Categories', () {
            // Navigate to categories page
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Categories(shop: shop)));
          }),
          _buildSectionCard(context, 'Products', () {
            // Navigate to products page
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Products(
                          shop: shop,
                        )));
          }),
          _buildSectionCard(context, 'Customers', () {
            // Navigate to customers page
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => Customers(shop: shop)));
          }),
          _buildSectionCard(context, 'Debts', () {
            // Navigate to debts page
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => Debts(shop: shop)));
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => POS(shop: shop))),
        tooltip: 'POS page',
        child: const Icon(Icons.point_of_sale),
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context, String title, VoidCallback onTap) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
