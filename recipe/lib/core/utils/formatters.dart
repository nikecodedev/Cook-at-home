import 'package:intl/intl.dart';

/// Data formatting utilities
class Formatters {
  /// Format date to readable string (e.g., "Nov 11, 2025")
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date with time (e.g., "Nov 11, 2025 at 2:30 PM")
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(dateTime);
  }

  /// Format time only (e.g., "2:30 PM")
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  /// Format date to short format (e.g., "11/11/2025")
  static String formatDateShort(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  /// Format date to ISO string
  static String formatDateISO(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format relative time (e.g., "2 days ago", "in 3 hours")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      // Past
      final absDiff = difference.abs();
      if (absDiff.inDays > 365) {
        final years = (absDiff.inDays / 365).floor();
        return '$years ${years == 1 ? 'year' : 'years'} ago';
      } else if (absDiff.inDays > 30) {
        final months = (absDiff.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else if (absDiff.inDays > 0) {
        return '${absDiff.inDays} ${absDiff.inDays == 1 ? 'day' : 'days'} ago';
      } else if (absDiff.inHours > 0) {
        return '${absDiff.inHours} ${absDiff.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (absDiff.inMinutes > 0) {
        return '${absDiff.inMinutes} ${absDiff.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } else {
      // Future
      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return 'in $years ${years == 1 ? 'year' : 'years'}';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return 'in $months ${months == 1 ? 'month' : 'months'}';
      } else if (difference.inDays > 0) {
        return 'in ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
      } else if (difference.inHours > 0) {
        return 'in ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
      } else if (difference.inMinutes > 0) {
        return 'in ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
      } else {
        return 'Now';
      }
    }
  }

  /// Format expiry status
  static String formatExpiryStatus(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays == 0) {
      return 'Expires today';
    } else if (difference.inDays == 1) {
      return 'Expires tomorrow';
    } else if (difference.inDays <= 7) {
      return 'Expires in ${difference.inDays} days';
    } else {
      return 'Expires on ${formatDate(expiryDate)}';
    }
  }

  /// Format duration in minutes to readable string (e.g., "1h 30m")
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '${hours}h';
      }
      return '${hours}h ${mins}m';
    }
  }

  /// Format price (e.g., "$5.99")
  static String formatPrice(double price, [String currency = '\$']) {
    return '$currency${price.toStringAsFixed(2)}';
  }

  /// Format quantity with unit (e.g., "2.5 kg", "3 pieces")
  static String formatQuantity(double quantity, String unit) {
    // Remove trailing zeros
    final formattedQty = quantity % 1 == 0 
        ? quantity.toInt().toString() 
        : quantity.toStringAsFixed(1);
    return '$formattedQty $unit';
  }

  /// Format rating (e.g., "4.5/5.0")
  static String formatRating(double rating, {int maxRating = 5}) {
    return '${rating.toStringAsFixed(1)}/$maxRating';
  }

  /// Format percentage (e.g., "85%")
  static String formatPercentage(double value, {int decimals = 0}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format file size (e.g., "1.5 MB")
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Format number with commas (e.g., "1,234,567")
  static String formatNumberWithCommas(int number) {
    return NumberFormat('#,###').format(number);
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Title case (capitalize each word)
  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength, [String suffix = '...']) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }

  /// Format phone number (e.g., "(123) 456-7890")
  static String formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phone;
  }

  /// Format ingredients list
  static String formatIngredientsList(List<Map<String, dynamic>> ingredients) {
    return ingredients
        .map((ing) => '${formatQuantity(ing['quantity'], ing['unit'])} ${ing['name']}')
        .join(', ');
  }

  /// Parse date from string (handles multiple formats)
  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // Try other formats
      try {
        return DateFormat('MM/dd/yyyy').parse(dateString);
      } catch (e) {
        try {
          return DateFormat('MMM dd, yyyy').parse(dateString);
        } catch (e) {
          return null;
        }
      }
    }
  }
}

