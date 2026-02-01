import 'package:cloud_firestore/cloud_firestore.dart';

/// User custom store model - represents a user's preferred store for purchases
class UserStore {
  final String id;
  final String name; // Store name (e.g., "Mi tienda local", "Costco")
  final String? baseUrl; // Optional base URL for the store
  final DateTime createdAt;
  final DateTime updatedAt;

  UserStore({
    required this.id,
    required this.name,
    this.baseUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserStore from Firestore document
  factory UserStore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserStore(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? '',
      baseUrl: data['baseUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create UserStore from Map
  factory UserStore.fromMap(Map<String, dynamic> data, String id) {
    return UserStore(
      id: id,
      name: (data['name'] as String?)?.trim() ?? '',
      baseUrl: data['baseUrl'] as String?,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert UserStore to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'baseUrl': baseUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  UserStore copyWith({
    String? id,
    String? name,
    String? baseUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserStore(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserStore(id: $id, name: $name, baseUrl: $baseUrl)';
  }
}

/// Custom store link for an item - stored as part of pantry/shopping items
class CustomStoreLink {
  final String storeName;
  final String url;

  CustomStoreLink({
    required this.storeName,
    required this.url,
  });

  factory CustomStoreLink.fromMap(Map<String, dynamic> data) {
    return CustomStoreLink(
      storeName: data['storeName'] ?? '',
      url: data['url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'url': url,
    };
  }

  @override
  String toString() {
    return 'CustomStoreLink(storeName: $storeName, url: $url)';
  }
}
