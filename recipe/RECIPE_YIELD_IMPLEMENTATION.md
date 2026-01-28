# Recipe Yield & Portion System - Implementation

## Overview

Complete implementation of yield and portion logic for recipes, enabling accurate serving calculations and cost per serving.

---

## ✅ Implementation Status

### Completed Components

1. **✅ Recipe Model Extensions** (`lib/models/recipe_model.dart`)
   - `yieldValue` (totalYield) - Total yield of the recipe
   - `yieldUnit` - Unit for yield (grams, liters, cups, pieces)
   - `standardPortionSize` (portionSize) - Standard portion size
   - Getters: `totalYield`, `portionSize`, `numberOfServings`
   - Validation: `hasValidYield`
   - Formatting: `formattedYield`, `formattedPortionSize`

2. **✅ Calculation Helpers** (`lib/utils/recipe_yield_helper.dart`)
   - `calculateServings()` - Calculate number of servings
   - `calculateCostPerServing()` - Calculate cost per serving
   - `validateYield()` - Validate yield configuration
   - `formatYield()` / `formatPortionSize()` - Format display strings
   - `getDefaultPortionSize()` - Suggest default portion sizes
   - `hasCompleteYield()` - Check if recipe has complete yield info

3. **✅ Validation Logic** (`lib/core/utils/validators.dart`)
   - `validateYieldValue()` - Validate total yield
   - `validatePortionSize()` - Validate portion size
   - `validateYieldUnit()` - Validate yield unit

4. **✅ Cost Calculation Integration** (`lib/services/recipe_cost_service.dart`)
   - Cost per serving calculation using yield and portion size
   - Fallback to number of servings if yield not available
   - Integrated with existing cost calculation

---

## Recipe Model Fields

### Required Fields (for yield calculations)

| Field | Type | Description | Alias |
|-------|------|-------------|-------|
| `yieldValue` | `double?` | Total yield value | `totalYield` |
| `yieldUnit` | `String?` | Unit for yield | - |
| `standardPortionSize` | `double?` | Standard portion size | `portionSize` |

### Calculated Properties

- **`numberOfServings`** (int?): Calculated as `totalYield / portionSize`
- **`hasValidYield`** (bool): Validates yield configuration
- **`formattedYield`** (String?): Formatted display string (e.g., "500 grams")
- **`formattedPortionSize`** (String?): Formatted display string (e.g., "125 grams")

---

## Calculation Formulas

### Number of Servings

```
numberOfServings = round(totalYield / portionSize)
```

**Example:**
- Total Yield: 500 grams
- Portion Size: 125 grams
- Servings: 500 / 125 = 4 servings

### Cost per Serving

**Method 1 (Preferred): Using yield and portion size**
```
costPerServing = (totalCost / totalYield) * portionSize
```

**Method 2 (Fallback): Using number of servings**
```
costPerServing = totalCost / numberOfServings
```

**Example:**
- Total Cost: $10.00
- Total Yield: 500 grams
- Portion Size: 125 grams
- Cost per Serving: ($10.00 / 500) * 125 = $2.50 per serving

---

## Validation Rules

### Yield Value Validation

- **Optional**: Can be null (for backward compatibility)
- **If provided**: Must be > 0
- **Type**: Must be a valid number

### Portion Size Validation

- **Optional**: Can be null (for backward compatibility)
- **If provided**: Must be > 0
- **Constraint**: Cannot exceed total yield
- **Type**: Must be a valid number

### Yield Unit Validation

- **Optional**: Can be null (for backward compatibility)
- **If provided**: Must be one of: `grams`, `kilograms`, `liters`, `milliliters`, `cups`, `pieces`
- **Case-sensitive**: Must match exact values

### Complete Yield Validation

A recipe has valid yield if:
1. `yieldValue` is not null and > 0
2. `yieldUnit` is not null and not empty
3. `standardPortionSize` is not null and > 0
4. `standardPortionSize` <= `yieldValue`

---

## Backward Compatibility

### Existing Recipes

- **No yield data**: Recipes without yield fields continue to work
- **Partial yield data**: Recipes with only some yield fields work (calculations skip missing data)
- **Null handling**: All calculations handle null values gracefully

### Migration Strategy

1. **Existing recipes**: Continue to function without yield data
2. **New recipes**: Should include yield data for accurate calculations
3. **Gradual migration**: Users can add yield data to existing recipes over time

---

## Usage Examples

### Creating a Recipe with Yield

```dart
final recipe = Recipe(
  id: 'recipe123',
  title: 'Pasta Carbonara',
  ingredients: [...],
  instructions: [...],
  cookTime: 30,
  authorId: 'user123',
  yieldValue: 500.0,        // Total yield: 500 grams
  yieldUnit: 'grams',       // Unit: grams
  standardPortionSize: 125.0, // Portion size: 125 grams
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// Calculate servings
final servings = recipe.numberOfServings; // Returns 4

// Check if valid
final isValid = recipe.hasValidYield; // Returns true

// Format for display
final yieldDisplay = recipe.formattedYield; // "500 grams"
final portionDisplay = recipe.formattedPortionSize; // "125 grams"
```

### Calculating Cost per Serving

```dart
final costService = RecipeCostService(...);
final costCalc = await costService.calculateRecipeCost(recipe, userId);

// costCalc.totalCost - Total recipe cost
// costCalc.costPerPortion - Cost per serving
// costCalc.numberOfServings - Number of servings
```

### Using Helper Functions

```dart
// Validate yield configuration
final error = RecipeYieldHelper.validateYield(
  totalYield: 500.0,
  yieldUnit: 'grams',
  portionSize: 125.0,
);
if (error != null) {
  // Show error to user
}

// Calculate servings
final servings = RecipeYieldHelper.calculateServings(
  totalYield: 500.0,
  portionSize: 125.0,
); // Returns 4

// Calculate cost per serving
final costPerServing = RecipeYieldHelper.calculateCostPerServing(
  totalCost: 10.0,
  totalYield: 500.0,
  portionSize: 125.0,
); // Returns 2.5

// Get default portion size
final defaultPortion = RecipeYieldHelper.getDefaultPortionSize(
  yieldUnit: 'grams',
  totalYield: 500.0,
); // Returns 150.0 (typical serving size)
```

### Validation in Forms

```dart
// In recipe form
TextFormField(
  decoration: InputDecoration(labelText: 'Total Yield'),
  keyboardType: TextInputType.number,
  validator: (value) => Validators.validateYieldValue(value),
  onSaved: (value) {
    if (value != null && value.isNotEmpty) {
      yieldValue = double.parse(value);
    }
  },
)

TextFormField(
  decoration: InputDecoration(labelText: 'Portion Size'),
  keyboardType: TextInputType.number,
  validator: (value) => Validators.validatePortionSize(value, yieldValue),
  onSaved: (value) {
    if (value != null && value.isNotEmpty) {
      portionSize = double.parse(value);
    }
  },
)
```

---

## Supported Yield Units

| Unit | Description | Typical Use Cases |
|------|-------------|-------------------|
| `grams` | Weight in grams | Solid ingredients, pasta, rice |
| `kilograms` | Weight in kilograms | Large quantities |
| `liters` | Volume in liters | Soups, sauces, beverages |
| `milliliters` | Volume in milliliters | Small quantities, liquids |
| `cups` | Volume in cups | Baking, US measurements |
| `pieces` | Count of items | Individual servings, portions |

---

## Default Portion Sizes

The system suggests default portion sizes based on yield unit:

| Unit | Default Portion Size |
|------|---------------------|
| `grams` | 150 grams |
| `kilograms` | 0.15 kg (150 grams) |
| `liters` | 0.25 liters (250ml) |
| `milliliters` | 250 milliliters |
| `cups` | 1 cup |
| `pieces` | 1 piece |
| Other | 1/4 of total yield |

---

## Integration with Cost Calculation

### RecipeCostService Integration

The `RecipeCostService` automatically uses yield data when available:

1. **Calculate total cost** from ingredient prices
2. **Calculate cost per serving** using:
   - Primary: `(totalCost / totalYield) * portionSize`
   - Fallback: `totalCost / numberOfServings`
3. **Return cost calculation** with all metrics

### Example Flow

```dart
// Recipe has yield data
final recipe = Recipe(
  yieldValue: 500.0,
  yieldUnit: 'grams',
  standardPortionSize: 125.0,
  // ... other fields
);

// Calculate cost
final costCalc = await recipeCostService.calculateRecipeCost(recipe, userId);

// Results:
// - costCalc.totalCost: $10.00
// - costCalc.costPerPortion: $2.50 (calculated from yield)
// - costCalc.numberOfServings: 4
```

---

## Error Handling

### Missing Yield Data

- **No yield data**: Calculations return `null` for servings and cost per serving
- **Partial yield data**: Calculations use available data, return `null` for incomplete calculations
- **Invalid yield data**: Validation catches errors before calculation

### Calculation Errors

- **Division by zero**: Handled gracefully, returns `null`
- **Invalid units**: Validation prevents invalid unit values
- **Negative values**: Validation prevents negative yield/portion values

---

## Testing Checklist

- [ ] Recipe with complete yield data → Servings calculated correctly
- [ ] Recipe with partial yield data → Graceful handling
- [ ] Recipe without yield data → Backward compatible
- [ ] Cost per serving calculation with yield
- [ ] Cost per serving calculation without yield (fallback)
- [ ] Validation: Invalid yield values
- [ ] Validation: Portion size > total yield
- [ ] Validation: Invalid units
- [ ] Formatting: Yield display strings
- [ ] Formatting: Portion size display strings
- [ ] Default portion size suggestions
- [ ] Number of servings calculation edge cases

---

## Files Modified/Created

### Created
- `lib/utils/recipe_yield_helper.dart` - Calculation and validation helpers

### Modified
- `lib/models/recipe_model.dart` - Added getters, validation, formatting
- `lib/services/recipe_cost_service.dart` - Enhanced cost per serving calculation
- `lib/core/utils/validators.dart` - Added yield validation functions

---

## Firestore Schema

### Recipe Document Fields

```json
{
  "yieldValue": 500.0,           // Optional: Total yield
  "yieldUnit": "grams",          // Optional: Yield unit
  "standardPortionSize": 125.0,  // Optional: Portion size
  // ... other recipe fields
}
```

### Backward Compatibility

- All yield fields are **optional**
- Existing recipes without yield fields continue to work
- New recipes can include yield fields for enhanced calculations

---

## Future Enhancements

1. **Auto-suggest yield**: Suggest yield based on recipe type
2. **Unit conversion**: Convert between yield units
3. **Portion scaling**: Scale recipe to different serving sizes
4. **Yield templates**: Pre-defined yield configurations for common recipe types
5. **Nutrition integration**: (Future) Calculate nutrition per serving

---

**Implementation Date:** January 26, 2026  
**Status:** ✅ Complete
