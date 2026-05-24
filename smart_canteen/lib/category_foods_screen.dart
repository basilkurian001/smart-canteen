import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/food.dart';
import 'food_details_screen.dart';

class CategoryFoodsScreen extends StatefulWidget {
  final String category;

  const CategoryFoodsScreen({super.key, required this.category});

  @override
  State<CategoryFoodsScreen> createState() => _CategoryFoodsScreenState();
}

class _CategoryFoodsScreenState extends State<CategoryFoodsScreen> {
  List<Food> _foods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategoryFoods();
  }

  Future<void> _fetchCategoryFoods() async {
    try {
      final url = widget.category.toLowerCase() == 'vegetarian'
          ? "http://10.125.22.31:3000/food/vegetarian"
          : "http://10.125.22.31:3000/food/category/${widget.category}";

      final res = await http.get(Uri.parse(url));

      final data = jsonDecode(res.body);

      setState(() {
        _foods =
            (data['foods'] as List).map((e) => Food.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint("Category fetch error: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _foods.isEmpty
              ? const Center(child: Text("No food available"))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _foods.length,
                  itemBuilder: (context, index) {
                    final food = _foods[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FoodDetailsScreen(food: food),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: food.image != null
                                  ? Image.network(
                                      "http://10.125.22.31:3000/food_images/${food.image}",
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Container(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₹${food.price}",
                                    style: const TextStyle(
                                      color: Color(0xFFFF7643),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
