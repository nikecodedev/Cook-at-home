import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/firebase_config.dart';
import '../core/constants/firebase_constants.dart';
import '../models/refill_alert_model.dart';
import '../models/pantry_item_model.dart';
import '../core/utils/logger.dart';

/// Service for managing smart refill alerts
class RefillAlertService {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  /// Generate refill alerts based on pantry depletion
  Future<List<RefillAlert>> generateDepletionAlerts(
    String userId,
    List<PantryItem> pantryItems,
  ) async {
    try {
      final List<RefillAlert> alerts = [];
      final now = DateTime.now();

      // Track consumption frequency (simplified: items that are frequently added/removed)
      // For now, we'll alert on items with low quantity
      for (final item in pantryItems) {
        if (item.canonicalIngredientId == null || item.canonicalIngredientId!.isEmpty) {
          continue;
        }

        // Simple threshold: alert if quantity is below 20% of typical amount
        // This is a simplified heuristic - in production, track historical usage
        final isLowStock = item.quantity < 1.0; // Adjust threshold as needed

        if (isLowStock) {
          // Check if alert already exists
          final existing = await getActiveAlert(
            userId,
            item.canonicalIngredientId!,
            'depletion',
          );

          if (existing == null) {
            final alert = RefillAlert(
              id: '', // Will be set by Firestore
              userId: userId,
              canonicalIngredientId: item.canonicalIngredientId!,
              ingredientName: item.name,
              reason: 'depletion',
              currentQuantity: item.quantity,
              currentUnit: item.unit,
              createdAt: now,
            );

            final alertId = await createRefillAlert(alert);
            alerts.add(alert.copyWith(id: alertId));
          }
        }
      }

      return alerts;
    } catch (e) {
      Logger.error('Failed to generate depletion alerts', e, null, 'RefillAlertService');
      return [];
    }
  }

  /// Get active refill alerts for a user
  Future<List<RefillAlert>> getActiveRefillAlerts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.refillAlerts)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RefillAlert.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Failed to get active refill alerts', e, null, 'RefillAlertService');
      return [];
    }
  }

  /// Get active alert for a specific ingredient
  Future<RefillAlert?> getActiveAlert(
    String userId,
    String canonicalIngredientId,
    String reason,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.refillAlerts)
          .where('canonicalIngredientId', isEqualTo: canonicalIngredientId)
          .where('reason', isEqualTo: reason)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return RefillAlert.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to get active alert', e, null, 'RefillAlertService');
      return null;
    }
  }

  /// Create a refill alert
  Future<String> createRefillAlert(RefillAlert alert) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseCollections.users)
          .doc(alert.userId)
          .collection(FirebaseCollections.refillAlerts)
          .add(alert.toMap());

      Logger.success('Refill alert created: ${docRef.id}', 'RefillAlertService');
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to create refill alert', e, null, 'RefillAlertService');
      rethrow;
    }
  }

  /// Dismiss a refill alert
  Future<void> dismissRefillAlert(String userId, String alertId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.refillAlerts)
          .doc(alertId)
          .update({
            'isActive': false,
            'dismissedAt': Timestamp.now(),
          });

      Logger.success('Refill alert dismissed: $alertId', 'RefillAlertService');
    } catch (e) {
      Logger.error('Failed to dismiss refill alert', e, null, 'RefillAlertService');
      rethrow;
    }
  }

  /// Stream active refill alerts
  Stream<List<RefillAlert>> streamActiveRefillAlerts(String userId) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .collection(FirebaseCollections.refillAlerts)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return RefillAlert.fromFirestore(doc);
            } catch (e) {
              Logger.error('Failed to parse refill alert', e, null, 'RefillAlertService');
              return null;
            }
          })
          .whereType<RefillAlert>()
          .toList();
    }).handleError((error) {
      Logger.error('Error in refill alerts stream', error, null, 'RefillAlertService');
      return <RefillAlert>[];
    });
  }
}

