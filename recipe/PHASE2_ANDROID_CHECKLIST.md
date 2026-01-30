# Phase 2 Android – Module Checklist

This document lists all Phase 2 modules that **must** be included on Android and confirms what **does not** change.

---

## 1. Phase 2 Modules (All Included on Android)

### Core logic & data

| Module | Status | Location / Notes |
|--------|--------|------------------|
| **Canonical ingredient system** | ✅ | `lib/models/canonical_ingredient_model.dart`, `lib/services/canonical_ingredient_service.dart`, Firestore `canonical_ingredients` |
| **Ingredient normalization & synonym handling** | ✅ | `CanonicalIngredient.normalize()`, `_removeAccents()`, synonyms array in model |
| **Global product catalog (shared across users)** | ✅ | Firestore `products` collection, `lib/services/product_service.dart`, no user scoping |

### Pantry enhancements

| Module | Status | Location / Notes |
|--------|--------|------------------|
| **Quantity + unit consistency** | ✅ | Pantry item model: quantity, unit; used in recipes and shopping lists |
| **Expiration dates** | ✅ | `PantryItem.expirationDate`, sort by expiration in Firestore service |
| **Correct linkage to recipes** | ✅ | `canonicalIngredientId` on pantry, recipe ingredients, shopping list items |
| **Pantry value calculation (NEW)** | ✅ | `PantryAnalyticsService`, `pantry_analytics_widget.dart` |
| **Pantry coverage score (NEW)** | ✅ | Coverage % in `PantryAnalyticsService`, shown in pantry analytics UI |

### Barcode scanning (HIGH priority)

| Module | Status | Location / Notes |
|--------|--------|------------------|
| **Scan UPC / EAN** | ✅ | `mobile_scanner`, `BarcodeScannerScreen` |
| **Auto-fill if product exists** | ✅ | `ProductService.getProductByBarcode()`, pantry edit autofill |
| **“Contribute product” flow if not** | ✅ | `ContributeProductScreen`, route `/contribute-product` |
| **Map scanned products → canonical ingredients** | ✅ | Product model `canonicalIngredientId`, contribute flow maps to canonical |

### Recipe logic upgrades

| Module | Status | Location / Notes |
|--------|--------|------------------|
| **Yield & portion system (NEW)** | ✅ | `recipe_model.dart` (yieldValue, yieldUnit, standardPortionSize), `recipe_yield_helper.dart` |
| **Cost per recipe (NEW)** | ✅ | `RecipeCostService`, `RecipeCostWidget` |
| **Cost per portion (NEW)** | ✅ | `RecipeCostService.calculateRecipeCost()`, cost per portion in UI |
| **Cost tiers (low / medium / high)** | ✅ | `CostTierConfig`, `CostTiers` in `firebase_constants.dart` |

### Smart shopping & planning

| Module | Status | Location / Notes |
|--------|--------|------------------|
| **Deduplicated smart shopping lists** | ✅ | `generateShoppingList`, `generateShoppingListFromMealPlan` aggregate by ingredient |
| **Weekly meal planning (Mon–Sun)** | ✅ | `MealPlanScreen`, `dailyMeals` (breakfast/lunch/dinner per day) |
| **Consolidated weekly shopping list** | ✅ | `generateShoppingListFromMealPlan` from meal plan |
| **Weekly plan cost estimation (NEW)** | ✅ | `MealPlanCostService`, cost summary on meal plan screen |

### Pricing intelligence (NEW)

| Module | Status | Location / Notes |
|--------|--------|------------------|
| **Average ingredient price engine** | ✅ | `ingredient_prices` collection, `IngredientPriceService` |
| **Manual override per ingredient** | ✅ | `setIngredientPrice`, user overrides stored per user/ingredient |
| **Architecture ready for Phase 3 dynamic pricing** | ✅ | Service-based pricing, no hardcoded retailer logic |

### Smart alerts (NEW)

| Module | Status | Location / Notes |
|--------|--------|------------------|
| **Refill alerts: consumption** | ✅ | `RefillAlertService`, usage frequency logic |
| **Refill alerts: depletion** | ✅ | Low quantity alerts |
| **Refill alerts: internal price index** | ✅ | Good-price alerts in `RefillAlertService` |
| **UI notification integration** | ✅ | `RefillAlertsWidget` on pantry |

### Sharing & growth

| Module | Status | Location / Notes |
|--------|--------|------------------|
| **Native recipe sharing (WhatsApp, social)** | ✅ | `share_plus`, `RecipeSharingService.shareRecipe()` |
| **Shared recipe deep links** | ✅ | App: `cocinaentucasa://recipe/{id}`, web: `https://cocinaentucasa.app/recipe/{id}` |

### Multi-language support (NEW)

| Module | Status | Location / Notes |
|--------|--------|------------------|
| **English / Spanish UI** | ✅ | `AppLocalizations`, `_localizedValues` (en, es) |
| **Per-user language preference** | ✅ | `ProfileModel.languagePreference`, `LocaleNotifier` |
| **No auto-translation of user content** | ✅ | Only app UI strings localized; recipes/ingredients not translated |

---

## 2. Meal plan → recipe selection (picker flow)

| Item | Status | Notes |
|------|--------|--------|
| **Tap day/meal slot to add food** | ✅ | Opens recipe **picker** (not only recipe list) |
| **Recipe list in “select for meal plan” mode** | ✅ | `RecipeListScreen(selectForMealPlan: true)` |
| **Tap recipe returns it to meal plan** | ✅ | `context.pop(recipe)` when `selectForMealPlan` is true |
| **Router passes selection mode** | ✅ | `Routes.recipes` with `extra: true` for meal plan |

When the user taps a day/meal slot to add food, they see “Seleccionar receta”, a single-tab list of recipes. Tapping a recipe **returns** that recipe to the meal plan and assigns it to the slot (no longer only opening the recipe detail window).

---

## 3. What does NOT change on Android

- **No monetization** – no payments, no in-app purchases  
- **No subscriptions** – no subscription logic or screens  
- **No ads** – no ad SDKs or ad placements  
- **No nutrition data** – no nutrition fields or calculations  
- **No heavy AI** – no ML models or heavy inference; logic is rule-based  
- **No community features** – no social feed, comments, or community UI  
- **No redesign unless required** – existing Android UI kept; new fields/sections added where needed  

Android UI remains familiar: some screens grow (e.g. meal plan, pantry analytics, recipe cost), but there is no full app redesign.

---

## 4. Quick reference – key files

| Area | Key files |
|------|-----------|
| Canonical ingredients | `canonical_ingredient_model.dart`, `canonical_ingredient_service.dart` |
| Products / barcode | `product_model.dart`, `product_service.dart`, `barcode_scanner_screen.dart`, `contribute_product_screen.dart` |
| Pantry | `pantry_item_model.dart`, `pantry_analytics_service.dart`, `pantry_analytics_widget.dart` |
| Prices | `ingredient_price_model.dart`, `ingredient_price_service.dart` |
| Recipe cost & yield | `recipe_cost_service.dart`, `recipe_yield_helper.dart`, `cost_tier_config.dart` |
| Meal plan | `meal_plan_model.dart`, `meal_plan_service.dart`, `meal_plan_cost_service.dart`, `meal_plan_screen.dart` |
| Shopping list from plan | `firestore_service.dart` (`generateShoppingListFromMealPlan`, `getShoppingList`) |
| Refill alerts | `refill_alert_model.dart`, `refill_alert_service.dart`, `refill_alerts_widget.dart` |
| Sharing | `recipe_sharing_service.dart` |
| Localization | `app_localizations.dart`, `locale_provider.dart`, `language_selector_widget.dart` |
| Recipe picker for meal plan | `recipe_list_screen.dart` (`selectForMealPlan`), `app_router.dart` (recipes route extra), `meal_plan_screen.dart` (`_addRecipeToMealSlot`) |

---

## 5. Verification

- All Phase 2 modules listed in **§1** are implemented and wired on Android.
- Meal plan “add food” uses the recipe **picker** and returns the selected recipe (**§2**).
- Constraints in **§3** are respected (no monetization, subscriptions, ads, nutrition, heavy AI, community, or full redesign).

**Last updated:** January 2026
