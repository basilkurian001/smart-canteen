import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_canteen/main.dart';
import 'auth_service.dart';

class CartService {
  static Future<void> addToCart(int foodId, {int quantity = 1}) async {
    final token = await AuthService().getToken();

    await http.post(
      Uri.parse("$API_URL/cart"),
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
      Uri.parse("$API_URL/cart/count"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    return data['count'] ?? 0;
  }

  static Future<List<dynamic>> getCartItems() async {
    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse("$API_URL/cart"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    return data['items'] ?? [];
  }

  static Future<void> updateQuantity(int foodId, int quantity) async {
    final token = await AuthService().getToken();

    await http.put(
      Uri.parse("$API_URL/cart"),
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
      Uri.parse("$API_URL/cart/$foodId"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

}
