import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class FavouritesService {
  static const _baseUrl = "http://10.125.22.31:3000";

  static Future<bool> isFavourite(int foodId) async {
    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse("$_baseUrl/favourites/check/$foodId"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    return data['isFavourite'] == true;
  }

  static Future<void> add(int foodId) async {
    final token = await AuthService().getToken();

    await http.post(
      Uri.parse("$_baseUrl/favourites/$foodId"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  static Future<void> remove(int foodId) async {
    final token = await AuthService().getToken();

    await http.delete(
      Uri.parse("$_baseUrl/favourites/$foodId"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  static Future<List<dynamic>> getAll() async {
    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse("$_baseUrl/favourites"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    return data['items'] ?? [];
  }
}
