# Phase 2 – Backend & Web Setup (for client)

**See also:** `VERIFICATION_GUIDE.md` for a step-by-step checklist to verify each feature.

These items require **backend or web deployment** configuration, not app code changes. The app logic for the following is already correct; the backend/web must be in place for full functionality.

---

## 1. Recipe share link (https://cocinaentucasa.com/recipe/{id})

**Issue:** Opening the shared link shows ERR_INTERNET_DISCONNECTED or 404.

**Cause:** The **website** at `cocinaentucasa.com` does not have a route that serves `/recipe/{id}`. The app only generates the URL; the web app must handle it.

**What to do:**
- Deploy or configure the web app so that `https://cocinaentucasa.com/recipe/{recipeId}` is a valid route.
- That route should load the recipe (e.g. from Firestore by `recipeId`) and render a recipe page (name, image, ingredients, etc.).
- Until this route exists and is deployed, shared links will not open correctly in the browser.

---

## 2. Recipe images not displaying

**Issue:** Uploaded recipe images show a placeholder in the app.

**Possible causes:**
1. **Firebase Storage rules** – Recipe images are stored in Firebase Storage. If read rules are too strict (e.g. only authenticated users, or no public read), the app may get the URL but the image request may fail (e.g. 403).
2. **CORS** – If images are loaded in a web context, the Storage bucket must allow the app’s origin in CORS.

**What to do:**
- In Firebase Console → Storage → Rules, ensure authenticated users (or the appropriate scope) can **read** the path where recipe images are stored (e.g. `recipes/{recipeId}/*`).
- For web, configure CORS on the Storage bucket for your app’s domain.
- In the app, recipe image URL is saved to Firestore after upload; list/detail/cards use that URL. No change needed there once Storage and CORS are correct.

---

## 3. Retailer links show “Sin Internet”

**Issue:** Tapping Amazon/Walmart (or other retailer) links sometimes shows “Sin Internet”.

**Cause:** If the **saved link** in the app is wrong (e.g. a recipe share URL like `cocinaentucasa.com/recipe/...` instead of an Amazon/Walmart URL), the app will try to open that. The app has been updated to:
- Not open empty URLs.
- Not open `cocinaentucasa.com` / `cocinaencasa.com` recipe paths as “store” links; it shows a message to add a real store link instead.

**What to do:**
- Ensure users add **real** Amazon/Walmart (or other retailer) product URLs in Pantry and in recipe ingredients.
- If the device has no browser or connectivity, “Sin Internet” can still appear; that is an environment/network issue, not an app bug.

---

## 4. App and website on the same backend

**Issue:** “Architecture mismatch” – app and website not using the same data.

**What to do:**
- Use the **same Firebase project** (same Firestore, same Storage, same Auth) for both the mobile app and the web app.
- Use the same collection/document structure so that recipe IDs and image URLs written by the app are the ones the web app reads for `/recipe/{id}` and for images.

---

## Summary of app-side fixes already done

- **Generate shopping list:** Always creates a list. If all ingredients are in pantry, the list still includes all recipe ingredients as a checklist (no more “Todos los ingredientes ya están en tu despensa” blocking).
- **Meal plan → shopping list:** Same behavior; list is always generated (full checklist when nothing is missing).
- **Retailer links:** Empty and app-domain URLs are validated; recipe share links are not opened as store links; user is prompted to add a real store link when needed.
- **Refill alerts:** Loading state shows a skeleton so the section is not blank.
- **Shopping list screen:** Custom store URLs are validated (empty, invalid scheme, app domain) before opening.

Once the web route `/recipe/{id}` is live and Storage (and CORS) are configured, sharing, images, and retailer flows should align with the intended behavior.
