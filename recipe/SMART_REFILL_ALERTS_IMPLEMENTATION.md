# Smart Refill Alerts - Implementation

## Overview

Complete implementation of smart refill alerts that track frequently used ingredients, monitor low quantities, and detect good price opportunities.

---

## ✅ Implementation Status

### Completed Components

1. **✅ Enhanced RefillAlertService** (`lib/services/refill_alert_service.dart`)
   - Usage frequency tracking from recipes and meal plans
   - Price index calculation
   - Smart alert generation with three trigger types
   - Usage-aware low quantity thresholds

2. **✅ Enhanced RefillAlert Model** (`lib/models/refill_alert_model.dart`)
   - Supports three alert reasons: `depletion`, `high_usage`, `price_index`
   - Stores usage frequency and price index data

3. **✅ Enhanced UI Widget** (`lib/features/pantry/presentation/widgets/refill_alerts_widget.dart`)
   - Color-coded alerts by reason
   - Icons for different alert types
   - Displays quantity and reason text
   - Dismiss functionality

4. **✅ Automatic Alert Generation** (`lib/providers/pantry_provider.dart`)
   - Triggers alert generation when pantry items are added/updated
   - Non-blocking background processing

---

## Alert Detection Logic

### 1. Low Quantity Alert (Depletion)

**Trigger:** Item quantity below usage-aware threshold

**Threshold Calculation:**
```
if usageScore >= 0.7: threshold = 30% of typical quantity
else if usageScore >= 0.3: threshold = 20% of typical quantity
else: threshold = 10% of typical quantity
```

**Example:**
- High usage ingredient (usageScore = 0.8): Alerts at 1.5 units (30% of 5.0)
- Medium usage (usageScore = 0.5): Alerts at 1.0 units (20% of 5.0)
- Low usage (usageScore = 0.1): Alerts at 0.5 units (10% of 5.0)

**Reason:** `'depletion'`

### 2. High Usage Frequency Alert

**Trigger:** Frequently used ingredient with low stock

**Conditions:**
- Usage score > 0.7 (high frequency)
- Current quantity < 2.0 units

**Logic:**
- Tracks ingredient usage from recipes and meal plans
- Identifies ingredients used in multiple recipes
- Alerts when frequently used items are running low

**Reason:** `'high_usage'`

### 3. Price Index Alert

**Trigger:** Good price opportunity detected

**Conditions:**
- Price index < 0.8 (lower = better price)
- Price is below average market price

**Price Index Calculation:**
```
priceIndex = (currentPrice - minPrice) / (maxPrice - minPrice)
```

**Logic:**
- Compares ingredient price to market average
- Normalizes to 0.0-1.0 scale (0.0 = best price, 1.0 = worst price)
- Alerts when price is in bottom 20% (index < 0.8)

**Reason:** `'price_index'`

---

## Usage Frequency Tracking

### Data Sources

1. **User Recipes**
   - Counts ingredient appearances in user's recipes
   - Tracks over last 4 weeks

2. **Meal Plans**
   - Counts ingredient usage in planned meals
   - Tracks from current and past meal plans

### Calculation

```dart
usageScore = ingredientUsageCount / maxUsageCount
```

**Normalization:**
- Counts ingredient appearances across all recipes/meal plans
- Normalizes to 0.0-1.0 scale
- Higher score = more frequently used

**Example:**
- Ingredient appears in 8 recipes, max is 10 → usageScore = 0.8
- Ingredient appears in 2 recipes, max is 10 → usageScore = 0.2

---

## Price Index Calculation

### Formula

```dart
priceIndex = (price - minPrice) / (maxPrice - minPrice)
```

**Steps:**
1. Get all ingredient prices
2. Find min and max prices
3. Calculate range
4. Normalize each price to 0.0-1.0 scale

**Interpretation:**
- **0.0-0.3**: Excellent price (bottom 30%)
- **0.3-0.7**: Average price
- **0.7-1.0**: High price (top 30%)

**Alert Threshold:** Index < 0.8 (good price opportunity)

---

## Alert Rules

### Rule 1: No Duplicate Alerts

- Checks for existing active alert before creating new one
- Prevents duplicate alerts for same ingredient and reason
- Uses `getActiveAlert()` to check

### Rule 2: Usage-Aware Thresholds

- High usage items: Alert earlier (30% threshold)
- Low usage items: Alert later (10% threshold)
- Prevents unnecessary alerts for rarely used items

### Rule 3: Price Index Threshold

- Only alerts when price is significantly below average
- Threshold: index < 0.8 (bottom 20% of prices)
- Prevents false positives from minor price fluctuations

### Rule 4: Automatic Generation

- Triggers when pantry items are added/updated
- Runs in background (non-blocking)
- Silent failure (doesn't affect pantry operations)

---

## UI Notification Integration

### RefillAlertsWidget

**Features:**
- Streams active alerts in real-time
- Shows up to 3 alerts with "View more" option
- Color-coded by alert reason:
  - **Red**: Depletion (low stock)
  - **Yellow**: High usage
  - **Green**: Good price

**Alert Item Display:**
- Icon (varies by reason)
- Ingredient name
- Current quantity (if available)
- Reason text (localized)

**Actions:**
- Dismiss button (X icon)
- Navigate to full alerts screen (TODO)

### Visual Indicators

**Icons:**
- `warning_amber_rounded` - Depletion
- `trending_up_rounded` - High usage
- `local_offer_rounded` - Price index

**Colors:**
- Depletion: Error color (red)
- High usage: Warning color (yellow)
- Price index: Success color (green)

---

## Integration Points

### 1. Pantry Provider

**Location:** `lib/providers/pantry_provider.dart`

**Integration:**
- `addPantryItem()` - Triggers alert generation
- `updatePantryItem()` - Triggers alert generation
- Non-blocking background processing

### 2. Refill Alert Service

**Location:** `lib/services/refill_alert_service.dart`

**Methods:**
- `generateSmartRefillAlerts()` - Main generation method
- `_calculateUsageFrequency()` - Usage tracking
- `_calculatePriceIndices()` - Price analysis
- `_checkLowQuantityAlert()` - Low stock detection

### 3. UI Widget

**Location:** `lib/features/pantry/presentation/widgets/refill_alerts_widget.dart`

**Integration:**
- Displays in pantry list screen
- Streams alerts in real-time
- Handles dismiss actions

---

## Alert Generation Flow

### Automatic Generation

1. **User adds/updates pantry item**
   - `PantryProvider.addPantryItem()` or `updatePantryItem()`

2. **Background alert generation triggered**
   - `_generateRefillAlerts()` called
   - Non-blocking, runs in background

3. **Service calculates metrics**
   - Usage frequency from recipes/meal plans
   - Price indices from ingredient prices
   - Current pantry quantities

4. **Alerts generated**
   - Low quantity alerts (usage-aware)
   - High usage alerts
   - Price index alerts

5. **Alerts saved to Firestore**
   - Stored in user's `refill_alerts` collection
   - Streamed to UI widget

### Manual Generation

```dart
final refillAlertService = ref.read(refillAlertServiceProvider);
final alerts = await refillAlertService.generateSmartRefillAlerts(
  userId,
  pantryItems,
);
```

---

## Rules Compliance

### ✅ No Retailer Scraping

- Uses internal price index only
- Compares prices from `ingredient_prices` collection
- No external API calls or web scraping

### ✅ Simple Notification System

- In-app widget display
- No complex push notification setup required
- Can be extended with FCM later if needed

---

## Alert Reasons

### Depletion

**Trigger:** Low quantity based on usage frequency

**Display:**
- Red color
- Warning icon
- "Low Stock" text
- Current quantity shown

### High Usage

**Trigger:** Frequently used ingredient with low stock

**Display:**
- Yellow color
- Trending up icon
- "Frequently Used" text
- Current quantity shown

### Price Index

**Trigger:** Good price opportunity

**Display:**
- Green color
- Local offer icon
- "Good Price" text
- Price index value stored

---

## Usage Frequency Algorithm

### Data Collection

1. **Get user recipes** (last 4 weeks)
2. **Get meal plans** (last 4 weeks)
3. **Count ingredient appearances** in all recipes
4. **Aggregate counts** per canonical ingredient

### Normalization

```dart
maxCount = max(usageCounts.values)
usageScore = count / maxCount
```

**Result:** Score from 0.0 to 1.0

### Threshold Application

- **High usage (≥0.7)**: Alert at 30% remaining
- **Medium usage (0.3-0.7)**: Alert at 20% remaining
- **Low usage (<0.3)**: Alert at 10% remaining

---

## Price Index Algorithm

### Data Collection

1. **Get all ingredient prices** for pantry items
2. **Extract price values** (effectivePrice)
3. **Calculate statistics**: min, max, average

### Normalization

```dart
priceRange = maxPrice - minPrice
priceIndex = (price - minPrice) / priceRange
```

**Result:** Index from 0.0 to 1.0

### Alert Threshold

- **Index < 0.8**: Good price opportunity
- **Index ≥ 0.8**: Normal/high price (no alert)

---

## Files Modified/Created

### Modified
- `lib/services/refill_alert_service.dart` - Enhanced with smart detection
- `lib/models/refill_alert_model.dart` - Added new reason types
- `lib/features/pantry/presentation/widgets/refill_alerts_widget.dart` - Enhanced UI
- `lib/providers/pantry_provider.dart` - Added automatic alert generation
- `lib/providers/phase2_providers.dart` - Updated provider dependencies
- `lib/core/localization/app_localizations.dart` - Added localization strings

### Created
- `SMART_REFILL_ALERTS_IMPLEMENTATION.md` - This documentation

---

## Usage Examples

### Generate Alerts Manually

```dart
final refillAlertService = ref.read(refillAlertServiceProvider);
final alerts = await refillAlertService.generateSmartRefillAlerts(
  userId,
  pantryItems,
);
```

### Get Active Alerts

```dart
final alerts = await refillAlertService.getActiveRefillAlerts(userId);
```

### Dismiss Alert

```dart
await refillAlertService.dismissRefillAlert(userId, alertId);
```

### Stream Alerts

```dart
final alertsStream = refillAlertService.streamActiveRefillAlerts(userId);
alertsStream.listen((alerts) {
  // Handle alerts
});
```

---

## Testing Checklist

- [ ] Low quantity alert with high usage
- [ ] Low quantity alert with low usage
- [ ] High usage frequency alert
- [ ] Price index alert (good price)
- [ ] No duplicate alerts
- [ ] Alert dismissal
- [ ] Usage frequency calculation
- [ ] Price index calculation
- [ ] Automatic generation on pantry update
- [ ] UI displays correctly
- [ ] Color coding works
- [ ] Icons display correctly
- [ ] Localization strings work

---

## Future Enhancements

### Potential Additions

1. **Historical Usage Tracking:**
   - Store usage history in Firestore
   - More accurate frequency calculation
   - Trend analysis

2. **Custom Thresholds:**
   - User-configurable alert thresholds
   - Per-ingredient preferences

3. **Push Notifications:**
   - FCM integration for alerts
   - Scheduled daily checks

4. **Alert Prioritization:**
   - Priority scoring system
   - Sort by urgency

---

**Implementation Date:** January 26, 2026  
**Status:** ✅ Complete
