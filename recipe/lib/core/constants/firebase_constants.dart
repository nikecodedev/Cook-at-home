/// Firebase Collection Names
class FirebaseCollections {
  static const String users = 'users';
  static const String pantryItems = 'pantry_items';
  static const String recipes = 'recipes';
  static const String shoppingLists = 'shopping_lists';
  static const String shoppingListItems = 'items';
  static const String recommendations = 'recommendations';
  static const String categories = 'categories';
  static const String userActivity = 'user_activity';
  static const String feedback = 'feedback';
  // Phase 2 collections
  static const String canonicalIngredients = 'canonical_ingredients';
  static const String products = 'products';
  static const String ingredientPrices = 'ingredient_prices';
  static const String mealPlans = 'meal_plans';
  static const String refillAlerts = 'refill_alerts';
}

/// Firebase Storage Paths
class FirebaseStoragePaths {
  static const String users = 'users';
  static const String recipes = 'recipes';
  static const String pantry = 'pantry';
  
  /// Get user profile image path
  static String userProfileImage(String userId, String imageId) {
    return '$users/$userId/profile/$imageId';
  }
  
  /// Get recipe image path
  static String recipeImage(String recipeId, String imageId) {
    return '$recipes/$recipeId/$imageId';
  }
  
  /// Get pantry item image path
  static String pantryItemImage(String userId, String itemId, String imageId) {
    return '$pantry/$userId/$itemId/$imageId';
  }
}

/// Firebase Field Names (for queries)
class FirebaseFields {
  // Common fields
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String userId = 'userId';
  
  // User fields
  static const String email = 'email';
  static const String displayName = 'displayName';
  static const String photoURL = 'photoURL';
  static const String role = 'role';
  
  // Pantry item fields
  static const String name = 'name';
  static const String category = 'category';
  static const String quantity = 'quantity';
  static const String unit = 'unit';
  static const String expiryDate = 'expiryDate';
  static const String isLowStock = 'isLowStock';
  
  // Recipe fields
  static const String title = 'title';
  static const String difficulty = 'difficulty';
  static const String rating = 'rating';
  static const String isPublic = 'isPublic';
  static const String isApproved = 'isApproved';
  
  // Shopping fields
  static const String listId = 'listId';
  static const String isPurchased = 'isPurchased';
  
  // Recommendation fields
  static const String matchScore = 'matchScore';
  static const String isViewed = 'isViewed';
  
  // Phase 2 fields
  static const String canonicalIngredientId = 'canonicalIngredientId';
  static const String barcode = 'barcode';
  static const String averagePrice = 'averagePrice';
  static const String userOverridePrice = 'userOverridePrice';
  static const String priceUnit = 'priceUnit';
  static const String yieldValue = 'yieldValue';
  static const String yieldUnit = 'yieldUnit';
  static const String standardPortionSize = 'standardPortionSize';
  static const String totalCost = 'totalCost';
  static const String costPerPortion = 'costPerPortion';
  static const String costTier = 'costTier';
}

/// User Roles
class UserRoles {
  static const String user = 'user';
  static const String admin = 'admin';
}

/// Recipe Difficulty Levels
class RecipeDifficulty {
  static const String easy = 'easy';
  static const String medium = 'medium';
  static const String hard = 'hard';
}

/// Common Units
class Units {
  // Weight units
  static const String grams = 'grams';
  static const String kilograms = 'kilograms';
  static const String ounces = 'ounces';
  static const String pounds = 'pounds';

  // Volume units
  static const String liters = 'liters';
  static const String milliliters = 'milliliters';
  static const String cups = 'cups';
  static const String tablespoons = 'tablespoons';
  static const String teaspoons = 'teaspoons';
  static const String fluidOunces = 'fluid_ounces';
  static const String pints = 'pints';
  static const String quarts = 'quarts';
  static const String gallons = 'gallons';

  // Count units
  static const String pieces = 'pieces';

  static List<String> get all => [
    // Weight
    grams,
    kilograms,
    ounces,
    pounds,
    // Volume
    liters,
    milliliters,
    cups,
    tablespoons,
    teaspoons,
    fluidOunces,
    pints,
    quarts,
    gallons,
    // Count
    pieces,
  ];

  /// Weight units only
  static List<String> get weight => [grams, kilograms, ounces, pounds];

  /// Volume units only
  static List<String> get volume => [liters, milliliters, cups, tablespoons, teaspoons, fluidOunces, pints, quarts, gallons];
}

/// Pantry Categories
class PantryCategories {
  static const String dairy = 'Dairy';
  static const String fruits = 'Fruits';
  static const String vegetables = 'Vegetables';
  static const String meat = 'Meat & Poultry';
  static const String seafood = 'Seafood';
  static const String grains = 'Grains & Bread';
  static const String canned = 'Canned Goods';
  static const String spices = 'Spices & Condiments';
  static const String beverages = 'Beverages';
  static const String frozen = 'Frozen Foods';
  static const String snacks = 'Snacks';
  static const String other = 'Other';
  
  static List<String> get all => [
    dairy,
    fruits,
    vegetables,
    meat,
    seafood,
    grains,
    canned,
    spices,
    beverages,
    frozen,
    snacks,
    other,
  ];
}

/// Recipe Categories
class RecipeCategories {
  static const String breakfast = 'Breakfast';
  static const String mainCourse = 'Main Course';
  static const String sideDish = 'Side Dish';
  static const String dessert = 'Dessert';
  static const String appetizer = 'Appetizer';
  static const String soupSalad = 'Soup & Salad';
  static const String beverages = 'Beverages';
  static const String snacks = 'Snacks';
  
  static List<String> get all => [
    breakfast,
    mainCourse,
    sideDish,
    dessert,
    appetizer,
    soupSalad,
    beverages,
    snacks,
  ];
}

/// Cuisine Types
class CuisineTypes {
  static const String italian = 'Italian';
  static const String mexican = 'Mexican';
  static const String chinese = 'Chinese';
  static const String indian = 'Indian';
  static const String japanese = 'Japanese';
  static const String american = 'American';
  static const String french = 'French';
  static const String thai = 'Thai';
  static const String mediterranean = 'Mediterranean';
  static const String middleEastern = 'Middle Eastern';
  static const String other = 'Other';
  
  static List<String> get all => [
    italian,
    mexican,
    chinese,
    indian,
    japanese,
    american,
    french,
    thai,
    mediterranean,
    middleEastern,
    other,
  ];
}

/// Storage Locations
class StorageLocations {
  static const String fridge = 'Fridge';
  static const String freezer = 'Freezer';
  static const String pantry = 'Pantry';
  static const String cabinet = 'Cabinet';
  static const String counter = 'Counter';
  
  static List<String> get all => [
    fridge,
    freezer,
    pantry,
    cabinet,
    counter,
  ];
}

/// Cost Tiers
class CostTiers {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  
  static List<String> get all => [low, medium, high];
}

/// Yield Units (for recipes)
class YieldUnits {
  static const String grams = 'grams';
  static const String kilograms = 'kilograms';
  static const String liters = 'liters';
  static const String milliliters = 'milliliters';
  static const String cups = 'cups';
  static const String pieces = 'pieces';
  
  static List<String> get all => [
    grams,
    kilograms,
    liters,
    milliliters,
    cups,
    pieces,
  ];
}

