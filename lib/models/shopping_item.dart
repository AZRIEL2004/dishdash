class ShoppingItem {
  final String id;
  final String name;
  final bool isBought;

  ShoppingItem({
    required this.id,
    required this.name,
    this.isBought = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isBought': isBought,
    };
  }

  factory ShoppingItem.fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingItem(
      id: id,
      name: data['name'] ?? '',
      isBought: data['isBought'] ?? false,
    );
  }
}
