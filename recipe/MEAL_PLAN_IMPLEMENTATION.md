# Weekly Meal Planning with Cost Estimation - Implementation

## Overview

Complete implementation of weekly meal planning with breakfast/lunch/dinner slots, cost estimation, and shopping list generation.

---

## ✅ Implementation Status

### Completed Components

1. **✅ Enhanced MealPlan Model** (`lib/models/meal_plan_model.dart`)
   - Added `dailyMeals` structure: `day -> mealType -> recipeId`
   - Supports breakfast, lunch, dinner slots
   - Backward compatible with `dailyRecipes`
   - Helper methods: `getRecipeForMeal()`, `setRecipeForMeal()`

2. **✅ Enhanced MealPlanCostService** (`lib/services/meal_plan_cost_service.dart`)
   - Calculates missing ingredient cost
   - Calculates daily costs from meal slots
   - Integrates with pantry analytics

3. **✅ Shopping List Generation** (`lib/services/firestore/firestore_service.dart`)
   - `generateShoppingListFromMealPlan()` method
   - Aggregates ingredients from all recipes
   - Creates consolidated shopping list

4. **✅ Meal Plan Screen** (`lib/features/meal_plan/presentation/screens/meal_plan_screen.dart`)
   - Monday-Sunday calendar view
   - Cost display (weekly, per day, missing ingredients)
   - Recipe assignment (existing implementation)

---

## Data Model Structure

### MealPlan Model

```dart
class MealPlan {
  final String id;
  final String userId;
  final DateTime weekStartDate;
  final Map<String, List<String>> dailyRecipes; // Legacy support
  final Map<String, Map<String, String?>> dailyMeals; // New structure
  // dailyMeals structure:
  // {
  //   'monday': {
  //     'breakfast': 'recipeId1',
  //     'lunch': 'recipeId2',
  //     'dinner': 'recipeId3'
  //   },
  //   ...
  // }
}
```

### Meal Types

- `'breakfast'` - Breakfast slot
- `'lunch'` - Lunch slot
- `'dinner'` - Dinner slot

### Day Keys

- `'monday'`, `'tuesday'`, `'wednesday'`, `'thursday'`, `'friday'`, `'saturday'`, `'sunday'`

---

## Cost Calculation

### Weekly Cost

```
totalWeeklyCost = Σ(recipeCost for all recipes in meal plan)
```

### Cost per Day

```
costPerDay = totalWeeklyCost / numberOfDaysWithMeals
```

### Missing Ingredient Cost

```
missingIngredientCost = Σ(missingQuantity × ingredientPrice)
```

**Calculation Steps:**
1. Aggregate required ingredients from all recipes
2. Compare with pantry items
3. Calculate missing quantities
4. Multiply by ingredient prices
5. Sum all missing ingredient costs

### Daily Costs

Calculated from meal slots:
- Sum costs of all recipes assigned to each day
- Includes breakfast, lunch, and dinner recipes

---

## Shopping List Generation

### Method: `generateShoppingListFromMealPlan()`

**Process:**
1. Fetch all recipes from meal plan
2. Aggregate ingredients from all recipes
3. Compare with pantry items
4. Create shopping list with missing ingredients
5. Aggregate quantities for duplicate ingredients

**Features:**
- Consolidates duplicate ingredients
- Generates purchase links
- Creates named shopping list with week dates

---

## UI Structure

### Meal Plan Screen Layout

1. **Week Navigation Header**
   - Previous/Next week buttons
   - Week date range display

2. **Cost Summary Card**
   - Total weekly cost
   - Cost per day
   - Missing ingredient cost
   - Loading indicator

3. **Weekly Calendar**
   - Monday through Sunday cards
   - Each day shows:
     - Day name and date
     - Day cost badge
     - Meal slots (breakfast/lunch/dinner)
     - Add recipe buttons

4. **Actions**
   - Generate shopping list button
   - Save meal plan (auto-save)

---

## Meal Slot Assignment

### Current Implementation

The existing `meal_plan_screen.dart` supports recipe assignment per day. To add meal type slots:

1. **Update `_addRecipeToDay()` method:**
   - Add meal type parameter
   - Use `setRecipeForMeal()` instead of adding to list

2. **Update `_buildDayCard()` method:**
   - Show three meal slots (breakfast/lunch/dinner)
   - Display assigned recipe for each slot
   - Add "Add Recipe" buttons per slot

3. **Update recipe display:**
   - Show recipe in appropriate meal slot
   - Allow removal from specific slot

---

## Integration Points

### 1. Meal Plan Service

**Location:** `lib/services/meal_plan_service.dart`

**Methods:**
- `getMealPlanForWeek()` - Get meal plan for specific week
- `saveMealPlan()` - Save/update meal plan
- `streamMealPlans()` - Stream meal plans

### 2. Cost Service

**Location:** `lib/services/meal_plan_cost_service.dart`

**Methods:**
- `calculateMealPlanCost()` - Calculate all costs

### 3. Shopping List Generation

**Location:** `lib/services/firestore/firestore_service.dart`

**Methods:**
- `generateShoppingListFromMealPlan()` - Generate consolidated list

### 4. Providers

**Location:** `lib/providers/phase2_providers.dart`

**Providers:**
- `mealPlanServiceProvider`
- `mealPlanCostServiceProvider`

---

## Cost Display

### Cost Summary Widget

**Displays:**
- **Total Weekly Cost**: Sum of all recipe costs
- **Cost per Day**: Average daily cost
- **Missing Ingredient Cost**: Cost to purchase missing items

**Layout:**
- Card with icon and title
- Three cost metrics in row
- Loading indicator during calculation

---

## Shopping List Generation

### Button Placement

Add "Generate Shopping List" button:
- In cost summary card
- Or as floating action button
- Or in app bar actions

### Implementation

```dart
Future<void> _generateShoppingList() async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null || _currentMealPlan == null) return;

  try {
    final pantryItems = await firestoreService.getPantryItems(userId);
    final listId = await firestoreService.generateShoppingListFromMealPlan(
      userId: userId,
      mealPlan: _currentMealPlan!,
      pantryItems: pantryItems,
    );
    
    // Navigate to shopping list or show success
    context.push(Routes.shoppingList, extra: listId);
  } catch (e) {
    // Show error
  }
}
```

---

## Backward Compatibility

### Legacy Support

The model maintains backward compatibility:
- `dailyRecipes` field still exists
- `allRecipeIds` getter includes both structures
- Cost calculation works with both

### Migration

Existing meal plans continue to work:
- Old structure: `dailyRecipes` (list of recipe IDs per day)
- New structure: `dailyMeals` (meal type -> recipe ID per day)

---

## Rules Compliance

### ✅ No Payments

- Cost estimation only
- No payment processing
- No checkout flows

### ✅ No Subscriptions

- All features available to all users
- No premium tiers
- No subscription checks

---

## Files Modified/Created

### Modified
- `lib/models/meal_plan_model.dart` - Added meal slots structure
- `lib/services/meal_plan_cost_service.dart` - Enhanced cost calculation
- `lib/services/firestore/firestore_service.dart` - Added shopping list generation
- `lib/providers/phase2_providers.dart` - Updated providers

### Created
- `MEAL_PLAN_IMPLEMENTATION.md` - This documentation

---

## Next Steps (UI Enhancements)

### To Complete Meal Slot UI:

1. **Update `_buildDayCard()` method:**
   ```dart
   Widget _buildDayCard(BuildContext context, String dayKey, bool isTablet) {
     // Show three meal slots
     return Column(
       children: [
         _buildMealSlot(dayKey, 'breakfast'),
         _buildMealSlot(dayKey, 'lunch'),
         _buildMealSlot(dayKey, 'dinner'),
       ],
     );
   }
   ```

2. **Add `_buildMealSlot()` method:**
   ```dart
   Widget _buildMealSlot(String dayKey, String mealType) {
     final recipeId = _currentMealPlan?.getRecipeForMeal(dayKey, mealType);
     // Display recipe or "Add Recipe" button
   }
   ```

3. **Update `_addRecipeToDay()` to include meal type:**
   ```dart
   Future<void> _addRecipeToDay(String dayKey, String mealType) async {
     // Use setRecipeForMeal() instead
   }
   ```

---

## Usage Examples

### Assign Recipe to Meal Slot

```dart
final mealPlan = currentMealPlan.setRecipeForMeal(
  'monday',
  'breakfast',
  recipeId,
);
await mealPlanService.saveMealPlan(mealPlan);
```

### Get Recipe for Meal

```dart
final recipeId = mealPlan.getRecipeForMeal('monday', 'breakfast');
```

### Calculate Costs

```dart
final costService = ref.read(mealPlanCostServiceProvider);
final calculation = await costService.calculateMealPlanCost(
  mealPlan,
  userId,
);
print('Weekly Cost: \$${calculation.totalWeeklyCost}');
print('Missing Ingredients: \$${calculation.missingIngredientCost}');
```

### Generate Shopping List

```dart
final listId = await firestoreService.generateShoppingListFromMealPlan(
  userId: userId,
  mealPlan: mealPlan,
  pantryItems: pantryItems,
);
```

---

**Implementation Date:** January 26, 2026  
**Status:** ✅ Core Implementation Complete  
**UI Enhancement:** ⏳ Meal Slot UI Pending
