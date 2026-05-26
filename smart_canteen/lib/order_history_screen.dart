import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:smart_canteen/auth_service.dart';
import 'order_details_screen.dart';

final API_URL = dotenv.get('API_URL');

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _loading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse("$API_URL/orders"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);

    setState(() {
      _orders = data['orders'] ?? [];
      _loading = false;
    });
  }

  String _formatOrderId(int id) =>
      "SC-${id.toString().padLeft(5, '0')}";

  String _formatDate(int? ts) {
    if (ts == null) return "Date unavailable";
    final d =
        DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  Color _statusColor(String status) {
    switch (status) {
      case "DELIVERED":
        return Colors.green;
      case "READY":
        return Colors.blue;
      case "PREPARING":
        return Colors.orange;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order History")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text("No orders yet"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _orders.length,
                  itemBuilder: (_, i) {
                    final order = _orders[i];

                    return Card(
                      child: ListTile(
                        title: Text(
                          "Order ID: ${_formatOrderId(order['id'])}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              "₹${order['total_amount']}",
                              style: const TextStyle(
                                color: Color(0xFFFF7643),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDate(order['created_at']),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(order['status']),
                          backgroundColor: _statusColor(
                                  order['status'])
                              .withOpacity(0.15),
                          labelStyle: TextStyle(
                            color: _statusColor(
                                order['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailsScreen(
                                order: order,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
