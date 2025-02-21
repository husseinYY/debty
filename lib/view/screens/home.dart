import 'dart:math';

import 'package:Debty/model/transaction.dart';
import 'package:Debty/view/screens/pos.dart';
import 'package:Debty/view/screens/transaction_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/debt.dart';
import '../../model/product.dart';
import '../../model/shop.dart';
import 'add_shop.dart';
import 'edit_shop.dart';
import 'shop_details.dart';
import 'user_profile.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  List<Shop> shops = [];
  int currentShopIndex = 0;
  bool isLoading = true;
  final Map<String, Map<String, double>> _shopValuesCache = {};

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  // Function to generate a random color
  Color _getRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1,
    );
  }

  String _getUserInitials() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final names = user.displayName!.split(' ');
      if (names.length > 1) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      }
      return names[0][0].toUpperCase();
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      // Use the first letter of the email if displayName is not available
      return user.email![0].toUpperCase();
    }
    return 'U'; // Default initial if no display name or email
  }

  void _showDeleteConfirmationDialog(BuildContext context, Shop shop) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF29236A),
          title: Text(
            'Delete Shop',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete ${shop.name}?',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Delete the shop from Firestore
                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('shops')
                    .doc(shop.id)
                    .delete();
                Navigator.pop(context); // Close the dialog
                _fetchShops(); // Refresh the shop list
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, double>> _calculateShopValues(String shopId) async {
    // Return cached values if available
    if (_shopValuesCache.containsKey(shopId)) {
      return _shopValuesCache[shopId]!;
    }

    // Calculate total revenue
    final transactionsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('shops')
        .doc(shopId)
        .collection('transactions')
        .get();

    double totalRevenue = 0.0;
    for (var doc in transactionsSnapshot.docs) {
      final transaction = doc.data();
      totalRevenue += transaction['totalPrice'] ?? 0.0;
    }

    // Calculate total products value
    final categoriesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('shops')
        .doc(shopId)
        .collection('categories')
        .get();

    double totalProductsValue = 0.0;
    for (var categoryDoc in categoriesSnapshot.docs) {
      final productsSnapshot =
          await categoryDoc.reference.collection('products').get();
      for (var productDoc in productsSnapshot.docs) {
        final product = Product.fromJson(productDoc.data());
        totalProductsValue += product.price;
      }
    }

    // Calculate total dues amount
    final debtsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('shops')
        .doc(shopId)
        .collection('debts')
        .get();

    double totalDuesAmount = 0.0;
    for (var doc in debtsSnapshot.docs) {
      final debt = Debt.fromJson(doc.data());
      totalDuesAmount += debt.amountDue;
    }

    // Cache the calculated values
    final values = {
      'totalRevenue': totalRevenue,
      'totalProductsValue': totalProductsValue,
      'totalDuesAmount': totalDuesAmount,
    };
    _shopValuesCache[shopId] = values;

    return values;
  }

  void _clearShopValuesCache() {
    _shopValuesCache.clear();
  }

  Future<void> _fetchShops() async {
    setState(() => isLoading = true);
    _clearShopValuesCache(); // Clear cache before fetching new data

    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('shops')
        .get();
    final fetchedShops = querySnapshot.docs.map((doc) {
      return Shop(
        id: doc.id,
        name: doc['name'],
        address: doc['address'],
        type: doc["type"],
      );
    }).toList();

    // Ensure there's always an extra card for "Add a Shop"
    fetchedShops.add(Shop(
      id: "add_shop",
      name: "Add a Shop",
      address: "",
      type: "",
    ));

    setState(() {
      shops = fetchedShops;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1B42),
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF29236A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getRandomColor(),
                shape: BoxShape.circle,
              ),
              width: 40,
              height: 40,
              child: Center(
                child: Text(
                  _getUserInitials(),
                  style: GoogleFonts.poppins(
                    color: Colors.white, // Ensure contrast
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : shops.length <= 1
              ? GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const AddShop())),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF29236A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 40),
                          Text("Add Shop",
                              style: GoogleFonts.poppins(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 50),
                    _buildShopSwiper(),
                    const SizedBox(height: 20),
                    _buildTransactionSection(),
                  ],
                ),
    );
  }

  Widget _buildShopSwiper() {
    return SizedBox(
      height: 300,
      child: CardSwiper(
        cardsCount: shops.length,
        onSwipe: (previousIndex, currentIndex, direction) {
          setState(() {
            currentShopIndex = currentIndex!;
          });
          return true;
        },
        cardBuilder: (context, index, next, prev) {
          return _buildShopsCard(shops[index]);
        },
      ),
    );
  }

  Widget _buildShopsCard(Shop shop) {
    return FutureBuilder<Map<String, double>>(
      future: shop.id == "add_shop"
          ? Future.value({})
          : _calculateShopValues(shop.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            shop.id != "add_shop") {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError && shop.id != "add_shop") {
          return Center(
            child: Text(
              "Error calculating shop values",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          );
        }

        final totalRevenue = snapshot.data?['totalRevenue'] ?? 0.0;
        final totalProductsValue = snapshot.data?['totalProductsValue'] ?? 0.0;
        final totalDuesAmount = snapshot.data?['totalDuesAmount'] ?? 0.0;

        return GestureDetector(
          onTap: () {
            if (shop.id == "add_shop") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddShop(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShopDetails(shop: shop),
                ),
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF5B3E9A), Color(0xFF3377FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: shop.id == "add_shop"
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 50),
                      const SizedBox(height: 10),
                      Text("Add a Shop",
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 18)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row with Shop Name & Icon
                      Row(
                        children: [
                          const Icon(Icons.store,
                              color: Colors.white, size: 30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              shop.name,
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz,
                                color: Colors.white),
                            onSelected: (value) {
                              if (value == 'edit') {
                                // Navigate to Edit Shop page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditShop(shop: shop),
                                  ),
                                );
                              } else if (value == 'delete') {
                                // Show delete confirmation dialog
                                _showDeleteConfirmationDialog(context, shop);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('Edit Shop'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Delete Shop'),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Total Assets Text
                      Text("Revenue (USD)",
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 14)),

                      const SizedBox(height: 5),

                      // Total Revenue Amount
                      Text(
                          "\$${totalRevenue.toStringAsFixed(2)}", // Dynamic revenue
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold)),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Products Value",
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                    "\$${totalProductsValue.toStringAsFixed(2)}", // Dynamic products value
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Dues Amount",
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                    "\$${totalDuesAmount.toStringAsFixed(2)}", // Dynamic dues amount
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionSection() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Transactions",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(width: 10),
                shops.isNotEmpty && shops[currentShopIndex].id != "add_shop"
                    ? GestureDetector(
                        onTap: () {
                          final route = MaterialPageRoute(
                            builder: (context) =>
                                POS(shop: shops[currentShopIndex]),
                          );
                          Navigator.push(context, route);
                        },
                        child: const Icon(Icons.add, color: Colors.white),
                      )
                    : Container(),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('shops')
                    .doc(shops[currentShopIndex].id)
                    .collection('transactions')
                    .orderBy('timestamp', descending: true) // Sort by timestamp
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error fetching transactions",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No transactions found",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    );
                  }

                  final transactions = snapshot.data!.docs;

                  return ListView(
                    children: transactions.map((doc) {
                      final transaction = doc.data() as Map<String, dynamic>;
                      final customerName =
                          transaction['customer']['customerName'];
                      final totalPrice = transaction['totalPrice'];
                      final timestamp =
                          DateTime.parse(transaction['timestamp']);
                      final formattedDate =
                          "${timestamp.day}/${timestamp.month}/${timestamp.year}";

                      return GestureDetector(
                        onTap: () {
                          // Open transaction details
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionDetails(
                                transaction:
                                    TransactionModel.fromJson(transaction),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF29236A),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.attach_money,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customerName,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "\$${totalPrice.toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
