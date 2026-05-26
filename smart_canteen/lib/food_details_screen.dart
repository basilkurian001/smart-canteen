import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:smart_canteen/cart_notifier.dart';
import 'package:smart_canteen/cart_service.dart';
import 'package:smart_canteen/checkout_screen.dart';
import 'package:smart_canteen/favourites_service.dart';
import 'models/food.dart';
import 'auth_service.dart';

final baseUrl = dotenv.get('API_URL');

class FoodDetailsScreen extends StatefulWidget {
  final Food food;

  const FoodDetailsScreen({super.key, required this.food});

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  final TextEditingController _reviewController = TextEditingController();

  int _selectedRating = 0;
  bool _loadingReviews = true;

  List<dynamic> _reviews = [];
  double _avgRating = 0.0;
  int _totalReviews = 0;
  int? _myUserId;

  bool _isFavourite = false;
  bool _loadingFavourite = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchReviews();
    _checkFavourite();
  }

  /* =============================
     LOAD CURRENT USER
  ============================== */
  Future<void> _loadUser() async {
    final me = await AuthService().me();
    setState(() {
      _myUserId = me['user']['id'];
    });
  }

  /* =============================
     CHECK FAVOURITE
  ============================== */
  Future<void> _checkFavourite() async {
    final fav = await FavouritesService.isFavourite(widget.food.id);
    setState(() {
      _isFavourite = fav;
      _loadingFavourite = false;
    });
  }

  /* =============================
     FETCH REVIEWS
  ============================== */
  Future<void> _fetchReviews() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/reviews/${widget.food.id}"),
      );

      final data = jsonDecode(res.body);

      setState(() {
        _reviews = data['reviews'] ?? [];
        _avgRating = double.tryParse(data['averageRating'].toString()) ?? 0.0;
        _totalReviews = data['totalReviews'] ?? 0;
        _loadingReviews = false;
      });
    } catch (_) {
      setState(() => _loadingReviews = false);
    }
  }

  /* =============================
     SUBMIT / UPDATE REVIEW
  ============================== */
  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating")),
      );
      return;
    }

    final token = await AuthService().getToken();

    await http.post(
      Uri.parse("$baseUrl/reviews/${widget.food.id}"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "rating": _selectedRating,
        "comment": _reviewController.text.trim(),
      }),
    );

    _reviewController.clear();
    _selectedRating = 0;
    _fetchReviews();
  }

  /* =============================
     DELETE REVIEW
  ============================== */
  Future<void> _deleteReview() async {
    final token = await AuthService().getToken();

    await http.delete(
      Uri.parse("$baseUrl/reviews/${widget.food.id}"),
      headers: {"Authorization": "Bearer $token"},
    );

    _fetchReviews();
  }

  /* =============================
     TOGGLE FAVOURITE
  ============================== */
  Future<void> _toggleFavourite() async {
    if (_isFavourite) {
      await FavouritesService.remove(widget.food.id);
    } else {
      await FavouritesService.add(widget.food.id);
    }

    setState(() {
      _isFavourite = !_isFavourite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;

    return Scaffold(
      appBar: AppBar(title: Text(food.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /* =============================
               FOOD IMAGE
            ============================== */
            AspectRatio(
              aspectRatio: 1,
              child: food.image != null
                  ? Image.network(
                      "$baseUrl/food_images/${food.image}",
                      fit: BoxFit.cover,
                    )
                  : Container(color: Colors.grey.shade300),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /* =============================
                     NAME + PRICE + FAVOURITE
                  ============================== */
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹${food.price}",
                            style: const TextStyle(
                              fontSize: 20,
                              color: Color(0xFFFF7643),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (!_loadingFavourite)
                        IconButton(
                          icon: Icon(
                            _isFavourite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavourite ? Colors.red : Colors.grey,
                            size: 28,
                          ),
                          onPressed: _toggleFavourite,
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /* =============================
                     AVG RATING
                  ============================== */
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text(
                        " $_avgRating ($_totalReviews reviews)",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /* =============================
                     DESCRIPTION
                  ============================== */
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(food.description ?? "No description available"),

                  const SizedBox(height: 24),

                  /* =============================
                     ADD TO CART / BUY NOW
                  ============================== */
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7643),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            await CartService.addToCart(food.id);

                            final count =
                                await CartService.getCartCount();
                            HomeScreenStateNotifier.updateCartCount(count);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Added to cart")),
                            );
                          },
                          child: const Text("Add to Cart"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(
                                  mode: CheckoutMode.buyNow,
                                  food: food,
                                ),
                              ),
                            );
                            },
                          child: const Text("Buy Now"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  /* =============================
                     USER REVIEWS
                  ============================== */
                  const Text(
                    "User Reviews",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  if (_loadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    const Text("No reviews yet. Be the first!")
                  else
                    ..._reviews.map(
                      (r) => Card(
                        child: ListTile(
                          title:
                              Text(r['name']?.toString() ?? "Anonymous"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(
                                  r['rating'] ?? 0,
                                  (_) => const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                              if ((r['comment'] ?? "")
                                  .toString()
                                  .isNotEmpty)
                                Text(r['comment'].toString()),
                            ],
                          ),
                          trailing: r['user_id'] == _myUserId
                              ? IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: _deleteReview,
                                )
                              : null,
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  /* =============================
                     ADD / UPDATE REVIEW
                  ============================== */
                  const Text(
                    "Your Rating",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),

                  StarRating(
                    rating: _selectedRating,
                    onRatingSelected: (r) {
                      setState(() => _selectedRating = r);
                    },
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _reviewController,
                    decoration: InputDecoration(
                      hintText: "Write a review (optional)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: _submitReview,
                    child: const Text("Submit Review"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =============================
   STAR RATING WIDGET
============================= */
class StarRating extends StatelessWidget {
  final int rating;
  final void Function(int) onRatingSelected;

  const StarRating({
    super.key,
    required this.rating,
    required this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () => onRatingSelected(index + 1),
        );
      }),
    );
  }
}
