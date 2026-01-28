# Canonical Ingredient System - Migration Strategy

## Overview

This document outlines the migration strategy for implementing the Canonical Ingredient System across existing data in Firestore. The goal is to ensure all pantry items, recipe ingredients, and shopping list items reference canonical ingredients via `canonicalIngredientId`.

---

## Migration Goals

1. **Create canonical ingredients** for all unique ingredient names in the database
2. **Backfill `canonicalIngredientId`** in:
   - Pantry items
   - Recipe ingredients
   - Shopping list items
3. **Ensure consistency:** An ingredient marked as available must NEVER appear as missing elsewhere
4. **Preserve data integrity:** No data loss during migration

---

## Pre-Migration Checklist

- [ ] Backup Firestore database
- [ ] Review existing ingredient names for duplicates/variations
- [ ] Test migration script on a small subset of data
- [ ] Verify normalization logic handles all edge cases
- [ ] Ensure Firestore indexes are created
- [ ] Set up monitoring for migration progress

---

## Migration Phases

### Phase 1: Analysis & Preparation

**Duration:** 1-2 hours

#### Step 1.1: Extract All Unique Ingredient Names

```dart
// Pseudo-code for analysis
Future<Map<String, int>> analyzeIngredientNames() async {
  final nameCounts = <String, int>{};
  
  // From pantry items
  final pantryItems = await getAllPantryItems();
  for (final item in pantryItems) {
    final normalized = CanonicalIngredient.normalize(item.name);
    nameCounts[normalized] = (nameCounts[normalized] ?? 0) + 1;
  }
  
  // From recipe ingredients
  final recipes = await getAllRecipes();
  for (final recipe in recipes) {
    for (final ingredient in recipe.ingredients) {
      final normalized = CanonicalIngredient.normalize(ingredient.name);
      nameCounts[normalized] = (nameCounts[normalized] ?? 0) + 1;
    }
  }
  
  // From shopping list items
  final shoppingLists = await getAllShoppingLists();
  for (final list in shoppingLists) {
    for (final item in list.items) {
      final normalized = CanonicalIngredient.normalize(item.name);
      nameCounts[normalized] = (nameCounts[normalized] ?? 0) + 1;
    }
  }
  
  return nameCounts;
}
```

**Output:** List of unique normalized ingredient names with occurrence counts

#### Step 1.2: Identify Duplicates and Variations

- Group similar names (e.g., "tomato" vs "tomatoes")
- Identify potential synonyms
- Create mapping of variations to primary names

#### Step 1.3: Create Synonym Dictionary (Optional)

Manually review and create a synonym mapping:

```dart
final synonymMap = {
  'tomatoes': 'tomato',
  'tomate': 'tomato',
  'jitomate': 'tomato',
  'onions': 'onion',
  'cebollas': 'cebolla',
  // ... more mappings
};
```

---

### Phase 2: Create Canonical Ingredients

**Duration:** 30 minutes - 2 hours (depending on data size)

#### Step 2.1: Create Canonical Ingredients Script

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/services/canonical_ingredient_service.dart';
import 'lib/core/utils/logger.dart';

/// Migration script to create canonical ingredients
Future<void> createCanonicalIngredients() async {
  final service = CanonicalIngredientService();
  final nameCounts = await analyzeIngredientNames();
  
  int created = 0;
  int skipped = 0;
  int errors = 0;
  
  for (final entry in nameCounts.entries) {
    final normalizedName = entry.key;
    final count = entry.value;
    
    try {
      // Check if canonical ingredient already exists
      final existing = await service.findCanonicalIngredientByName(normalizedName);
      
      if (existing != null) {
        Logger.info('Skipping existing: $normalizedName', 'Migration');
        skipped++;
        continue;
      }
      
      // Create new canonical ingredient
      final canonicalId = await service.createOrGetCanonicalIngredient(
        name: normalizedName,
        synonyms: _getSynonyms(normalizedName), // Optional: from synonym map
        category: _inferCategory(normalizedName), // Optional: infer from name
        defaultUnit: _inferDefaultUnit(normalizedName), // Optional: infer from name
      );
      
      Logger.success('Created canonical ingredient: $normalizedName (id: $canonicalId, occurrences: $count)', 'Migration');
      created++;
      
      // Rate limiting: avoid Firestore quota limits
      await Future.delayed(Duration(milliseconds: 100));
      
    } catch (e) {
      Logger.error('Failed to create canonical ingredient: $normalizedName', e, null, 'Migration');
      errors++;
    }
  }
  
  Logger.info('Migration complete: Created=$created, Skipped=$skipped, Errors=$errors', 'Migration');
}

/// Helper: Get synonyms for a normalized name
List<String> _getSynonyms(String normalizedName) {
  // Return synonyms from synonym map or empty list
  return [];
}

/// Helper: Infer category from name
String? _inferCategory(String normalizedName) {
  // Simple heuristics or return null
  return null;
}

/// Helper: Infer default unit from name
String? _inferDefaultUnit(String normalizedName) {
  // Simple heuristics or return null
  return null;
}
```

#### Step 2.2: Execute Script

```bash
# Run migration script
dart run scripts/migrate_canonical_ingredients.dart
```

**Expected Output:**
- All unique ingredient names have corresponding canonical ingredients
- No duplicates (same normalized name)
- Synonyms populated where applicable

---

### Phase 3: Backfill Pantry Items

**Duration:** 30 minutes - 1 hour

#### Step 3.1: Update Pantry Items Script

```dart
/// Migration script to backfill canonicalIngredientId in pantry items
Future<void> backfillPantryItems() async {
  final firestore = FirebaseFirestore.instance;
  final canonicalService = CanonicalIngredientService();
  
  // Get all users
  final usersSnapshot = await firestore.collection('users').get();
  
  int updated = 0;
  int skipped = 0;
  int errors = 0;
  
  for (final userDoc in usersSnapshot.docs) {
    final userId = userDoc.id;
    
    // Get all pantry items for this user
    final pantrySnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('pantry_items')
        .get();
    
    final batch = firestore.batch();
    int batchCount = 0;
    
    for (final itemDoc in pantrySnapshot.docs) {
      try {
        final data = itemDoc.data();
        final itemName = data['name'] as String? ?? '';
        
        // Skip if already has canonicalIngredientId
        if (data['canonicalIngredientId'] != null) {
          skipped++;
          continue;
        }
        
        // Find or create canonical ingredient
        final canonical = await canonicalService.findCanonicalIngredientByName(itemName);
        if (canonical == null) {
          // Create if not found
          final canonicalId = await canonicalService.createOrGetCanonicalIngredient(
            name: itemName,
          );
          batch.update(itemDoc.reference, {
            'canonicalIngredientId': canonicalId,
          });
        } else {
          batch.update(itemDoc.reference, {
            'canonicalIngredientId': canonical.id,
          });
        }
        
        batchCount++;
        updated++;
        
        // Firestore batch limit is 500
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
          Logger.info('Committed batch for user: $userId', 'Migration');
        }
        
      } catch (e) {
        Logger.error('Failed to update pantry item: ${itemDoc.id}', e, null, 'Migration');
        errors++;
      }
    }
    
    // Commit remaining batch
    if (batchCount > 0) {
      await batch.commit();
    }
    
    Logger.info('Updated pantry items for user: $userId (Updated=$updated, Skipped=$skipped, Errors=$errors)', 'Migration');
  }
  
  Logger.success('Pantry items migration complete: Updated=$updated, Skipped=$skipped, Errors=$errors', 'Migration');
}
```

#### Step 3.2: Execute Script

```bash
dart run scripts/migrate_pantry_items.dart
```

---

### Phase 4: Backfill Recipe Ingredients

**Duration:** 1-2 hours (depending on recipe count)

#### Step 4.1: Update Recipe Ingredients Script

```dart
/// Migration script to backfill canonicalIngredientId in recipe ingredients
Future<void> backfillRecipeIngredients() async {
  final firestore = FirebaseFirestore.instance;
  final canonicalService = CanonicalIngredientService();
  
  final recipesSnapshot = await firestore.collection('recipes').get();
  
  int updated = 0;
  int skipped = 0;
  int errors = 0;
  
  for (final recipeDoc in recipesSnapshot.docs) {
    try {
      final data = recipeDoc.data();
      final ingredients = (data['ingredients'] as List<dynamic>?) ?? [];
      
      bool hasChanges = false;
      final updatedIngredients = <Map<String, dynamic>>[];
      
      for (final ingredientData in ingredients) {
        final ingredientMap = Map<String, dynamic>.from(ingredientData);
        final ingredientName = ingredientMap['name'] as String? ?? '';
        
        // Skip if already has canonicalIngredientId
        if (ingredientMap['canonicalIngredientId'] != null) {
          updatedIngredients.add(ingredientMap);
          continue;
        }
        
        // Find or create canonical ingredient
        final canonical = await canonicalService.findCanonicalIngredientByName(ingredientName);
        if (canonical == null) {
          final canonicalId = await canonicalService.createOrGetCanonicalIngredient(
            name: ingredientName,
          );
          ingredientMap['canonicalIngredientId'] = canonicalId;
        } else {
          ingredientMap['canonicalIngredientId'] = canonical.id;
        }
        
        updatedIngredients.add(ingredientMap);
        hasChanges = true;
        updated++;
      }
      
      // Update recipe if changes were made
      if (hasChanges) {
        await recipeDoc.reference.update({
          'ingredients': updatedIngredients,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        Logger.info('Updated recipe: ${recipeDoc.id} (${updatedIngredients.length} ingredients)', 'Migration');
      } else {
        skipped++;
      }
      
      // Rate limiting
      await Future.delayed(Duration(milliseconds: 50));
      
    } catch (e) {
      Logger.error('Failed to update recipe: ${recipeDoc.id}', e, null, 'Migration');
      errors++;
    }
  }
  
  Logger.success('Recipe ingredients migration complete: Updated=$updated, Skipped=$skipped, Errors=$errors', 'Migration');
}
```

#### Step 4.2: Execute Script

```bash
dart run scripts/migrate_recipe_ingredients.dart
```

---

### Phase 5: Backfill Shopping List Items

**Duration:** 30 minutes - 1 hour

#### Step 5.1: Update Shopping List Items Script

```dart
/// Migration script to backfill canonicalIngredientId in shopping list items
Future<void> backfillShoppingListItems() async {
  final firestore = FirebaseFirestore.instance;
  final canonicalService = CanonicalIngredientService();
  
  final usersSnapshot = await firestore.collection('users').get();
  
  int updated = 0;
  int skipped = 0;
  int errors = 0;
  
  for (final userDoc in usersSnapshot.docs) {
    final userId = userDoc.id;
    
    // Get all shopping lists for this user
    final listsSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('shopping_lists')
        .get();
    
    for (final listDoc in listsSnapshot.docs) {
      final listId = listDoc.id;
      
      // Get all items in this shopping list
      final itemsSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .get();
      
      final batch = firestore.batch();
      int batchCount = 0;
      
      for (final itemDoc in itemsSnapshot.docs) {
        try {
          final data = itemDoc.data();
          final itemName = data['name'] as String? ?? '';
          
          // Skip if already has canonicalIngredientId
          if (data['canonicalIngredientId'] != null) {
            skipped++;
            continue;
          }
          
          // Find or create canonical ingredient
          final canonical = await canonicalService.findCanonicalIngredientByName(itemName);
          if (canonical == null) {
            final canonicalId = await canonicalService.createOrGetCanonicalIngredient(
              name: itemName,
            );
            batch.update(itemDoc.reference, {
              'canonicalIngredientId': canonicalId,
            });
          } else {
            batch.update(itemDoc.reference, {
              'canonicalIngredientId': canonical.id,
            });
          }
          
          batchCount++;
          updated++;
          
          // Firestore batch limit is 500
          if (batchCount >= 500) {
            await batch.commit();
            batchCount = 0;
          }
          
        } catch (e) {
          Logger.error('Failed to update shopping list item: ${itemDoc.id}', e, null, 'Migration');
          errors++;
        }
      }
      
      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit();
      }
    }
  }
  
  Logger.success('Shopping list items migration complete: Updated=$updated, Skipped=$skipped, Errors=$errors', 'Migration');
}
```

#### Step 5.2: Execute Script

```bash
dart run scripts/migrate_shopping_list_items.dart
```

---

## Post-Migration Validation

### Step 1: Verify Data Consistency

```dart
/// Validation script to check migration success
Future<void> validateMigration() async {
  final firestore = FirebaseFirestore.instance;
  final canonicalService = CanonicalIngredientService();
  
  int pantryWithoutId = 0;
  int recipeIngredientWithoutId = 0;
  int shoppingItemWithoutId = 0;
  int invalidReferences = 0;
  
  // Check pantry items
  final usersSnapshot = await firestore.collection('users').get();
  for (final userDoc in usersSnapshot.docs) {
    final pantrySnapshot = await firestore
        .collection('users')
        .doc(userDoc.id)
        .collection('pantry_items')
        .get();
    
    for (final itemDoc in pantrySnapshot.docs) {
      final data = itemDoc.data();
      final canonicalId = data['canonicalIngredientId'] as String?;
      
      if (canonicalId == null || canonicalId.isEmpty) {
        pantryWithoutId++;
      } else {
        // Verify reference exists
        final canonical = await canonicalService.getCanonicalIngredient(canonicalId);
        if (canonical == null) {
          invalidReferences++;
        }
      }
    }
  }
  
  // Check recipe ingredients
  final recipesSnapshot = await firestore.collection('recipes').get();
  for (final recipeDoc in recipesSnapshot.docs) {
    final ingredients = (recipeDoc.data()['ingredients'] as List<dynamic>?) ?? [];
    for (final ingredient in ingredients) {
      final ingredientMap = Map<String, dynamic>.from(ingredient);
      final canonicalId = ingredientMap['canonicalIngredientId'] as String?;
      
      if (canonicalId == null || canonicalId.isEmpty) {
        recipeIngredientWithoutId++;
      } else {
        final canonical = await canonicalService.getCanonicalIngredient(canonicalId);
        if (canonical == null) {
          invalidReferences++;
        }
      }
    }
  }
  
  // Check shopping list items
  for (final userDoc in usersSnapshot.docs) {
    final listsSnapshot = await firestore
        .collection('users')
        .doc(userDoc.id)
        .collection('shopping_lists')
        .get();
    
    for (final listDoc in listsSnapshot.docs) {
      final itemsSnapshot = await firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('shopping_lists')
          .doc(listDoc.id)
          .collection('items')
          .get();
      
      for (final itemDoc in itemsSnapshot.docs) {
        final data = itemDoc.data();
        final canonicalId = data['canonicalIngredientId'] as String?;
        
        if (canonicalId == null || canonicalId.isEmpty) {
          shoppingItemWithoutId++;
        } else {
          final canonical = await canonicalService.getCanonicalIngredient(canonicalId);
          if (canonical == null) {
            invalidReferences++;
          }
        }
      }
    }
  }
  
  Logger.info('Validation Results:', 'Migration');
  Logger.info('  Pantry items without ID: $pantryWithoutId', 'Migration');
  Logger.info('  Recipe ingredients without ID: $recipeIngredientWithoutId', 'Migration');
  Logger.info('  Shopping items without ID: $shoppingItemWithoutId', 'Migration');
  Logger.info('  Invalid references: $invalidReferences', 'Migration');
  
  if (pantryWithoutId == 0 && recipeIngredientWithoutId == 0 && 
      shoppingItemWithoutId == 0 && invalidReferences == 0) {
    Logger.success('Migration validation PASSED', 'Migration');
  } else {
    Logger.warning('Migration validation found issues', 'Migration');
  }
}
```

### Step 2: Test Availability Consistency Rule

```dart
/// Test: An ingredient marked as available must NEVER appear as missing elsewhere
Future<void> testAvailabilityConsistency() async {
  final firestore = FirebaseFirestore.instance;
  
  // Get all users
  final usersSnapshot = await firestore.collection('users').get();
  
  for (final userDoc in usersSnapshot.docs) {
    final userId = userDoc.id;
    
    // Get all pantry items with canonical IDs
    final pantrySnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('pantry_items')
        .where('canonicalIngredientId', isNotEqualTo: null)
        .where('quantity', isGreaterThan: 0)
        .get();
    
    final availableCanonicalIds = pantrySnapshot.docs
        .map((doc) => doc.data()['canonicalIngredientId'] as String)
        .toSet();
    
    // Get all shopping list items
    final listsSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('shopping_lists')
        .get();
    
    for (final listDoc in listsSnapshot.docs) {
      final itemsSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('shopping_lists')
          .doc(listDoc.id)
          .collection('items')
          .get();
      
      for (final itemDoc in itemsSnapshot.docs) {
        final canonicalId = itemDoc.data()['canonicalIngredientId'] as String?;
        
        if (canonicalId != null && availableCanonicalIds.contains(canonicalId)) {
          Logger.warning(
            'VIOLATION: Ingredient $canonicalId is in pantry but also in shopping list ${listDoc.id}',
            'Migration',
          );
        }
      }
    }
  }
}
```

---

## Rollback Plan

If migration fails or causes issues:

1. **Stop migration script** immediately
2. **Restore from backup** if data corruption occurred
3. **Review logs** to identify failure points
4. **Fix issues** in migration script
5. **Re-run migration** on corrected script

### Partial Rollback

If only some data was migrated:

```dart
/// Remove canonicalIngredientId from all documents (use with caution)
Future<void> rollbackCanonicalIds() async {
  // Only use if absolutely necessary
  // This will remove all canonicalIngredientId references
  // Consider backing up first
}
```

---

## Monitoring & Metrics

### Key Metrics to Track

1. **Migration Progress:**
   - Total items to migrate
   - Items migrated
   - Items skipped
   - Errors encountered

2. **Performance:**
   - Migration duration
   - Firestore read/write operations
   - Error rate

3. **Data Quality:**
   - Percentage of items with canonical IDs
   - Invalid references count
   - Availability consistency violations

### Logging

All migration scripts should log:
- Progress updates (every 100 items)
- Errors with full stack traces
- Summary statistics
- Timing information

---

## Best Practices

1. **Run during low-traffic periods** to minimize impact
2. **Test on staging first** before production
3. **Monitor Firestore quotas** (reads/writes per day)
4. **Use batch operations** to reduce write costs
5. **Implement rate limiting** to avoid quota limits
6. **Validate after each phase** before proceeding
7. **Keep backups** at each phase
8. **Document any manual interventions** required

---

## Estimated Timeline

| Phase | Duration | Notes |
|-------|----------|-------|
| Phase 1: Analysis | 1-2 hours | One-time analysis |
| Phase 2: Create Canonical | 30 min - 2 hours | Depends on unique names |
| Phase 3: Pantry Items | 30 min - 1 hour | Depends on pantry size |
| Phase 4: Recipe Ingredients | 1-2 hours | Depends on recipe count |
| Phase 5: Shopping Lists | 30 min - 1 hour | Depends on list count |
| Validation | 30 minutes | Verification |
| **Total** | **4-8 hours** | For typical database |

---

## Success Criteria

✅ All pantry items have `canonicalIngredientId`  
✅ All recipe ingredients have `canonicalIngredientId`  
✅ All shopping list items have `canonicalIngredientId`  
✅ No invalid references (all IDs point to existing canonical ingredients)  
✅ Availability consistency rule validated  
✅ No data loss or corruption  
✅ Application continues to function normally  

---

**Last Updated:** January 26, 2026
