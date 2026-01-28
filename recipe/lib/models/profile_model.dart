import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Profile model representing user profile and household information
class ProfileModel {
  final String userId;
  final String name;
  final String email;
  final String? location;
  final String unitPreference; // e.g., 'metric', 'imperial'
  final int servingSize;
  final String? languagePreference; // e.g., 'en', 'es' - null = use device default
  final List<HouseholdMember> householdMembers;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    required this.userId,
    required this.name,
    required this.email,
    this.location,
    this.unitPreference = 'metric',
    this.servingSize = 4,
    this.languagePreference,
    this.householdMembers = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ProfileModel from Firestore document
  /// Handles both UserModel format (with displayName) and ProfileModel format (with name)
  factory ProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle both UserModel (displayName) and ProfileModel (name) formats
    final name = data['name'] ?? data['displayName'] ?? '';
    
    // Parse householdMembers - handle both string list and map list formats
    List<HouseholdMember> householdMembers = [];
    if (data['householdMembers'] != null) {
      final membersList = data['householdMembers'] as List<dynamic>?;
      if (membersList != null) {
        householdMembers = membersList.map((member) {
          if (member is String) {
            // Handle legacy string format - convert to HouseholdMember
            return HouseholdMember(
              id: const Uuid().v4(),
              name: member,
              relationship: null,
              age: null,
            );
          } else if (member is Map<String, dynamic>) {
            // Handle map format
            return HouseholdMember.fromMap(member);
          } else {
            // Skip invalid entries
            return null;
          }
        }).whereType<HouseholdMember>().toList();
      }
    }
    
    return ProfileModel(
      userId: doc.id,
      name: name,
      email: data['email'] ?? '',
      location: data['location'],
      unitPreference: data['unitPreference'] ?? 'metric',
      servingSize: data['servingSize'] ?? 4,
      languagePreference: data['languagePreference'] as String?,
      householdMembers: householdMembers,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create ProfileModel from Map
  factory ProfileModel.fromMap(Map<String, dynamic> data) {
    // Parse householdMembers - handle both string list and map list formats
    List<HouseholdMember> householdMembers = [];
    if (data['householdMembers'] != null) {
      final membersList = data['householdMembers'] as List<dynamic>?;
      if (membersList != null) {
        householdMembers = membersList.map((member) {
          if (member is String) {
            // Handle legacy string format - convert to HouseholdMember
            return HouseholdMember(
              id: const Uuid().v4(),
              name: member,
              relationship: null,
              age: null,
            );
          } else if (member is Map<String, dynamic>) {
            // Handle map format
            return HouseholdMember.fromMap(member);
          } else {
            // Skip invalid entries
            return null;
          }
        }).whereType<HouseholdMember>().toList();
      }
    }
    
    return ProfileModel(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      location: data['location'],
      unitPreference: data['unitPreference'] ?? 'metric',
      servingSize: data['servingSize'] ?? 4,
      languagePreference: data['languagePreference'] as String?,
      householdMembers: householdMembers,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert ProfileModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'location': location,
      'unitPreference': unitPreference,
      'servingSize': servingSize,
      'languagePreference': languagePreference,
      'householdMembers': householdMembers.map((member) => member.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  ProfileModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? location,
    String? unitPreference,
    int? servingSize,
    String? languagePreference,
    List<HouseholdMember>? householdMembers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      location: location ?? this.location,
      unitPreference: unitPreference ?? this.unitPreference,
      servingSize: servingSize ?? this.servingSize,
      languagePreference: languagePreference ?? this.languagePreference,
      householdMembers: householdMembers ?? this.householdMembers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProfileModel(userId: $userId, name: $name, email: $email, location: $location, unitPreference: $unitPreference, servingSize: $servingSize, householdMembers: ${householdMembers.length})';
  }
}

/// Household member model
class HouseholdMember {
  final String id;
  final String name;
  final String? relationship; // e.g., 'spouse', 'child', 'parent', 'other'
  final int? age;

  HouseholdMember({
    required this.id,
    required this.name,
    this.relationship,
    this.age,
  });

  factory HouseholdMember.fromMap(Map<String, dynamic> data) {
    return HouseholdMember(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      relationship: data['relationship'],
      age: data['age'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'age': age,
    };
  }

  HouseholdMember copyWith({
    String? id,
    String? name,
    String? relationship,
    int? age,
  }) {
    return HouseholdMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      age: age ?? this.age,
    );
  }

  @override
  String toString() {
    return 'HouseholdMember(id: $id, name: $name, relationship: $relationship, age: $age)';
  }
}

