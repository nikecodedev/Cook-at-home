/// Service for generating purchase/affiliate links
/// 
/// This service centralizes all purchase link generation logic.
/// 
/// ## How to Update Affiliate Tags
/// 
/// 1. Get your affiliate IDs:
///    - **Amazon**: Sign up for Amazon Associates and get your Associate Tag (e.g., "yourstore-20")
///    - **Walmart**: Sign up for Walmart Affiliate Program and get your Affiliate ID
/// 
/// 2. Update the constants below:
///    - Set [amazonAffiliateTag] to your Amazon Associate Tag
///    - Set [walmartAffiliateTag] to your Walmart Affiliate ID
/// 
/// 3. All purchase links throughout the app will automatically include your affiliate tags.
/// 
/// ## Usage
/// 
/// The service is used automatically by:
/// - Purchase buttons in shopping lists
/// - Purchase buttons in pantry items
/// - Link generation when creating shopping lists from recipes
/// - Shop buttons in recipe add/edit screens
class PurchaseLinkService {
  // ==================== AFFILIATE TAGS ====================
  // 
  // UPDATE THESE WHEN YOU GET YOUR AFFILIATE IDs:
  // 
  // For Amazon Associates:
  //   1. Sign up at https://affiliate-program.amazon.com/
  //   2. Get your Associate Tag (format: "yourstore-20")
  //   3. Replace null below with your tag: static const String? amazonAffiliateTag = "yourstore-20";
  // 
  // For Walmart Affiliate Program:
  //   1. Sign up at https://affiliates.walmart.com/
  //   2. Get your Affiliate ID
  //   3. Replace null below with your ID: static const String? walmartAffiliateTag = "yourid";
  // 
  static const String? amazonAffiliateTag = null; // TODO: Add your Amazon Associate Tag
  static const String? walmartAffiliateTag = null; // TODO: Add your Walmart Affiliate ID

  // ==================== BASE URLs ====================
  static const String amazonBaseUrl = 'https://www.amazon.com';
  static const String walmartBaseUrl = 'https://www.walmart.com';

  /// Generate Amazon search link for an item
  /// 
  /// If [amazonAffiliateTag] is set, it will be included in the URL.
  /// If [customUrl] is provided, it will be used instead of generating a search link.
  static String generateAmazonLink({
    required String itemName,
    String? customUrl,
  }) {
    // If a custom URL is provided, validate and use it (but still add affiliate tag if available)
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      // Validate that it's actually an Amazon URL
      if (isAmazonUrl(customUrl)) {
        return _addAffiliateTagToUrl(customUrl, amazonAffiliateTag, 'tag');
      }
      // If customUrl is provided but not a valid Amazon URL, fall through to generate new one
    }

    // Generate search URL
    final encodedName = Uri.encodeComponent(itemName.trim());
    String url = '$amazonBaseUrl/s?k=$encodedName';

    // Add affiliate tag if available
    if (amazonAffiliateTag != null && amazonAffiliateTag!.isNotEmpty) {
      url = '$url&tag=${Uri.encodeComponent(amazonAffiliateTag!)}';
    }

    return url;
  }

  /// Generate Walmart search link for an item
  /// 
  /// If [walmartAffiliateTag] is set, it will be included in the URL.
  /// If [customUrl] is provided, it will be used instead of generating a search link.
  static String generateWalmartLink({
    required String itemName,
    String? customUrl,
  }) {
    // If a custom URL is provided, validate and use it (but still add affiliate tag if available)
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      // Validate that it's actually a Walmart URL
      if (isWalmartUrl(customUrl)) {
        return _addAffiliateTagToUrl(customUrl, walmartAffiliateTag, 'affid');
      }
      // If customUrl is provided but not a valid Walmart URL, fall through to generate new one
    }

    // Generate search URL
    final encodedName = Uri.encodeComponent(itemName.trim());
    String url = '$walmartBaseUrl/search?q=$encodedName';

    // Add affiliate tag if available
    if (walmartAffiliateTag != null && walmartAffiliateTag!.isNotEmpty) {
      url = '$url&affid=${Uri.encodeComponent(walmartAffiliateTag!)}';
    }

    return url;
  }

  /// Add affiliate tag to an existing URL
  /// 
  /// Handles both URLs with and without existing query parameters.
  static String _addAffiliateTagToUrl(
    String url,
    String? affiliateTag,
    String tagParamName,
  ) {
    if (affiliateTag == null || affiliateTag.isEmpty) {
      return url;
    }

    // Normalize URL - ensure it has a scheme
    String normalizedUrl = url.trim();
    if (!normalizedUrl.startsWith('http://') && !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }

    try {
      final uri = Uri.parse(normalizedUrl);
      
      // Validate URI
      if (!uri.hasScheme || !uri.hasAuthority) {
        throw FormatException('Invalid URL format');
      }
      
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams[tagParamName] = affiliateTag;

      return uri.replace(queryParameters: queryParams).toString();
    } catch (e) {
      // If URL parsing fails, append the tag manually
      final separator = normalizedUrl.contains('?') ? '&' : '?';
      return '$normalizedUrl$separator$tagParamName=${Uri.encodeComponent(affiliateTag)}';
    }
  }

  /// Check if a URL is a valid Amazon URL
  static bool isAmazonUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('amazon.com') || uri.host.contains('amazon.');
    } catch (e) {
      return false;
    }
  }

  /// Check if a URL is a valid Walmart URL
  static bool isWalmartUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('walmart.com') || uri.host.contains('walmart.');
    } catch (e) {
      return false;
    }
  }

  /// Generate links for multiple items (for recipe ingredients)
  /// Returns a combined search URL
  static String generateAmazonLinkForItems(List<String> itemNames) {
    if (itemNames.isEmpty) {
      return generateAmazonLink(itemName: 'groceries');
    }

    final combinedQuery = itemNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .join(' ');
    
    return generateAmazonLink(itemName: combinedQuery);
  }

  /// Generate links for multiple items (for recipe ingredients)
  /// Returns a combined search URL
  static String generateWalmartLinkForItems(List<String> itemNames) {
    if (itemNames.isEmpty) {
      return generateWalmartLink(itemName: 'groceries');
    }

    final combinedQuery = itemNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .join(' ');
    
    return generateWalmartLink(itemName: combinedQuery);
  }
}

