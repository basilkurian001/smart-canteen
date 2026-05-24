class HomeScreenStateNotifier {
  static void Function(int)? onCartCountChanged;

  static void updateCartCount(int count) {
    if (onCartCountChanged != null) {
      onCartCountChanged!(count);
    }
  }
}
