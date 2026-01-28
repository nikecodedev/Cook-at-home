import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/firebase_config.dart';
import '../core/constants/firebase_constants.dart';
import '../models/meal_plan_model.dart';
import '../core/utils/logger.dart';

/// Service for managing meal plans
class MealPlanService {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  /// Get meal plan for a specific week
  Future<MealPlan?> getMealPlanForWeek(
    String userId,
    DateTime weekStartDate,
  ) async {
    try {
      // Normalize to Monday
      final monday = _getMonday(weekStartDate);
      
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.mealPlans)
          .where('weekStartDate', isEqualTo: Timestamp.fromDate(monday))
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return MealPlan.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get meal plan for week', e, null, 'MealPlanService');
      return null;
    }
  }

  /// Create or update meal plan
  Future<String> saveMealPlan(MealPlan mealPlan) async {
    try {
      // Normalize week start date to Monday
      final monday = _getMonday(mealPlan.weekStartDate);
      final normalizedPlan = mealPlan.copyWith(weekStartDate: monday);

      // Check if meal plan exists for this week
      final existing = await getMealPlanForWeek(normalizedPlan.userId, monday);
      
      if (existing != null) {
        // Update existing
        await _firestore
            .collection(FirebaseCollections.users)
            .doc(normalizedPlan.userId)
            .collection(FirebaseCollections.mealPlans)
            .doc(existing.id)
            .update(normalizedPlan.copyWith(
              id: existing.id,
              updatedAt: DateTime.now(),
            ).toMap());

        Logger.success('Meal plan updated: ${existing.id}', 'MealPlanService');
        return existing.id;
      } else {
        // Create new
        final now = DateTime.now();
        final newPlan = normalizedPlan.copyWith(
          id: '', // Will be set by Firestore
          createdAt: now,
          updatedAt: now,
        );

        final docRef = await _firestore
            .collection(FirebaseCollections.users)
            .doc(normalizedPlan.userId)
            .collection(FirebaseCollections.mealPlans)
            .add(newPlan.toMap());

        Logger.success('Meal plan created: ${docRef.id}', 'MealPlanService');
        return docRef.id;
      }
    } catch (e) {
      Logger.error('Failed to save meal plan', e, null, 'MealPlanService');
      rethrow;
    }
  }

  /// Delete meal plan
  Future<void> deleteMealPlan(String userId, String mealPlanId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.mealPlans)
          .doc(mealPlanId)
          .delete();

      Logger.success('Meal plan deleted: $mealPlanId', 'MealPlanService');
    } catch (e) {
      Logger.error('Failed to delete meal plan', e, null, 'MealPlanService');
      rethrow;
    }
  }

  /// Stream meal plans for a user
  Stream<List<MealPlan>> streamMealPlans(String userId) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.mealPlans)
        .orderBy('weekStartDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return MealPlan.fromFirestore(doc);
            } catch (e) {
              Logger.error('Failed to parse meal plan', e, null, 'MealPlanService');
              return null;
            }
          })
          .whereType<MealPlan>()
          .toList();
    }).handleError((error) {
      Logger.error('Error in meal plans stream', error, null, 'MealPlanService');
      return <MealPlan>[];
    });
  }

  /// Get Monday of the week for a given date
  DateTime _getMonday(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final daysFromMonday = weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }
}



