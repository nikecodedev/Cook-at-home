import 'package:cloud_firestore/cloud_firestore.dart';

/// Feedback category enum
enum FeedbackCategory {
  issue,
  suggestion,
  other;

  String get displayName {
    switch (this) {
      case FeedbackCategory.issue:
        return 'Problema';
      case FeedbackCategory.suggestion:
        return 'Sugerencia';
      case FeedbackCategory.other:
        return 'Otro';
    }
  }
}

/// Feedback model
class Feedback {
  final String id;
  final String userId;
  final String message;
  final FeedbackCategory category;
  final DateTime createdAt;

  Feedback({
    required this.id,
    required this.userId,
    required this.message,
    required this.category,
    required this.createdAt,
  });

  /// Create Feedback from Firestore document
  factory Feedback.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Feedback(
      id: doc.id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      category: _categoryFromString(data['category'] ?? 'other'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create Feedback from Map
  factory Feedback.fromMap(Map<String, dynamic> data, String id) {
    return Feedback(
      id: id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      category: _categoryFromString(data['category'] ?? 'other'),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'].toString()),
    );
  }

  /// Convert Feedback to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'category': category.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Helper to convert string to FeedbackCategory
  static FeedbackCategory _categoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'issue':
        return FeedbackCategory.issue;
      case 'suggestion':
        return FeedbackCategory.suggestion;
      case 'other':
      default:
        return FeedbackCategory.other;
    }
  }

  Feedback copyWith({
    String? id,
    String? userId,
    String? message,
    FeedbackCategory? category,
    DateTime? createdAt,
  }) {
    return Feedback(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Feedback(id: $id, userId: $userId, category: ${category.name}, message: ${message.substring(0, message.length > 50 ? 50 : message.length)}...)';
  }
}

