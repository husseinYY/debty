import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/customer.dart';
import '../../model/product.dart';
import '../../model/debt.dart';

import '../../model/category.dart';
import '../../model/shop.dart';

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

  void _handlePayment() {
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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS - Purchase'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<List<Category>>(
                future: _fetchCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                        child: Text('Error fetching categories'));
                  }

                  final categories = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Category',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCategory,
                          hint: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Choose a category',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent)),
                          ),
                          items: categories
                              .map((category) => DropdownMenuItem(
                                    value: category.categoryID,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(category.categoryName,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent)),
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
              if (availableProducts.isNotEmpty) ...[
                const Text(
                  'Select Product',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  child: DropdownButton<Product>(
                    isExpanded: true,
                    value: selectedProduct,
                    hint: const Text('Choose a product',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent)),
                    items: availableProducts
                        .map((product) => DropdownMenuItem(
                              value: product,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.store,
                                      color: Colors.pink,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(product.name,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent)),
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
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            quantity = int.tryParse(value) ??
                                1; // Update quantity on input change
                          },
                          onSubmitted: (value) {
                            _addToCart(selectedProduct!,
                                quantity); // Use updated quantity
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          _addToCart(selectedProduct!,
                              quantity); // Use the same quantity variable
                        },
                        child: const Text('Add to Cart'),
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 20),
              const Text(
                'Cart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (cart.isNotEmpty) ...[
                ...cart.entries.map((entry) => ListTile(
                      title: Text('${entry.key.name} x${entry.value}'),
                      subtitle: Text(
                          '\$${(entry.key.price * entry.value).toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeFromCart(entry.key),
                      ),
                    )),
                Text(
                  'Total Price: \$${totalPrice.toString()}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FutureBuilder<List<Customer>>(
                future: _fetchCustomers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                        child: Text('Error fetching customers'));
                  }

                  final customers = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Customer',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: DropdownButton<Customer>(
                          isExpanded: true,
                          value: selectedCustomer,
                          hint: const Text('Choose a customer'),
                          items: customers
                              .map((customer) => DropdownMenuItem(
                                    value: customer,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.supervised_user_circle,
                                          color: Colors.pink,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(customer.name),
                                      ],
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
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    amountPaid = double.tryParse(value) ?? 0.0;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Amount Paid',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: cart.isEmpty || selectedCustomer == null
                        ? null
                        : _handlePayment, // Disable if cart is empty
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Complete Payment'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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
