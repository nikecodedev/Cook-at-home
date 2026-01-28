# Canonical Ingredient System - Implementation Summary

## Overview

The Canonical Ingredient System has been fully implemented to standardize ingredient naming across the application. This ensures consistency and prevents duplicates, enabling accurate matching between pantry items, recipes, and shopping lists.

---

## ✅ Implementation Status

### Completed Components

1. **✅ Data Model** (`lib/models/canonical_ingredient_model.dart`)
   - CanonicalIngredient class with all required fields
   - Normalization logic with accent removal
   - Synonym support
   - Firestore serialization

2. **✅ Service Layer** (`lib/services/canonical_ingredient_service.dart`)
   - CRUD operations
   - Name-based search with synonym matching
   - Automatic normalization

3. **✅ Model Updates**
   - ✅ `PantryItem` - has `canonicalIngredientId` field
   - ✅ `RecipeIngredient` - has `canonicalIngredientId` field
   - ✅ `ShoppingListItem` - has `canonicalIngredientId` field (newly added)

4. **✅ Firestore Service Updates**
   - Shopping list item creation includes `canonicalIngredientId`
   - Shopping list item update supports `canonicalIngredientId`

5. **✅ Normalization Logic**
   - Lowercase conversion
   - Trim whitespace
   - Accent/diacritic removal
   - Whitespace normalization

6. **✅ Documentation**
   - Firestore schema documentation (`CANONICAL_INGREDIENT_SCHEMA.md`)
   - Migration strategy (`CANONICAL_INGREDIENT_MIGRATION.md`)

---

## Key Features

### 1. Normalization

All ingredient names are normalized using:
- **Lowercase:** `"Tomato"` → `"tomato"`
- **Trim:** `"  tomato  "` → `"tomato"`
- **Whitespace:** `"tomato   sauce"` → `"tomato sauce"`
- **Accent Removal:** `"tomáto"` → `"tomato"`, `"cebólla"` → `"cebolla"`

### 2. Synonym Support

Canonical ingredients can have multiple synonyms:
```dart
CanonicalIngredient(
  name: "tomato",
  synonyms: ["tomatoes", "tomate", "jitomate"],
)
```

### 3. Data References

All ingredient references now support `canonicalIngredientId`:
- **PantryItem:** `canonicalIngredientId` (nullable)
- **RecipeIngredient:** `canonicalIngredientId` (nullable)
- **ShoppingListItem:** `canonicalIngredientId` (nullable) ✨ **NEW**

---

## Firestore Collection

### Collection: `canonical_ingredients`

**Path:** `/canonical_ingredients/{ingredientId}`

**Fields:**
- `id` (String) - Document ID
- `name` (String) - Normalized primary name
- `synonyms` (Array<String>) - Alternative names
- `category` (String, nullable) - Optional category
- `defaultUnit` (String, nullable) - Suggested unit
- `createdAt` (Timestamp) - Creation time
- `updatedAt` (Timestamp) - Last update time

See `CANONICAL_INGREDIENT_SCHEMA.md` for complete schema documentation.

---

## Critical Rule: Availability Consistency

**"An ingredient marked as available must NEVER appear as missing elsewhere"**

### Implementation

This rule is enforced through:

1. **Canonical ID Matching:** When checking if an ingredient is available:
   - First check `canonicalIngredientId` if present
   - Fall back to name-based matching if `canonicalIngredientId` is null
   - Use normalized names for comparison

2. **Shopping List Generation:** When generating shopping lists from recipes:
   - Match recipe ingredients to pantry items by `canonicalIngredientId` first
   - If IDs match, ingredient is considered available (even if name differs)
   - Only add to shopping list if no match found

3. **Pantry Matching:** When matching pantry items to recipe ingredients:
   - Check `canonicalIngredientId` for exact match
   - Use synonym matching if IDs don't match
   - Normalize names before comparison

---

## Code Changes Summary

### Files Modified

1. **`lib/models/canonical_ingredient_model.dart`**
   - Enhanced `normalize()` method with accent removal
   - Added `_removeAccents()` helper method

2. **`lib/models/shopping_list_model.dart`**
   - Added `canonicalIngredientId` field to `ShoppingListItem`
   - Updated `fromFirestore()`, `fromMap()`, `toMap()`, and `copyWith()` methods

3. **`lib/services/firestore/firestore_service.dart`**
   - Updated `generateShoppingList()` to include `canonicalIngredientId` when creating items
   - Updated `updateShoppingItem()` to support `canonicalIngredientId` parameter

### Files Created

1. **`CANONICAL_INGREDIENT_SCHEMA.md`** - Complete Firestore schema documentation
2. **`CANONICAL_INGREDIENT_MIGRATION.md`** - Detailed migration strategy

---

## Usage Examples

### Creating a Canonical Ingredient

```dart
final service = CanonicalIngredientService();

// Create or get canonical ingredient
final canonicalId = await service.createOrGetCanonicalIngredient(
  name: "tomato",
  synonyms: ["tomatoes", "tomate"],
  category: "Vegetables",
  defaultUnit: "pieces",
);
```

### Finding a Canonical Ingredient

```dart
// Find by name (handles synonyms and normalization)
final canonical = await service.findCanonicalIngredientByName("Tomatoes");
if (canonical != null) {
  print("Found: ${canonical.name} (ID: ${canonical.id})");
}
```

### Normalizing a Name

```dart
// Normalize any ingredient name
final normalized = CanonicalIngredient.normalize("Tomáto");
// Result: "tomato"
```

### Using in Pantry Items

```dart
final pantryItem = PantryItem(
  id: "item123",
  name: "Fresh Tomatoes",
  canonicalIngredientId: canonicalId, // Reference to canonical
  quantity: 5.0,
  unit: "pieces",
  category: "Vegetables",
  addedAt: DateTime.now(),
);
```

### Using in Recipe Ingredients

```dart
final ingredient = RecipeIngredient(
  name: "Tomatoes",
  canonicalIngredientId: canonicalId, // Reference to canonical
  quantity: 2.0,
  unit: "pieces",
);
```

### Using in Shopping List Items

```dart
final shoppingItem = ShoppingListItem(
  id: "item456",
  name: "Tomatoes",
  canonicalIngredientId: canonicalId, // Reference to canonical
  quantity: 2.0,
  unit: "pieces",
  addedAt: DateTime.now(),
);
```

---

## Migration Required

⚠️ **Important:** Existing data in Firestore needs to be migrated to use canonical ingredients.

### Migration Steps

1. **Create canonical ingredients** for all unique ingredient names
2. **Backfill `canonicalIngredientId`** in:
   - Pantry items
   - Recipe ingredients
   - Shopping list items

See `CANONICAL_INGREDIENT_MIGRATION.md` for:
- Detailed migration scripts
- Step-by-step instructions
- Validation procedures
- Rollback plan

---

## Testing Checklist

- [ ] Test normalization with various inputs (accents, case, whitespace)
- [ ] Test synonym matching
- [ ] Test canonical ingredient creation
- [ ] Test finding canonical ingredients by name
- [ ] Test pantry item with canonical ID
- [ ] Test recipe ingredient with canonical ID
- [ ] Test shopping list item with canonical ID
- [ ] Test availability consistency rule
- [ ] Test migration scripts on sample data

---

## Next Steps

1. **Run Migration:** Execute migration scripts to backfill existing data
2. **Update UI:** Modify UI to use canonical ingredients (future work)
3. **Add Validation:** Ensure new items always get canonical IDs
4. **Monitor:** Track migration progress and validate results

---

## Notes

- **No UI Changes:** This implementation is logic + data model only (as requested)
- **Backward Compatible:** Models support nullable `canonicalIngredientId` for gradual migration
- **Name Fallback:** If `canonicalIngredientId` is null, systems fall back to name-based matching
- **Future Enhancement:** UI can be updated to auto-suggest canonical ingredients when users type ingredient names

---

**Implementation Date:** January 26, 2026  
**Status:** ✅ Complete (Logic + Data Model)
