import 'package:cloud_firestore/cloud_firestore.dart';

/// Shopping list item model
class ShoppingListItem {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final bool isChecked;
  final String? amazonLink;
  final String? walmartLink;
  final DateTime addedAt;

  ShoppingListItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.isChecked = false,
    this.amazonLink,
    this.walmartLink,
    required this.addedAt,
  });

  factory ShoppingListItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingListItem(
      id: doc.id,
      name: data['name'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      isChecked: data['isChecked'] ?? false,
      amazonLink: data['amazonLink'],
      walmartLink: data['walmartLink'],
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> data, String id) {
    return ShoppingListItem(
      id: id,
      name: data['name'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      isChecked: data['isChecked'] ?? false,
      amazonLink: data['amazonLink'],
      walmartLink: data['walmartLink'],
      addedAt: data['addedAt'] is Timestamp
          ? (data['addedAt'] as Timestamp).toDate()
          : DateTime.parse(data['addedAt'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'isChecked': isChecked,
      // Only save links if they are non-null and non-empty
      if (amazonLink != null && amazonLink!.isNotEmpty) 'amazonLink': amazonLink,
      if (walmartLink != null && walmartLink!.isNotEmpty) 'walmartLink': walmartLink,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  ShoppingListItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    bool? isChecked,
    String? amazonLink,
    String? walmartLink,
    DateTime? addedAt,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      amazonLink: amazonLink ?? this.amazonLink,
      walmartLink: walmartLink ?? this.walmartLink,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'ShoppingListItem(id: $id, name: $name, quantity: $quantity $unit, isChecked: $isChecked)';
  }
}

/// Shopping list model
class ShoppingList {
  final String id;
  final String name;
  final String? recipeId;
  final String? recipeTitle;
  final List<ShoppingListItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingList({
    required this.id,
    required this.name,
    this.recipeId,
    this.recipeTitle,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Get items from subcollection
    final items = <ShoppingListItem>[];
    // Note: Items will be loaded separately via streamShoppingListItems
    
    return ShoppingList(
      id: doc.id,
      name: data['name'] ?? 'Shopping List',
      recipeId: data['recipeId'],
      recipeTitle: data['recipeTitle'],
      items: items,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ShoppingList.fromMap(Map<String, dynamic> data, String id) {
    return ShoppingList(
      id: id,
      name: data['name'] ?? 'Shopping List',
      recipeId: data['recipeId'],
      recipeTitle: data['recipeTitle'],
      items: [], // Items loaded separately
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ShoppingList copyWith({
    String? id,
    String? name,
    String? recipeId,
    String? recipeTitle,
    List<ShoppingListItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      recipeId: recipeId ?? this.recipeId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get checked items count
  int get checkedCount => items.where((item) => item.isChecked).length;

  /// Get total items count
  int get totalCount => items.length;

  /// Check if all items are checked
  bool get isComplete => items.isNotEmpty && checkedCount == totalCount;

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, items: ${items.length}, recipeId: $recipeId)';
  }
}

