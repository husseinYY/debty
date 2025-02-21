import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/customer.dart';
import '../../model/product.dart';
import '../../model/debt.dart';
import '../../model/category.dart';
import '../../model/shop.dart';
import '../../model/transaction.dart';

class POS extends StatefulWidget {
  final Shop shop;
  const POS({super.key, required this.shop});

  @override
  POSState createState() => POSState();
}

class POSState extends State<POS> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  String? selectedCategory;
  List<Product> availableProducts = [];
  Product? selectedProduct;
  Customer? selectedCustomer;
  double totalPrice = 0.0;
  double amountPaid = 0.0;
  int quantity = 1;

  Map<Product, int> cart = {};

  Future<List<Category>> _fetchCategories() async {
    final categoriesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('shops')
        .doc(widget.shop.id)
        .collection('categories')
        .get();

    final List<Category> categories = [];
    for (var doc in categoriesSnapshot.docs) {
      categories
          .add(Category(categoryID: doc.id, categoryName: doc.data()['name']));
    }
    return categories;
  }

  Future<void> _fetchProductsByCategory() async {
    if (selectedCategory == null) return;

    final productsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('shops')
        .doc(widget.shop.id)
        .collection('categories')
        .doc(selectedCategory)
        .collection('products')
        .get();

    setState(() {
      availableProducts = productsSnapshot.docs
          .map((doc) => Product.fromJson(doc.data()))
          .toList();
      selectedProduct = null;
    });
  }

  void _addToCart(Product product, int quantity) {
    if (quantity > 0) {
      setState(() {
        if (cart.containsKey(product)) {
          cart[product] = cart[product]! + quantity;
        } else {
          cart[product] = quantity;
        }
        _calculateTotalPrice();
      });
    }
  }

  void _calculateTotalPrice() {
    totalPrice = cart.entries
        .map((entry) => entry.key.price * entry.value)
        .fold(0.0, (sum, element) => sum + element);
  }

  void _removeFromCart(Product product) {
    setState(() {
      cart.remove(product);
      _calculateTotalPrice();
    });
  }

  Future<void> _addTransaction() async {
    final transactionRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('shops')
        .doc(widget.shop.id)
        .collection('transactions')
        .doc();

    final transaction = TransactionModel(
      id: transactionRef.id,
      shopId: widget.shop.id,
      customer: selectedCustomer!,
      products: cart.keys.toList(), // List of Product objects
      totalPrice: totalPrice,
      amountPaid: amountPaid,
      amountDue: totalPrice - amountPaid,
      timestamp: DateTime.now(),
    );

    await transactionRef.set(transaction.toJson());
  }

  Future<void> _addDebt() async {
    final debtQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('shops')
        .doc(widget.shop.id)
        .collection('debts')
        .where('customerId', isEqualTo: selectedCustomer!.id)
        .get();

    if (debtQuery.docs.isNotEmpty) {
      // If debt already exists, update the amountDue by adding the new debt
      final debtRef = debtQuery.docs.first.reference;
      final existingDebt = Debt.fromJson(debtQuery.docs.first.data());
      final updatedAmountDue =
          existingDebt.amountDue + (totalPrice - amountPaid);

      await debtRef.update({'amountDue': updatedAmountDue});
    } else {
      // If no debt exists, create a new one
      final debtRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('shops')
          .doc(widget.shop.id)
          .collection('debts')
          .doc();

      final debt = Debt(
        customerId: selectedCustomer!.id,
        customerName: selectedCustomer!.name,
        amountDue: totalPrice - amountPaid,
      );

      await debtRef.set(debt.toJson());
    }
  }

  void _handlePayment() async {
    await _addTransaction();

    if (amountPaid > totalPrice) {
      final change = amountPaid - totalPrice;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Change to return: \$${change.toString()}')),
      );
      Navigator.pop(context);
    } else if (amountPaid == totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful!')),
      );
      Navigator.pop(context);
    } else {
      _addDebt();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debt created!')),
      );
      Phoenix.rebirth(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1B42), // Background color
      appBar: AppBar(
        title: Text(
          'POS - Purchase',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF29236A), // AppBar background color
        iconTheme:
            const IconThemeData(color: Colors.white), // Back button color
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Dropdown
              FutureBuilder<List<Category>>(
                future: _fetchCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text(
                        'Error fetching categories',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    );
                  }

                  final categories = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Category',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF29236A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCategory,
                          hint: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Choose a category',
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                          ),
                          dropdownColor: const Color(0xFF29236A),
                          style: GoogleFonts.poppins(color: Colors.white),
                          items: categories
                              .map((category) => DropdownMenuItem(
                                    value: category.categoryID,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        category.categoryName,
                                        style: GoogleFonts.poppins(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value;
                            });
                            _fetchProductsByCategory();
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Product Dropdown
              if (availableProducts.isNotEmpty) ...[
                Text(
                  'Select Product',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF29236A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<Product>(
                    isExpanded: true,
                    value: selectedProduct,
                    hint: Text(
                      'Choose a product',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                    dropdownColor: const Color(0xFF29236A),
                    style: GoogleFonts.poppins(color: Colors.white),
                    items: availableProducts
                        .map((product) => DropdownMenuItem(
                              value: product,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.store,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      product.name,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (product) {
                      setState(() {
                        selectedProduct = product;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                if (selectedProduct != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              TextEditingController(text: quantity.toString()),
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            labelStyle:
                                GoogleFonts.poppins(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.white70),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            quantity = int.tryParse(value) ?? 1;
                          },
                          onSubmitted: (value) {
                            _addToCart(selectedProduct!, quantity);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          _addToCart(selectedProduct!, quantity);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B3E9A),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Add to Cart',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 20),

              // Cart Section
              Text(
                'Cart',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (cart.isNotEmpty) ...[
                ...cart.entries.map((entry) => ListTile(
                      title: Text(
                        '${entry.key.name} x${entry.value}',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      subtitle: Text(
                        '\$${(entry.key.price * entry.value).toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeFromCart(entry.key),
                      ),
                    )),
                Text(
                  'Total Price: \$${totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: Colors.green[800],
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Customer Dropdown
              FutureBuilder<List<Customer>>(
                future: _fetchCustomers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text(
                        'Error fetching customers',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    );
                  }

                  final customers = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Customer',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF29236A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<Customer>(
                          isExpanded: true,
                          value: selectedCustomer,
                          hint: Text(
                            'Choose a customer',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                          dropdownColor: const Color(0xFF29236A),
                          style: GoogleFonts.poppins(color: Colors.white),
                          items: customers
                              .map((customer) => DropdownMenuItem(
                                    value: customer,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            customer.name,
                                            style: GoogleFonts.poppins(
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCustomer = value;
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Amount Paid Field
              TextField(
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount Paid',
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
                onChanged: (value) {
                  setState(() {
                    amountPaid = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: cart.isEmpty || selectedCustomer == null
                        ? null
                        : _handlePayment,
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                    label: Text(
                      'Complete Payment',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B3E9A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.cancel_outlined, color: Colors.white),
                    label: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B3E9A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Customer>> _fetchCustomers() async {
    final customerSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('shops')
        .doc(widget.shop.id)
        .collection('customers')
        .get();

    final List<Customer> customers = [];
    for (var doc in customerSnapshot.docs) {
      customers.add(
        Customer(
          id: doc.id,
          name: doc.data()['customerName'],
          phone: doc.data()['phone'],
        ),
      );
    }
    return customers;
  }
}
