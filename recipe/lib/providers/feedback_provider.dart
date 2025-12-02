import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore/firestore_service.dart';
import '../models/feedback_model.dart';
import '../core/utils/logger.dart';
import 'profile_provider.dart';
import 'auth_provider.dart';

/// Provider for feedback controller
final feedbackControllerProvider =
    StateNotifierProvider<FeedbackController, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FeedbackController(firestoreService, ref);
});

/// Feedback controller for handling feedback operations
class FeedbackController extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  FeedbackController(this._firestoreService, this._ref)
      : super(const AsyncValue.data(null));

  /// Submit feedback
  Future<String> submitFeedback({
    required String message,
    required FeedbackCategory category,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No hay usuario conectado');
    }

    state = const AsyncValue.loading();

    try {
      final feedbackId = await _firestoreService.submitFeedback(
        userId: userId,
        message: message,
        category: category,
      );
      state = const AsyncValue.data(null);
      return feedbackId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      Logger.error('Failed to submit feedback', e, stackTrace, 'FeedbackController');
      rethrow;
    }
  }
}

/// Provider for user's feedback stream
final userFeedbackStreamProvider = StreamProvider<List<Feedback>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamUserFeedback(userId);
});

