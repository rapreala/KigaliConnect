# KigaliConnect — Implementation Reflection

**Course:** Mobile Application Development — Individual Assignment 2
**App:** KigaliConnect City Directory
**Student:** [Your Name]
**Date:** 2025

---

## Overview

This document reflects on the key Firebase integration challenges encountered during development of the KigaliConnect application, the errors that surfaced, and how each was diagnosed and resolved.

---

## Error 1: Pigeon Type-Cast Crash on User Registration

### Description

During early development, creating a new account via `FirebaseAuth.createUserWithEmailAndPassword()` succeeded silently in Firebase Console, but the app crashed immediately after with a cryptic Dart type-cast error coming from the Pigeon platform channel:

```
type 'List<Object?>' is not a subtype of type 'List<String?>' in type cast
```

The stack trace pointed deep into the `firebase_auth` platform channel, not in our own code, making the root cause very hard to identify.

### Diagnosis

Through a process of elimination — commenting out lines one at a time — the crash was traced to a `user.updateDisplayName(displayName)` call made immediately after registration. This method internally triggers another platform channel round-trip through Pigeon, and the version of `firebase_auth` used (`^4.16.0`) had a known incompatibility with the Pigeon-generated channel code when called immediately after `createUserWithEmailAndPassword` on Android.

### Resolution

Removed the `updateDisplayName()` call from the registration flow entirely. The `displayName` is stored in the Firestore `users/{uid}` document instead, which is the single source of truth for profile data throughout the app. This is a cleaner architecture anyway — Firebase Auth is used only for authentication tokens, while all profile fields live in Firestore.

**Commit:** `fix: remove updateDisplayName call that caused Pigeon type-cast crash`

---

## Error 2: Stale Auth State — Deleted Users Re-entering the App

### Description

During testing with multiple test accounts, a user whose Firebase Auth account was manually deleted from the Firebase Console could still open the app and reach the main `AppShell` without being re-authenticated. The Firebase SDK cached the auth token locally, so the app believed the user was still signed in.

### Diagnosis

`FirebaseAuth.authStateChanges` does not immediately fire when a user is deleted from the console — it only reflects the cached local state until the token expires (typically 1 hour). Calling `FirebaseAuth.instance.currentUser` returned a non-null user even though the account no longer existed in Firebase.

### Resolution

Added a `user.reload()` call inside `_onAuthUserChanged` in `AuthBloc`. This forces a round-trip to Firebase to refresh the token. If the user has been deleted or disabled, Firebase throws a `FirebaseAuthException` with code `user-not-found` or `user-disabled`. The bloc catches these specific codes, calls `signOut()` to clear the local cache, and emits `AuthUnauthenticated`.

```dart
try {
  await user.reload();
} on FirebaseAuthException catch (e) {
  if (e.code == 'user-not-found' || e.code == 'user-disabled') {
    await _authRepository.signOut();
    emit(const AuthUnauthenticated());
    return;
  }
} catch (_) {
  // Ignore transient network errors — proceed with cached user.
}
```

**Commit:** `fix: sign out stale cached users deleted from Firebase Console`

---

## Error 3: Listings Not Appearing After Creation (Empty Screen Bug)

### Description

After implementing the `ListingsBloc` with a server-side Firestore `where(category: ...)` filter, creating a new listing produced an empty list screen. The listing was visible in Firebase Console but not in the app until a hot restart.

### Diagnosis

The root cause was two compounding issues:

1. **Stream subscription race**: The server-side `where()` query created a new Firestore stream every time the category filter changed. If the stream had not yet fired by the time `ListingCreated` completed, the in-memory `_allListings` list was replaced by the new stream's empty initial result, wiping out the just-created listing.

2. **Malformed documents crashing the stream**: A Firestore document written with a missing `category` field caused `Listing.fromJson()` to throw, which terminated the entire stream with an uncaught error. Once the stream died, no further real-time updates were received.

### Resolution

Two fixes applied together:

**Fix 1 — Switch to a single all-listings stream with client-side filtering:**

```dart
// Before: server-side filter, new stream per category
_listingsSubscription = _repo.watchListings(category: _activeCategory).listen(...)

// After: always stream all, filter in memory
_listingsSubscription = _repo.watchListings().listen(...)

ListingsLoaded _buildLoaded() {
  final byCategory = _activeCategory == null
      ? _allListings
      : _allListings.where((l) => l.category == _activeCategory).toList();
  // ... apply search filter on top
}
```

**Fix 2 — Defensive stream mapping to skip malformed documents:**

```dart
return query.snapshots().map(
  (snap) => snap.docs
      .map((d) { try { return Listing.fromJson(d.data()); } catch (_) { return null; } })
      .whereType<Listing>()
      .toList(),
);
```

**Commits:** `fix: keep listings visible during ListingsActionSuccess transient state`

---

## Error 4: Real-time Updates Stopped After First Error

### Description

Occasionally, especially on flaky emulator WiFi, the Firestore stream would emit an error. After that, edits and deletions stopped reflecting in the UI — the app showed stale data that only updated on hot restart.

### Diagnosis

A Dart stream terminates permanently on error unless the `onError` handler prevents propagation. The initial implementation used `.listen((data) => ...)` without an `onError` callback. Once Firestore emitted a network error, the `StreamSubscription` reached its end state and never fired again. The BLoC showed the last known `ListingsLoaded` state indefinitely.

### Resolution

Added an `onError` handler that dispatches an internal `_ListingsStreamErrored` event. The BLoC handler for this event calls `_subscribe()` again to create a fresh stream subscription:

```dart
_listingsSubscription = _repo.watchListings().listen(
  (listings) => add(_ListingsUpdated(listings)),
  onError: (Object e) => add(_ListingsStreamErrored(e.toString())),
);

void _onStreamErrored(_ListingsStreamErrored event, Emitter<ListingsState> emit) {
  if (state is! ListingsLoaded) {
    emit(ListingsError(event.message));
  }
  _subscribe(); // restart the stream
}
```

This keeps the UI showing the last valid data while silently reconnecting in the background.

---

## Error 5: Google Maps Showing Grey Tiles (API Key Restrictions)

### Description

After integrating `google_maps_flutter` and adding an API key to `AndroidManifest.xml`, the `MapViewScreen` rendered only a grey grid with no map tiles. The app did not throw any error or exception — it simply displayed a blank grey canvas where the map should appear. Markers were not visible either.

### Diagnosis

The Google Maps SDK for Android was not enabled for the API key in Google Cloud Console. The key existed but had not been granted access to the Maps SDK — requests to the tile server were being silently rejected with a `REQUEST_DENIED` response that the Flutter plugin does not surface as a Dart exception.

A secondary issue was found during testing: the API key had **HTTP referrer restrictions** applied (intended for web use), which are incompatible with Android SDK requests. Android app requests are authenticated by the app's SHA-1 fingerprint, not by HTTP referrer headers.

### Resolution

**Step 1 — Enable the Maps SDK for Android:**

1. Open [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to **APIs & Services → Library**
3. Search for **"Maps SDK for Android"** and click **Enable**

**Step 2 — Remove incompatible restrictions:**

1. Navigate to **APIs & Services → Credentials**
2. Select the API key used in `AndroidManifest.xml`
3. Under **Application restrictions**, set to **"Android apps"** (not "HTTP referrers")
4. Add the app's SHA-1 fingerprint under **Android restrictions**:
   ```
   Debug SHA-1: 49:D3:C4:49:14:FC:11:4D:C8:03:2A:EA:D5:9B:AC:89:70:0D:49:2A
   ```
5. Under **API restrictions**, select **"Restrict key"** and choose **Maps SDK for Android**

**Step 3 — During development, use an unrestricted key:**

For rapid development and emulator testing, temporarily set the key to **"Don't restrict key"** with only the Maps SDK API restriction enabled. This avoids SHA-1 registration issues on emulators where the debug certificate may vary.

After applying these changes, map tiles loaded immediately on the next app launch. All markers appeared at their correct Firestore-stored coordinates.

**Key file:** `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ENABLED_KEY_HERE"/>
```

---

## Key Learnings

1. **Firebase Auth platform channels can be fragile** — avoid calling multiple Auth methods in rapid sequence immediately after account creation. Store extra profile data in Firestore instead.

2. **Always handle stream errors explicitly** — a Dart stream that terminates on error stops all future updates. Using `onError` with an auto-resubscribe pattern is essential for production-quality real-time features.

3. **Server-side filtering creates subtle race conditions** — client-side filtering on a single all-documents stream is more predictable and provides a better user experience (instant category switching, no loading states between filter changes).

4. **Defensive deserialization prevents silent stream death** — wrapping `fromJson` in a try/catch and skipping malformed documents protects the entire stream from a single bad Firestore document.
