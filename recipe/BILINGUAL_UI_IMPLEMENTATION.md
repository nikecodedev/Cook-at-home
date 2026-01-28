# Bilingual UI Support - Implementation

## Overview

Complete implementation of bilingual UI support (English and Spanish) with user preference storage, device language detection, and language selector.

---

## ✅ Implementation Status

### Completed Components

1. **✅ ProfileModel Enhancement** (`lib/models/profile_model.dart`)
   - Added `languagePreference` field
   - Supports 'en' or 'es' values
   - Null = use device default

2. **✅ Locale Provider** (`lib/providers/locale_provider.dart`)
   - Manages app locale state
   - Priority: User preference > Device locale > Default (Spanish)
   - Watches profile changes for language updates

3. **✅ Language Selector Widget** (`lib/features/profile/presentation/widgets/language_selector_widget.dart`)
   - Visual language selector
   - Shows current selection
   - Updates locale immediately
   - Saves preference to user profile

4. **✅ Main App Integration** (`lib/main.dart`)
   - Uses locale provider instead of hardcoded locale
   - Reacts to locale changes automatically

5. **✅ Firestore Service** (`lib/services/firestore/firestore_service.dart`)
   - Updated `updateUserProfile()` to support language preference

---

## Language Preference Priority

### Priority Order

1. **User Preference** (stored in profile)
   - Saved in `users/{userId}/languagePreference`
   - Persists across app restarts
   - Can be changed via language selector

2. **Device Locale** (fallback)
   - Detected from system settings
   - Used if no user preference set
   - Automatically matches device language

3. **Default** (fallback)
   - Spanish (es_ES)
   - Used if device locale not supported

### Flow

```
App Start
  ↓
Check User Profile
  ↓
Has languagePreference?
  ├─ Yes → Use user preference
  └─ No → Check Device Locale
           ├─ Supported? → Use device locale
           └─ Not supported? → Use default (Spanish)
```

---

## Language Selector UI

### Location

**Profile Screen** (`lib/features/profile/presentation/screens/profile_screen.dart`)

**Placement:**
- After serving size field
- Before household members section
- Always visible (not edit-mode only)

### Features

- **Visual Selection:**
  - Card-based design
  - Selected language highlighted
  - Check icon for selected option

- **Languages:**
  - English (en)
  - Spanish (es)

- **User Feedback:**
  - Success snackbar on change
  - Error handling
  - Immediate UI update

- **Note Display:**
  - Reminds users that user-generated content is NOT translated
  - Recipes, ingredients, pantry items remain in original language

---

## Persistence Logic

### Storage

**Location:** Firestore `users/{userId}` document

**Field:** `languagePreference` (String?)

**Values:**
- `'en'` - English
- `'es'` - Spanish
- `null` - Use device default

### Update Flow

1. **User selects language** in language selector
2. **Locale updated immediately** (UI changes)
3. **Profile updated** in Firestore
4. **Profile stream invalidated** (triggers refresh)
5. **Locale provider watches** profile changes
6. **State synchronized** across app

---

## User-Generated Content Protection

### Rule: No Translation

**Protected Content:**
- Recipe titles
- Recipe instructions
- Ingredient names
- Pantry item names
- Shopping list items
- User comments/notes

**Translated Content:**
- UI labels and buttons
- System messages
- Error messages
- Help text
- Navigation labels

### Implementation

- Only `AppLocalizations` strings are translated
- All user data stored as-is in Firestore
- No translation service applied to user content
- Display language affects UI only, not data

---

## Locale Provider Details

### LocaleNotifier

**State:** `Locale` (current app locale)

**Methods:**
- `setLocalePreference(String languageCode)` - Set and save preference
- `_initializeLocale()` - Initialize from profile or device
- `_watchProfileChanges()` - Watch for profile updates
- `_getDeviceLocale()` - Get device locale
- `_parseLocale(String)` - Parse language code to Locale

### Initialization

```dart
LocaleNotifier(firestoreService, ref)
  → _initializeLocale() // Get from profile or device
  → _watchProfileChanges() // Watch for updates
```

### Profile Watching

- Listens to `profileStreamProvider`
- Updates locale when profile changes
- Handles null preference (reverts to device locale)

---

## Language Selector Component

### Widget Structure

```dart
LanguageSelectorWidget(
  enabled: true, // Can be disabled in certain contexts
)
```

### Display

- **Header:** Language icon + "Language" title
- **Description:** Explains language selection
- **Options:** English and Spanish cards
- **Note:** Reminder about user content not being translated

### Selection Behavior

1. User taps language option
2. Locale updated immediately
3. Profile saved to Firestore
4. Success message shown
5. App UI updates automatically

---

## Integration Points

### 1. Main App

**Location:** `lib/main.dart`

**Integration:**
```dart
final currentLocale = ref.watch(appLocaleProvider);
MaterialApp.router(
  locale: currentLocale,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

### 2. Profile Screen

**Location:** `lib/features/profile/presentation/screens/profile_screen.dart`

**Integration:**
```dart
const LanguageSelectorWidget(enabled: true)
```

### 3. Profile Model

**Location:** `lib/models/profile_model.dart`

**Field:**
```dart
final String? languagePreference;
```

### 4. Firestore Service

**Location:** `lib/services/firestore/firestore_service.dart`

**Method:**
```dart
updateUserProfile(
  userId: userId,
  languagePreference: languageCode,
)
```

---

## Localization Files

### Current Structure

**File:** `lib/core/localization/app_localizations.dart`

**Languages:**
- English (`'en'`)
- Spanish (`'es'`)

**Strings:**
- All UI labels
- Error messages
- Button text
- Navigation labels
- System messages

**New Strings Added:**
- `language` - "Language" / "Idioma"
- `languageDescription` - Description text
- `languageNote` - Note about user content
- `languageChanged` - Success message
- `languageChangeError` - Error message

---

## Device Language Detection

### Implementation

```dart
_getDeviceLocale() {
  final deviceLocales = ui.PlatformDispatcher.instance.locales;
  // Get first device locale
  // Match against supported locales
  // Return matching locale or default
}
```

### Supported Device Locales

- English variants: `en_US`, `en_GB`, `en_CA`, etc. → `Locale('en', 'US')`
- Spanish variants: `es_ES`, `es_MX`, `es_AR`, etc. → `Locale('es', 'ES')`
- Other languages → Default (Spanish)

---

## Rules Compliance

### ✅ English and Spanish UI

- Full localization support for both languages
- All UI strings translated
- System messages localized

### ✅ Language Preference Stored Per User

- Saved in user profile
- Persists across sessions
- Syncs across devices (if same account)

### ✅ Default Based on Device Language

- Detects device locale on first launch
- Uses device language if supported
- Falls back to Spanish if not supported

### ✅ User-Generated Content NOT Translated

- Recipe titles: Stored as-is
- Ingredients: Stored as-is
- Instructions: Stored as-is
- All user data: No translation applied

---

## Files Modified/Created

### Modified
- `lib/models/profile_model.dart` - Added languagePreference field
- `lib/services/firestore/firestore_service.dart` - Added languagePreference to updateUserProfile
- `lib/main.dart` - Uses locale provider instead of hardcoded locale
- `lib/core/localization/app_localizations.dart` - Added language selector strings
- `lib/features/profile/presentation/screens/profile_screen.dart` - Added language selector widget

### Created
- `lib/providers/locale_provider.dart` - Locale management provider
- `lib/features/profile/presentation/widgets/language_selector_widget.dart` - Language selector UI
- `BILINGUAL_UI_IMPLEMENTATION.md` - This documentation

---

## Usage Examples

### Get Current Locale

```dart
final currentLocale = ref.watch(appLocaleProvider);
```

### Change Language

```dart
final localeNotifier = ref.read(appLocaleProvider.notifier);
await localeNotifier.setLocalePreference('en'); // or 'es'
```

### Check User Preference

```dart
final profile = await firestoreService.getUserProfile(userId);
final languagePreference = profile?.languagePreference; // 'en', 'es', or null
```

---

## Testing Checklist

- [ ] Language selector displays correctly
- [ ] English selection works
- [ ] Spanish selection works
- [ ] Preference persists after app restart
- [ ] Device locale detection works
- [ ] Default to Spanish if device locale not supported
- [ ] Profile updates save language preference
- [ ] UI updates immediately on language change
- [ ] User-generated content NOT translated
- [ ] Recipe titles remain in original language
- [ ] Ingredient names remain in original language
- [ ] All UI strings translate correctly
- [ ] Error messages translate correctly

---

## Future Enhancements

### Potential Additions

1. **More Languages:**
   - Add French, Portuguese, etc.
   - Extend localization files

2. **Language Detection:**
   - Auto-detect from recipe content
   - Suggest language based on usage

3. **Per-Recipe Language:**
   - Store language per recipe
   - Display recipes in their original language

---

**Implementation Date:** January 26, 2026  
**Status:** ✅ Complete
