import 'package:flutter/material.dart';
import 'package:smart_canteen/favourites_service.dart';
import 'package:smart_canteen/main.dart';
import 'food_details_screen.dart';
import 'models/food.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await FavouritesService.getAll();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _remove(int foodId) async {
    await FavouritesService.remove(foodId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return const Center(child: Text("No favourites yet"));
    }

    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final item = _items[i];
        final bool unavailable = item['is_available'] == 0 || item['is_available'] == false;

        return ListTile(
          leading: unavailable
              ? const Icon(Icons.block, color: Colors.grey)
              : Image.network(
                  "$API_URL/food_images/${item['image']}",
                  width: 50,
                  fit: BoxFit.cover,
                ),

          title: Text(
            unavailable ? "Item unavailable" : item['name'],
            style: TextStyle(
              color: unavailable ? Colors.grey : Colors.black,
              fontStyle:
                  unavailable ? FontStyle.italic : FontStyle.normal,
            ),
          ),

          subtitle: unavailable
              ? const Text("This item is no longer available")
              : Text("₹${item['price']}"),

          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _remove(item['food_id']),
          ),

          onTap: unavailable
              ? null
              : () {
                  final food = Food(
                    id: item['food_id'],
                    name: item['name'] ?? '',
                    price: (item['price'] as num).toDouble(),
                    image: item['image'] ?? '',
                    category: item['category'] ?? '',
                    isVeg:
                        item['isVeg'] == 1 || item['isVeg'] == true,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FoodDetailsScreen(food: food),
                    ),
                  );
                },
        );
      },
    );
  }
}
