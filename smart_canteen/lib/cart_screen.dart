import 'package:flutter/material.dart';
import 'package:smart_canteen/cart_service.dart';
import 'package:smart_canteen/cart_notifier.dart';
import 'package:smart_canteen/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final items = await CartService.getCartItems();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  /// TOTAL ONLY FOR AVAILABLE ITEMS
  double get _totalAmount {
    double total = 0;
    for (final item in _items) {
      final bool unavailable =
          item['available'] == 0 || item['available'] == null;

      if (!unavailable) {
        total +=
            ((item['price'] as num).toDouble() * item['quantity']);
      }
    }
    return total;
  }

  bool get _hasUnavailableItems {
    return _items.any(
      (item) => item['available'] == 0 || item['available'] == null,
    );
  }

  Future<void> _updateQuantity(int foodId, int newQty) async {
    await CartService.updateQuantity(foodId, newQty);
    await _loadCart();

    final count = await CartService.getCartCount();
    HomeScreenStateNotifier.updateCartCount(count);
  }

  Future<void> _removeItem(int foodId) async {
    await CartService.removeItem(foodId);
    await _loadCart();

    final count = await CartService.getCartCount();
    HomeScreenStateNotifier.updateCartCount(count);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text("Your cart is empty", style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final item = _items[i];
              final bool unavailable =
                  item['available'] == 0 || item['available'] == null;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      unavailable
                          ? const Icon(Icons.block,
                              size: 60, color: Colors.grey)
                          : Image.network(
                              "http://10.125.22.31:3000/food_images/${item['image']}",
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              unavailable
                                  ? "Item unavailable"
                                  : item['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: unavailable
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),

                            unavailable
                                ? const Text(
                                    "This item is no longer available",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : Text("₹${item['price']}"),

                            const SizedBox(height: 8),

                            if (!unavailable)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline),
                                    onPressed: item['quantity'] > 1
                                        ? () => _updateQuantity(
                                              item['food_id'],
                                              item['quantity'] - 1,
                                            )
                                        : null,
                                  ),
                                  Text(
                                    item['quantity'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.add_circle_outline),
                                    onPressed: () => _updateQuantity(
                                      item['food_id'],
                                      item['quantity'] + 1,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      Column(
                        children: [
                          if (!unavailable)
                            Text(
                              "₹${((item['price'] as num).toDouble() * item['quantity']).toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _removeItem(item['food_id']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey)),
          ),
          child: Column(
            children: [
              if (_hasUnavailableItems)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Remove unavailable items to continue",
                    style: TextStyle(color: Colors.red),
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "₹${_totalAmount.toStringAsFixed(2)}",
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
                    backgroundColor: _hasUnavailableItems
                        ? Colors.grey
                        : const Color(0xFFFF7643),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _hasUnavailableItems
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Proceeding to checkout")),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(
                                mode: CheckoutMode.cart,
                              ),
                            ),
                          );
                        },
                  child: const Text(
                    "Proceed to Buy",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
