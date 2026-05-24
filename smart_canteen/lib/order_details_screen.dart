import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

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
      appBar: AppBar(title: const Text("Order Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            /* ===== ORDER ID ===== */
            Text(
              _formatOrderId(order['id']),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Chip(
              label: Text(order['status']),
              backgroundColor:
                  _statusColor(order['status'])
                      .withOpacity(0.15),
              labelStyle: TextStyle(
                color:
                    _statusColor(order['status']),
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),
            Text("Placed on: ${_formatDate(order['created_at'])}"),

            const Divider(height: 32),

            /* ===== ITEMS ===== */
            const Text(
              "Items",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: order['items'].length,
                itemBuilder: (_, i) {
                  final item = order['items'][i];
                  return ListTile(
                    title: Text(item['name'] ?? "Food"),
                    subtitle:
                        Text("Qty: ${item['quantity']}"),
                    trailing: Text(
                      "₹${item['price']}",
                      style: const TextStyle(
                          fontWeight:
                              FontWeight.bold),
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            /* ===== TOTAL ===== */
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Paid",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold),
                ),
                Text(
                  "₹${order['total_amount']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFFFF7643),
                  ),
                ),
              ],
            ),

            if ((order['points_used'] ?? 0) > 0)
              Text(
                "Points used: ${order['points_used']}",
                style:
                    const TextStyle(color: Colors.red),
              ),

            if ((order['points_earned'] ?? 0) > 0)
              Text(
                "Points earned: ${order['points_earned']}",
                style: const TextStyle(
                    color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
