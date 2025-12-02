import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/firebase_config.dart';
import '../../core/constants/firebase_constants.dart';
import '../../models/user_model.dart';
import '../../core/utils/logger.dart';

/// Service for managing user profiles in Firestore
class UserService {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  /// Create a new user profile in Firestore
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String displayName,
    String? photoURL,
    String role = 'user',
  }) async {
    try {
      final now = DateTime.now();
      final userModel = UserModel(
        userId: userId,
        email: email,
        displayName: displayName,
        photoURL: photoURL,
        role: role,
        preferences: UserPreferences(),
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .set(userModel.toMap());

      Logger.success('User profile created: $userId', 'UserService');
    } catch (e) {
      Logger.error('Failed to create user profile', e, null, 'UserService');
      rethrow;
    }
  }

  /// Get user profile from Firestore
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get user profile', e, null, 'UserService');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? photoURL,
    UserPreferences? preferences,
  }) async {
    try {
      final updates = <String, dynamic>{
        FirebaseFields.updatedAt: Timestamp.now(),
      };

      if (displayName != null) {
        updates[FirebaseFields.displayName] = displayName;
      }
      if (photoURL != null) {
        updates[FirebaseFields.photoURL] = photoURL;
      }
      if (preferences != null) {
        updates['preferences'] = preferences.toMap();
      }

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update(updates);

      Logger.success('User profile updated: $userId', 'UserService');
    } catch (e) {
      Logger.error('Failed to update user profile', e, null, 'UserService');
      rethrow;
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .delete();

      Logger.success('User profile deleted: $userId', 'UserService');
    } catch (e) {
      Logger.error('Failed to delete user profile', e, null, 'UserService');
      rethrow;
    }
  }

  /// Stream user profile changes
  Stream<UserModel?> streamUserProfile(String userId) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Check if user profile exists
  Future<bool> userProfileExists(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      Logger.error('Failed to check user profile', e, null, 'UserService');
      return false;
    }
  }

  /// Update user preferences
  Future<void> updatePreferences({
    required String userId,
    required UserPreferences preferences,
  }) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update({
        'preferences': preferences.toMap(),
        FirebaseFields.updatedAt: Timestamp.now(),
      });

      Logger.success('User preferences updated: $userId', 'UserService');
    } catch (e) {
      Logger.error(
          'Failed to update user preferences', e, null, 'UserService');
      rethrow;
    }
  }
}

