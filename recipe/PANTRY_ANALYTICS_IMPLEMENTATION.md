# Pantry Analytics - Implementation

## Overview

Complete implementation of pantry analytics with comprehensive metrics, efficiency scoring, and mobile-first visual indicators.

---

## ✅ Implementation Status

### Completed Components

1. **✅ PantryAnalyticsService** (`lib/services/pantry_analytics_service.dart`)
   - Total pantry value calculation
   - Estimated meals available calculation
   - Coverage % based on planned recipes
   - Efficiency score calculation
   - Integration with meal plans

2. **✅ PantryAnalyticsWidget** (`lib/features/pantry/presentation/widgets/pantry_analytics_widget.dart`)
   - Mobile-first responsive design
   - Visual indicators for all metrics
   - Color-coded efficiency and coverage
   - Progress bar for efficiency score

3. **✅ Comprehensive Analytics Model**
   - `PantryAnalytics` class with all metrics
   - Integrated with existing value and coverage metrics

---

## Metrics Implemented

### 1. Total Pantry Estimated Value

**Calculation:**
```
totalValue = Σ(pantryItemQuantity × ingredientPrice)
```

**Details:**
- Uses ingredient prices (with user overrides if available)
- Converts units if needed
- Sums all pantry item values

**Display:**
- Currency formatted (e.g., "$125.50")
- Primary color indicator
- Money icon

### 2. Estimated Meals Available

**Calculation:**
```
estimatedMeals = (coveragePercentage / 100) × plannedRecipesCount
```

**Details:**
- Based on current week's meal plan
- Rounded to nearest integer
- Shows how many meals can be made from pantry

**Display:**
- Integer value
- Secondary color indicator
- Restaurant icon

### 3. Coverage % Based on Planned Recipes

**Calculation:**
```
coveragePercentage = (availableIngredients / requiredIngredients) × 100
```

**Details:**
- Compares pantry items to planned recipe requirements
- Uses canonical ingredient matching
- Accounts for quantities (not just presence)

**Display:**
- Percentage (0-100%)
- Color-coded:
  - Green (≥80%): Excellent
  - Yellow (50-79%): Good
  - Red (<50%): Needs attention
- Check circle icon

### 4. Simple Efficiency Score

**Calculation:**
```
efficiencyScore = (coverageScore × 0.4) + (valueUtilizationScore × 0.3) + (healthScore × 0.3)
```

**Components:**
- **Coverage Score (40% weight)**: Based on coverage percentage
- **Value Utilization Score (30% weight)**: How well pantry value is utilized
- **Health Score (30% weight)**: Based on expired/expiring items

**Health Score Details:**
```
healthScore = ((totalItems - expiredCount - expiringCount × 0.5) / totalItems) × 30
```

**Display:**
- Score out of 100
- Progress bar visualization
- Color-coded:
  - Green (≥80): Excellent
  - Yellow (60-79): Good
  - Red (<60): Needs improvement
- Trending up icon

---

## Efficiency Score Formula

### Components

1. **Coverage Score (40%)**
   - Direct mapping: `coveragePercentage × 0.4`
   - Rewards high coverage of planned recipes

2. **Value Utilization Score (30%)**
   - If coverage ≥ 50%: Full 30 points
   - If coverage < 50%: `(coverage / 50) × 30`
   - Rewards using pantry value effectively

3. **Health Score (30%)**
   - Based on expired and expiring items
   - Formula: `((total - expired - expiring×0.5) / total) × 30`
   - Penalizes waste and poor inventory management

### Example Calculation

**Scenario:**
- Coverage: 75%
- Total items: 20
- Expired: 2
- Expiring soon: 3

**Calculation:**
```
coverageScore = 75 × 0.4 = 30.0
valueUtilizationScore = 30.0 (coverage ≥ 50%)
healthScore = ((20 - 2 - 3×0.5) / 20) × 30 = 24.75
efficiencyScore = 30.0 + 30.0 + 24.75 = 84.75
```

---

## UI Design

### Mobile-First Layout

**Structure:**
1. Header with analytics icon and title
2. 2x2 grid of metric cards:
   - Row 1: Total Value | Meals Available
   - Row 2: Coverage % | Efficiency Score
3. Efficiency progress bar (below grid)

### Visual Indicators

**Metric Cards:**
- White background with colored border
- Icon + label + value
- Responsive sizing
- Subtle shadow for depth

**Color Coding:**
- **Total Value**: Primary color (blue)
- **Meals Available**: Secondary color (purple)
- **Coverage**: Dynamic (green/yellow/red)
- **Efficiency**: Dynamic (green/yellow/red)

**Progress Bar:**
- Linear progress indicator
- Color matches efficiency score
- Shows score out of 100
- Rounded corners

---

## Integration Points

### 1. Meal Plan Integration

**Location:** `lib/services/pantry_analytics_service.dart`

**Behavior:**
- Retrieves current week's meal plan
- Fetches all recipes in the meal plan
- Calculates coverage based on planned recipes
- Falls back gracefully if no meal plan exists

**Code:**
```dart
if (userId != null && _mealPlanService != null && _firestoreService != null) {
  final now = DateTime.now();
  final monday = _getMonday(now);
  final mealPlan = await _mealPlanService!.getMealPlanForWeek(userId, monday);
  // ... fetch recipes and calculate coverage
}
```

### 2. Pantry List Screen

**Location:** `lib/features/pantry/presentation/screens/pantry_list_screen.dart`

**Integration:**
```dart
PantryAnalyticsWidget(pantryItems: items)
```

**Behavior:**
- Only shows when pantry has items
- Automatically calculates all metrics
- Updates when pantry items change

### 3. Provider Integration

**Location:** `lib/providers/phase2_providers.dart`

**Updated Provider:**
```dart
final pantryAnalyticsServiceProvider = Provider<PantryAnalyticsService>((ref) {
  final priceService = ref.watch(ingredientPriceServiceProvider);
  final canonicalService = ref.watch(canonicalIngredientServiceProvider);
  final mealPlanService = ref.watch(mealPlanServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PantryAnalyticsService(
    priceService: priceService,
    canonicalService: canonicalService,
    mealPlanService: mealPlanService,
    firestoreService: firestoreService,
  );
});
```

---

## Data Flow

### Calculation Flow

1. **User opens pantry screen**
   - Widget receives pantry items list

2. **Widget calls `calculateComprehensiveAnalytics()`**
   - Service calculates pantry value
   - Service retrieves current meal plan
   - Service fetches planned recipes
   - Service calculates coverage
   - Service calculates efficiency score

3. **Widget displays results**
   - Shows all metrics in grid layout
   - Color-codes based on values
   - Displays efficiency progress bar

### Error Handling

- **No meal plan**: Coverage defaults to 100%, estimated meals = 0
- **No recipes in meal plan**: Coverage = 100%, estimated meals = 0
- **Missing prices**: Items without prices excluded from value calculation
- **Calculation errors**: Returns default values (0s) and logs error

---

## Performance Considerations

### Optimizations

1. **Batch Price Queries**: Uses `getIngredientPrices()` for batch fetching
2. **Canonical ID Resolution**: Resolves IDs once per calculation
3. **Early Returns**: Skips unnecessary work when possible
4. **Async Operations**: Non-blocking calculations

### Caching

- No caching (always fresh data)
- Provider-based state management
- FutureBuilder for async loading

---

## Rules Compliance

### ✅ No Charts Yet

- Basic UI with cards and progress bar
- No complex chart libraries
- Simple visual indicators

### ✅ Mobile-First Visual Indicators

- Responsive grid layout (2x2)
- Touch-friendly card sizes
- Color-coded metrics
- Progress bar visualization
- Clear icons and labels

### ✅ All Required Metrics

- ✅ Total pantry estimated value
- ✅ Estimated meals available
- ✅ Coverage % based on planned recipes
- ✅ Simple efficiency score

---

## Testing Checklist

- [ ] Calculate analytics with full pantry
- [ ] Calculate analytics with empty pantry
- [ ] Calculate analytics with meal plan
- [ ] Calculate analytics without meal plan
- [ ] Coverage calculation with partial ingredients
- [ ] Efficiency score calculation
- [ ] Efficiency score with expired items
- [ ] Efficiency score with expiring items
- [ ] Widget displays correctly
- [ ] Widget handles loading state
- [ ] Widget handles error state
- [ ] Color coding works correctly
- [ ] Progress bar displays correctly
- [ ] Mobile responsiveness

---

## Files Modified/Created

### Modified
- `lib/services/pantry_analytics_service.dart` - Enhanced with comprehensive analytics
- `lib/features/pantry/presentation/widgets/pantry_analytics_widget.dart` - Complete redesign
- `lib/providers/phase2_providers.dart` - Updated provider with dependencies

### Created
- `PANTRY_ANALYTICS_IMPLEMENTATION.md` - This documentation

---

## Usage Examples

### Basic Usage

```dart
final analyticsService = ref.watch(pantryAnalyticsServiceProvider);
final analytics = await analyticsService.calculateComprehensiveAnalytics(
  pantryItems,
  userId,
);

print('Total Value: \$${analytics.totalValue}');
print('Meals Available: ${analytics.estimatedMealsAvailable}');
print('Coverage: ${analytics.coveragePercentage}%');
print('Efficiency: ${analytics.efficiencyScore}');
```

### Widget Usage

```dart
PantryAnalyticsWidget(
  pantryItems: items,
)
```

---

## Future Enhancements

### Potential Additions

1. **Charts** (when requested):
   - Value over time
   - Coverage trends
   - Efficiency history

2. **Detailed Breakdowns**:
   - Top value items
   - Missing ingredients list
   - Efficiency improvement suggestions

3. **Notifications**:
   - Low efficiency alerts
   - Coverage warnings
   - Expiring items affecting score

---

**Implementation Date:** January 26, 2026  
**Status:** ✅ Complete
