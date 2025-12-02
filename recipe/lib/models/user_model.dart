import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing a user in the app
class UserModel {
  final String userId;
  final String email;
  final String displayName;
  final String? photoURL;
  final String role;
  final UserPreferences preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.role = 'user',
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      userId: doc.id,
      email: (data['email'] as String?)?.trim() ?? '',
      displayName: (data['displayName'] as String?)?.trim() ?? '',
      photoURL: data['photoURL'] as String?,
      role: data['role'] as String? ?? 'user',
      preferences: UserPreferences.fromMap(data['preferences'] as Map<String, dynamic>? ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      role: data['role'] ?? 'user',
      preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role,
      'preferences': preferences.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? photoURL,
    String? role,
    UserPreferences? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  @override
  String toString() {
    return 'UserModel(userId: $userId, email: $email, displayName: $displayName, role: $role)';
  }
}

/// User preferences
class UserPreferences {
  final List<String> dietaryRestrictions;
  final List<String> allergies;
  final List<String> cuisinePreferences;
  final bool notificationsEnabled;
  final bool expiryAlerts;
  final String language;

  UserPreferences({
    this.dietaryRestrictions = const [],
    this.allergies = const [],
    this.cuisinePreferences = const [],
    this.notificationsEnabled = true,
    this.expiryAlerts = true,
    this.language = 'en',
  });

  factory UserPreferences.fromMap(Map<String, dynamic> data) {
    return UserPreferences(
      dietaryRestrictions:
          List<String>.from(data['dietaryRestrictions'] ?? []),
      allergies: List<String>.from(data['allergies'] ?? []),
      cuisinePreferences:
          List<String>.from(data['cuisinePreferences'] ?? []),
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      expiryAlerts: data['expiryAlerts'] ?? true,
      language: data['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dietaryRestrictions': dietaryRestrictions,
      'allergies': allergies,
      'cuisinePreferences': cuisinePreferences,
      'notificationsEnabled': notificationsEnabled,
      'expiryAlerts': expiryAlerts,
      'language': language,
    };
  }

  UserPreferences copyWith({
    List<String>? dietaryRestrictions,
    List<String>? allergies,
    List<String>? cuisinePreferences,
    bool? notificationsEnabled,
    bool? expiryAlerts,
    String? language,
  }) {
    return UserPreferences(
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      allergies: allergies ?? this.allergies,
      cuisinePreferences: cuisinePreferences ?? this.cuisinePreferences,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      expiryAlerts: expiryAlerts ?? this.expiryAlerts,
      language: language ?? this.language,
    );
  }
}

