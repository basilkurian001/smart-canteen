import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CartService {
  static const _baseUrl = "http://10.125.22.31:3000";

  static Future<void> addToCart(int foodId, {int quantity = 1}) async {
    final token = await AuthService().getToken();

    await http.post(
      Uri.parse("$_baseUrl/cart"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "foodId": foodId,
        "quantity": quantity,
      }),
    );
  }

  static Future<int> getCartCount() async {
    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse("$_baseUrl/cart/count"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    return data['count'] ?? 0;
  }

  static Future<List<dynamic>> getCartItems() async {
    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse("$_baseUrl/cart"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    return data['items'] ?? [];
  }

  static Future<void> updateQuantity(int foodId, int quantity) async {
    final token = await AuthService().getToken();

    await http.put(
      Uri.parse("$_baseUrl/cart"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "foodId": foodId,
        "quantity": quantity,
      }),
    );
  }

  static Future<void> removeItem(int foodId) async {
    final token = await AuthService().getToken();

    await http.delete(
      Uri.parse("$_baseUrl/cart/$foodId"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

}
