import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_canteen/models/food.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<List<Food>> fetchFoods() async {
  final baseUrl = dotenv.get('API_URL');
  final uri = Uri.parse("$baseUrl/food");

  final response = await http.get(uri);

  if (response.statusCode != 200) {
    throw Exception("Failed to load food");
  }

  final data = jsonDecode(response.body);
  final List list = data["foods"];

  return list.map((e) => Food.fromJson(e)).toList();
}
