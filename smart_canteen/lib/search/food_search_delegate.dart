import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_canteen/food_details_screen.dart';
import '../models/food.dart';

class FoodSearchDelegate extends SearchDelegate {
  List<Food> _allFoods = [];
  bool _loaded = false;

  Future<void> _loadFoods() async {
    if (_loaded) return;

    final res = await http.get(
      Uri.parse("http://10.125.22.31:3000/food"),
    );

    final data = jsonDecode(res.body);
    _allFoods =
        (data['foods'] as List).map((e) => Food.fromJson(e)).toList();

    _loaded = true;
  }

  @override
  String get searchFieldLabel => "Search food";

  @override
  TextStyle get searchFieldStyle =>
      const TextStyle(fontSize: 16);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder(
      future: _loadFoods(),
      builder: (context, snapshot) {
        if (!_loaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = _allFoods.where((food) {
          return food.name
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();

        if (results.isEmpty) {
          return const Center(child: Text("No food found"));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final food = results[index];
            return ListTile(
              leading: food.image != null
                  ? Image.network(
                      "http://10.125.22.31:3000/food_images/${food.image}",
                      width: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.fastfood),
              title: Text(food.name),
              subtitle: Text("₹${food.price}"),
              onTap: () {
                close(context, null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodDetailsScreen(food: food),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
