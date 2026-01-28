# Average Ingredient Price Engine - Implementation

## Overview

Complete implementation of the Average Ingredient Price Engine that automatically assigns default prices when pantry items are added and supports user price overrides.

---

## ✅ Implementation Status

### Completed Components

1. **✅ IngredientPrice Model** (`lib/models/ingredient_price_model.dart`)
   - `canonicalIngredientId` - Reference to canonical ingredient
   - `averagePrice` - Global average price
   - `priceUnit` - Unit for the price
   - `userOverridePrice` - User's manual override (optional)
   - `updatedAt` - Last update timestamp
   - `createdAt` - Creation timestamp
   - `effectivePrice` getter - Returns override if set, otherwise average

2. **✅ IngredientPriceService** (`lib/services/ingredient_price_service.dart`)
   - `getIngredientPrice()` - Get global price
   - `getUserIngredientPrice()` - Get price with user override
   - `setIngredientPrice()` - Set/update global average price
   - `setUserOverridePrice()` - Set user override price
   - `getIngredientPrices()` - Batch get prices
   - `initializeDefaultPrice()` - Initialize default price (called when pantry item added)

3. **✅ Pantry Integration** (`lib/providers/pantry_provider.dart`)
   - Auto-initializes default price when pantry item added
   - Uses canonical ingredient ID from pantry item
   - Non-blocking (doesn't fail if price init fails)

4. **✅ Firestore Schema**
   - Global collection: `ingredient_prices`
   - User overrides: `users/{userId}/ingredient_prices`

---

## Firestore Collection: `ingredient_prices`

### Schema

**Path:** `/ingredient_prices/{ingredientId}`

**Fields:**
- `canonicalIngredientId` (String, required) - Reference to canonical ingredient
- `averagePrice` (Number, required) - Average price per unit
- `priceUnit` (String, required) - Unit for the price (e.g., 'grams', 'liters', 'pieces')
- `updatedAt` (Timestamp, required) - Last update timestamp
- `createdAt` (Timestamp, required) - Creation timestamp

**Note:** `userOverridePrice` is stored in user subcollection, not in global collection.

### User Override Subcollection

**Path:** `/users/{userId}/ingredient_prices/{canonicalIngredientId}`

**Fields:**
- `canonicalIngredientId` (String, required)
- `userOverridePrice` (Number, required) - User's override price
- `updatedAt` (Timestamp, required)

---

## Behavior

### When Pantry Item Added

1. **Pantry item saved** to Firestore
2. **Check canonical ingredient ID**:
   - If `canonicalIngredientId` is present → Proceed
   - If not present → Skip price initialization
3. **Check if price exists**:
   - Query `ingredient_prices` collection for `canonicalIngredientId`
   - If price exists → Skip initialization
   - If not exists → Initialize default price
4. **Initialize default price**:
   - Create price document with `averagePrice = 0.0`
   - Use pantry item's unit as `priceUnit`
   - Set `canonicalIngredientId`
   - Set timestamps

### Price Resolution (Effective Price)

When getting a price for a user:

1. **Check user override** (`users/{userId}/ingredient_prices/{canonicalIngredientId}`)
2. **If override exists** → Return override price
3. **If no override** → Return global average price
4. **If no price exists** → Return null

**Formula:**
```
effectivePrice = userOverridePrice ?? averagePrice
```

---

## Price Storage Rules

### Per Ingredient, Not Per Store

- **Single price per ingredient**: One average price per canonical ingredient
- **No store-specific prices**: Price is global average, not per retailer
- **User overrides**: Users can override with their own price
- **Future-ready**: Architecture supports dynamic pricing (can be extended later)

### No Retailer Integration

- **No external APIs**: Prices are manually set or user-provided
- **No scraping**: No retailer price scraping
- **Manual entry**: Prices entered by users or admins
- **Average calculation**: Future enhancement can calculate averages from user entries

---

## User Price Override

### Setting Override

```dart
final priceService = IngredientPriceService();

// Set user override price
await priceService.setUserOverridePrice(
  userId: 'user123',
  canonicalIngredientId: 'ingredient456',
  overridePrice: 2.50, // User's price
);

// Remove override (use global average)
await priceService.setUserOverridePrice(
  userId: 'user123',
  canonicalIngredientId: 'ingredient456',
  overridePrice: null, // Removes override
);
```

### Getting Price with Override

```dart
// Get price with user override (if set)
final price = await priceService.getUserIngredientPrice(
  'ingredient456',
  'user123',
);

// price.effectivePrice will be:
// - userOverridePrice if user has override
// - averagePrice if no override
```

---

## Integration Points

### 1. Pantry Item Creation

**Location:** `lib/providers/pantry_provider.dart`

**Flow:**
```dart
// When pantry item added:
1. Save pantry item to Firestore
2. If canonicalIngredientId exists:
   - Call initializeDefaultPrice()
   - Use pantry item's unit as default
   - Set default price to 0.0 (user can override)
3. Continue (non-blocking)
```

### 2. Recipe Cost Calculation

**Location:** `lib/services/recipe_cost_service.dart`

**Flow:**
```dart
// When calculating recipe cost:
1. Get all canonical ingredient IDs from recipe
2. Get prices (with user overrides if userId provided)
3. Calculate cost per ingredient
4. Sum total cost
5. Calculate cost per serving (if yield data available)
```

### 3. Pantry Analytics

**Location:** `lib/services/pantry_analytics_service.dart`

**Flow:**
```dart
// When calculating pantry value:
1. Get all pantry items
2. Resolve canonical ingredient IDs
3. Get prices (with user overrides)
4. Calculate value per item
5. Sum total pantry value
```

---

## Default Price Initialization

### When Called

- **Pantry item added** with `canonicalIngredientId`
- **Non-blocking**: Doesn't fail if price init fails
- **Idempotent**: Safe to call multiple times

### Default Values

- **averagePrice**: `0.0` (user must set manually or via future dynamic pricing)
- **priceUnit**: Uses pantry item's unit
- **canonicalIngredientId**: From pantry item

### Example

```dart
// User adds pantry item:
PantryItem(
  name: "Tomatoes",
  canonicalIngredientId: "tomato123",
  quantity: 5.0,
  unit: "pieces",
  // ...
)

// System automatically:
await priceService.initializeDefaultPrice(
  canonicalIngredientId: "tomato123",
  defaultPrice: 0.0,
  defaultUnit: "pieces",
);

// Creates price document:
{
  "canonicalIngredientId": "tomato123",
  "averagePrice": 0.0,
  "priceUnit": "pieces",
  "updatedAt": Timestamp.now(),
  "createdAt": Timestamp.now(),
}
```

---

## Architecture for Future Dynamic Pricing

### Current Architecture

- **Service-based**: `IngredientPriceService` handles all price operations
- **Separation of concerns**: Price logic separated from pantry/recipe logic
- **Extensible**: Easy to add new price sources

### Future Enhancements (Architecture Ready)

1. **Price Aggregation Service**:
   ```dart
   class PriceAggregationService {
     // Calculate average from multiple sources
     Future<double> calculateAveragePrice(String canonicalIngredientId);
   }
   ```

2. **Price Source Interface**:
   ```dart
   abstract class PriceSource {
     Future<double?> getPrice(String canonicalIngredientId);
   }
   
   class RetailerPriceSource implements PriceSource { ... }
   class UserPriceSource implements PriceSource { ... }
   ```

3. **Dynamic Price Updates**:
   - Cloud Functions to update prices periodically
   - User price submissions aggregated into averages
   - Regional pricing support

### Current Limitations (By Design)

- **No retailer integration**: As per requirements
- **Manual price entry**: Prices must be set manually
- **No automatic updates**: Prices don't update automatically

---

## Validation

### Price Validation

- **averagePrice**: Must be >= 0 (can be 0 for unknown prices)
- **priceUnit**: Must be valid unit (grams, liters, pieces, etc.)
- **canonicalIngredientId**: Must reference existing canonical ingredient

### User Override Validation

- **overridePrice**: Must be > 0 (cannot be 0 or negative)
- **canonicalIngredientId**: Must reference existing canonical ingredient
- **userId**: Must be valid user ID

---

## Error Handling

### Price Initialization Errors

- **Non-critical**: Price initialization failures don't prevent pantry item creation
- **Logging**: Errors are logged but not thrown
- **Graceful degradation**: App continues to function without prices

### Price Lookup Errors

- **Null handling**: Returns null if price not found
- **Error logging**: Errors logged for debugging
- **Fallback**: Calculations use 0.0 if price unavailable

---

## Testing Checklist

- [ ] Add pantry item with canonical ID → Price initialized
- [ ] Add pantry item without canonical ID → No price init
- [ ] Add pantry item with existing price → No duplicate created
- [ ] Get price without override → Returns average
- [ ] Get price with override → Returns override
- [ ] Set user override → Override stored
- [ ] Remove user override → Falls back to average
- [ ] Calculate recipe cost with prices
- [ ] Calculate recipe cost without prices (graceful handling)
- [ ] Calculate pantry value with prices
- [ ] Batch price lookup (multiple ingredients)

---

## Files Modified/Created

### Modified
- `lib/models/ingredient_price_model.dart` - Updated to use `updatedAt`
- `lib/services/ingredient_price_service.dart` - Enhanced with initialization
- `lib/providers/pantry_provider.dart` - Integrated price initialization

### Created
- `INGREDIENT_PRICE_ENGINE.md` - This documentation

---

## Firestore Indexes Required

### Composite Index

**Collection:** `ingredient_prices`  
**Fields:**
- `canonicalIngredientId` (Ascending)

**Purpose:** Enable efficient price lookups by canonical ingredient

**Firestore Console Command:**
```bash
firebase firestore:indexes
```

**Index Definition:**
```json
{
  "indexes": [
    {
      "collectionGroup": "ingredient_prices",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "canonicalIngredientId",
          "order": "ASCENDING"
        }
      ]
    }
  ]
}
```

---

## Security Rules

### Recommended Firestore Security Rules

```javascript
// Global ingredient prices
match /ingredient_prices/{priceId} {
  // Allow read for all authenticated users
  allow read: if request.auth != null;
  
  // Allow create/update for authenticated users (can restrict to admins)
  allow create: if request.auth != null
    && request.resource.data.keys().hasAll(['canonicalIngredientId', 'averagePrice', 'priceUnit', 'createdAt', 'updatedAt'])
    && request.resource.data.canonicalIngredientId is string
    && request.resource.data.averagePrice is number
    && request.resource.data.averagePrice >= 0;
  
  allow update: if request.auth != null
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['averagePrice', 'priceUnit', 'updatedAt']);
  
  // Prevent deletion (or restrict to admins)
  allow delete: if false; // or: if request.auth.token.role == 'admin';
}

// User price overrides
match /users/{userId}/ingredient_prices/{priceId} {
  // Users can only access their own overrides
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

---

## Usage Examples

### Initialize Default Price (Automatic)

```dart
// This happens automatically when pantry item is added
// No manual call needed
```

### Get Price for Recipe Calculation

```dart
final priceService = IngredientPriceService();

// Get price with user override
final price = await priceService.getUserIngredientPrice(
  'ingredient123',
  'user456',
);

if (price != null) {
  final effectivePrice = price.effectivePrice; // Uses override if set
  // Use for cost calculation
}
```

### Set User Override Price

```dart
final priceService = IngredientPriceService();

// User sets their price for tomatoes
await priceService.setUserOverridePrice(
  userId: 'user123',
  canonicalIngredientId: 'tomato123',
  overridePrice: 2.50, // $2.50 per piece
);
```

### Batch Get Prices

```dart
final priceService = IngredientPriceService();

// Get prices for multiple ingredients
final ingredientIds = ['ingredient1', 'ingredient2', 'ingredient3'];
final prices = await priceService.getIngredientPrices(ingredientIds);

// prices is a Map<String, IngredientPrice>
for (final entry in prices.entries) {
  final ingredientId = entry.key;
  final price = entry.value;
  // Use price.effectivePrice
}
```

---

## Future Dynamic Pricing Support

The architecture is designed to support future dynamic pricing:

### Extension Points

1. **Price Source Abstraction**:
   ```dart
   abstract class PriceSource {
     Future<double?> getPrice(String canonicalIngredientId);
   }
   ```

2. **Price Aggregation**:
   ```dart
   class PriceAggregationService {
     Future<double> aggregatePrices(
       String canonicalIngredientId,
       List<PriceSource> sources,
     );
   }
   ```

3. **Automatic Updates**:
   - Cloud Functions can update `averagePrice` periodically
   - User submissions can contribute to averages
   - Regional pricing can be added as separate collections

### Current State

- **Manual entry**: Prices set manually
- **User overrides**: Users can override global prices
- **Ready for extension**: Service pattern allows easy extension

---

**Implementation Date:** January 26, 2026  
**Status:** ✅ Complete
