import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_canteen/auth_service.dart';
import 'package:smart_canteen/cart_notifier.dart';
import 'package:smart_canteen/cart_service.dart';
import 'package:smart_canteen/main.dart';
import 'models/food.dart';

enum CheckoutMode { cart, buyNow }

class CheckoutScreen extends StatefulWidget {
  final CheckoutMode mode;
  final Food? food;

  const CheckoutScreen({
    super.key,
    required this.mode,
    this.food,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  int _availablePoints = 0;
  int _pointsToUse = 0;
  double _rupeePerPoint = 1;
  double _maxRedeemPercent = 50; // ✅ dynamic

  @override
  void initState() {
    super.initState();
    _loadPointsPreview();
    widget.mode == CheckoutMode.cart
        ? _loadCartItems()
        : _loadBuyNowItem();
  }

  /* =============================
     LOAD POINT RULES FROM BACKEND
  ============================== */
  Future<void> _loadPointsPreview() async {
    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse("$API_URL/orders/preview"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);

    if (data['success'] == true) {
      setState(() {
        _availablePoints = data['availablePoints'] ?? 0;
        _rupeePerPoint =
            (data['rupeePerPoint'] as num?)?.toDouble() ?? 1;
        _maxRedeemPercent =
            (data['maxRedeemPercent'] as num?)?.toDouble() ?? 50;
      });
    }
  }

  /* =============================
     LOAD CART ITEMS
  ============================== */
  Future<void> _loadCartItems() async {
    final items = await CartService.getCartItems();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  /* =============================
     LOAD BUY NOW ITEM
  ============================== */
  void _loadBuyNowItem() {
    _items = [
      {
        "food_id": widget.food!.id,
        "name": widget.food!.name,
        "price": widget.food!.price,
        "image": widget.food!.image,
        "quantity": 1,
      }
    ];
    _loading = false;
  }

  /* =============================
     SUBTOTAL
  ============================== */
  double get _subtotal {
    return _items.fold(
      0,
      (sum, item) =>
          sum + (item['price'] as num).toDouble() * item['quantity'],
    );
  }

  /* =============================
     ESTIMATED TOTAL (UI ONLY)
  ============================== */
  double get _estimatedTotal {
    return (_subtotal - (_pointsToUse * _rupeePerPoint))
        .clamp(0, _subtotal);
  }

  /* =============================
     PLACE ORDER
  ============================== */
  Future<void> _placeOrder() async {
    final token = await AuthService().getToken();

    final uri = widget.mode == CheckoutMode.cart
        ? "$API_URL/orders"
        : "$API_URL/orders/buy-now";

    final body = widget.mode == CheckoutMode.cart
        ? { "usePoints": _pointsToUse }
        : {
            "foodId": widget.food!.id,
            "quantity": _items.first['quantity'],
            "usePoints": _pointsToUse,
          };

    final res = await http.post(
      Uri.parse(uri),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);

    if (data['success'] == true) {
      if (widget.mode == CheckoutMode.cart) {
        HomeScreenStateNotifier.updateCartCount(0);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Order placed! You earned ${data['pointsEarned'] ?? 0} points 🎉",
          ),
        ),
      );

      Navigator.popUntil(context, (r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Order failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ..._items.map((item) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: Image.network(
                        "$API_URL/food_images/${item['image']}",
                        width: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(item['name']),
                      subtitle: Text("₹${item['price']}"),
                    ),
                  );
                }),

                /* =============================
                   POINTS SECTION
                ============================== */
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Available Points: $_availablePoints",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText:
                              "Redeem Points (Max ${_maxRedeemPercent.toInt()}%)",
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          final entered = int.tryParse(v) ?? 0;

                          final maxRedeemBySubtotal =
                              (_subtotal * (_maxRedeemPercent / 100)).floor();

                          setState(() {
                            _pointsToUse = entered.clamp(
                              0,
                              min(_availablePoints, maxRedeemBySubtotal),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /* =============================
             TOTAL + PLACE ORDER
          ============================== */
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Estimated Total",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "₹${_estimatedTotal.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF7643),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7643),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _placeOrder,
                    child: const Text(
                      "Place Order",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
