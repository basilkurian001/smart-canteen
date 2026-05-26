import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_canteen/main.dart';
import 'auth_service.dart';

class FavouritesService {

  static Future<bool> isFavourite(int foodId) async {
    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse("$API_URL/favourites/check/$foodId"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    return data['isFavourite'] == true;
  }

  static Future<void> add(int foodId) async {
    final token = await AuthService().getToken();

    await http.post(
      Uri.parse("$API_URL/favourites/$foodId"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  static Future<void> remove(int foodId) async {
    final token = await AuthService().getToken();

    await http.delete(
      Uri.parse("$API_URL/favourites/$foodId"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  static Future<List<dynamic>> getAll() async {
    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse("$API_URL/favourites"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    return data['items'] ?? [];
  }
}
