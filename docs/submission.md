# KigaliConnect — Assignment Submission

**Course:** Mobile Application Development — Individual Assignment 2
**App:** KigaliConnect City Directory
**Student:** [Your Name]
**Student ID:** [Your ID]
**Date:** 2025

---

## Section 1 — Implementation Reflection

### Overview

This section reflects on the key Firebase integration challenges encountered during development of KigaliConnect, the errors that surfaced, and how each was diagnosed and resolved.

---

### Error 1: Pigeon Type-Cast Crash on User Registration

**Description**

During early development, creating a new account via `FirebaseAuth.createUserWithEmailAndPassword()` succeeded silently in Firebase Console, but the app crashed immediately after with a cryptic Dart type-cast error coming from the Pigeon platform channel:

```
type 'List<Object?>' is not a subtype of type 'List<String?>' in type cast
```

The stack trace pointed deep into the `firebase_auth` platform channel rather than our own code, making the root cause difficult to identify.

**Diagnosis**

Through a process of elimination — commenting out lines one at a time — the crash was traced to a `user.updateDisplayName(displayName)` call made immediately after registration. This method internally triggers another platform channel round-trip through Pigeon. The version of `firebase_auth` used (`^4.16.0`) had a known incompatibility with the Pigeon-generated channel code when called immediately after `createUserWithEmailAndPassword` on Android.

**Resolution**

Removed the `updateDisplayName()` call from the registration flow entirely. The `displayName` is now stored directly in the Firestore `users/{uid}` document, making it the single source of truth for profile data throughout the app. Firebase Auth is used only for authentication tokens; all profile fields live in Firestore. This is architecturally cleaner — the domain layer has no dependency on Firebase Auth methods beyond signing in and out.

**Commit:** `fix: remove updateDisplayName call that caused Pigeon type-cast crash`

---

### Error 2: Stale Auth State — Deleted Users Re-entering the App

**Description**

During testing with multiple test accounts, a user whose Firebase Auth account was manually deleted from the Firebase Console could still open the app and reach the main `AppShell` without being re-authenticated. The Firebase SDK cached the auth token locally, so the app believed the user was still signed in.

**Diagnosis**

`FirebaseAuth.authStateChanges` does not immediately fire when a user is deleted from the console — it only reflects the cached local state until the token expires (typically 1 hour). Calling `FirebaseAuth.instance.currentUser` returned a non-null user object even though the account no longer existed in Firebase.

**Resolution**

Added a `user.reload()` call inside `_onAuthUserChanged` in `AuthBloc`. This forces a server round-trip to refresh the token. If the user has been deleted or disabled, Firebase throws a `FirebaseAuthException` with code `user-not-found` or `user-disabled`. The BLoC catches these specific codes, calls `signOut()` to clear the local cache, and emits `AuthUnauthenticated`.

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

### Error 3: Listings Not Appearing After Creation (Empty Screen Bug)

**Description**

After implementing `ListingsBloc` with a server-side Firestore `where(category: ...)` filter, creating a new listing produced an empty list screen. The listing was visible in Firebase Console but not in the app until a hot restart.

**Diagnosis**

Two compounding issues caused this:

1. **Stream subscription race**: The server-side `where()` query created a new Firestore stream every time the category filter changed. If the new stream had not yet fired by the time `ListingCreated` completed, the in-memory `_allListings` list was replaced by the stream's empty initial result, wiping out the newly created listing.

2. **Malformed documents crashing the stream**: A Firestore document written with a missing `category` field caused `Listing.fromJson()` to throw, which terminated the entire stream with an uncaught error. Once the stream died, no further real-time updates were received.

**Resolution**

Two fixes applied together:

**Fix 1 — Switch to a single all-listings stream with client-side filtering:**

```dart
// Before: server-side filter, new stream per category change
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
      .map((d) {
        try { return Listing.fromJson(d.data()); } catch (_) { return null; }
      })
      .whereType<Listing>()
      .toList(),
);
```

**Commit:** `fix: switch to client-side filtering to resolve stream race condition`

---

### Error 4: Real-time Updates Stopped After First Network Error

**Description**

Occasionally, especially on flaky emulator Wi-Fi, the Firestore stream would emit an error. After that error, edits and deletions stopped reflecting in the UI — the app showed stale data that only updated on hot restart.

**Diagnosis**

A Dart stream terminates permanently on error unless an `onError` handler is provided. The initial implementation used `.listen((data) => ...)` with no error handler. Once Firestore emitted a network error, the `StreamSubscription` reached a closed state and never fired again. The BLoC continued showing the last known `ListingsLoaded` state indefinitely.

**Resolution**

Added an `onError` handler that dispatches an internal `_ListingsStreamErrored` event. The BLoC handler calls `_subscribe()` again to open a fresh stream subscription, keeping the UI showing the last valid data while silently reconnecting:

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

**Commit:** `fix: auto-resubscribe Firestore stream on error`

---

### Error 5: Duplicate Listings Appearing After Creation

**Description**

After adding a new listing, the Places tab momentarily showed two identical entries before settling back to one. The duplicate disappeared on the next Firestore stream update.

**Diagnosis**

`flutter_bloc` 8.x processes events **concurrently** by default. The original `_onListingCreated` handler called `await _repo.createListing()`, which writes to Firestore. Firestore's offline persistence fires the stream listener immediately on local write (before the `await` resolves). Since events are processed concurrently, `_onListingsUpdated` ran during the `await`, updating `_allListings` to include the new listing. When `_onListingCreated` then resumed and prepended the same listing again, it was added a second time, resulting in a visible duplicate.

**Resolution**

Removed the optimistic prepend from `_onListingCreated`. Firestore's local persistence fires the stream so quickly (sub-100ms) that the listing appears in the UI without any perceptible delay — the stream update handles the UI refresh on its own:

```dart
Future<void> _onListingCreated(
  ListingCreated event,
  Emitter<ListingsState> emit,
) async {
  try {
    await _repo.createListing(event.listing);
    // Stream fires immediately via Firestore local cache — no manual prepend needed.
    emit(const ListingsActionSuccess('Listing added successfully.'));
  } catch (e) {
    emit(ListingsError(e.toString()));
  }
}
```

**Commit:** `fix: remove optimistic prepend that caused duplicate listing on create`

---

### Error 6: Google Maps Showing Grey Tiles

**Description**

After integrating `google_maps_flutter` and adding an API key to `AndroidManifest.xml`, the `MapViewScreen` rendered only a grey grid with no map tiles. No exception was thrown — the app silently displayed a blank canvas where the map should appear.

**Diagnosis**

The Maps SDK for Android was not enabled for the API key in Google Cloud Console. Tile server requests were being silently rejected with a `REQUEST_DENIED` response that the Flutter plugin does not surface as a Dart exception. A secondary issue was that the key had HTTP referrer restrictions applied (intended for web use), which are incompatible with Android SDK requests — Android authenticates by SHA-1 fingerprint, not HTTP referrer.

**Resolution**

1. Enabled **Maps SDK for Android** in Google Cloud Console → APIs & Services → Library.
2. Changed application restrictions on the key from "HTTP referrers" to "Android apps" and registered the debug SHA-1 fingerprint.
3. During emulator development, temporarily removed application restrictions (key unrestricted) to avoid SHA-1 mismatch issues on emulators where the debug certificate varies.

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ENABLED_UNRESTRICTED_KEY"/>
```

Map tiles loaded immediately after these changes.

---

### Key Learnings

1. **Firebase Auth platform channels can be fragile** — avoid calling multiple Auth methods in rapid sequence immediately after account creation. Store extra profile data in Firestore instead.
2. **Always handle stream errors explicitly** — a Dart stream that terminates on error stops all future updates. An `onError` with auto-resubscribe is essential for production real-time features.
3. **Server-side filtering creates subtle race conditions** — client-side filtering on a single all-documents stream is more predictable and provides instant category switching with no loading states.
4. **Default concurrent BLoC event processing requires care** — optimistic UI mutations that run before stream updates complete can cause duplicates. Either guard against re-insertion or let the stream be the sole source of UI truth.
5. **Defensive deserialization protects the stream** — wrapping `fromJson` in a try/catch and skipping malformed documents prevents a single bad Firestore document from killing the entire real-time feed.

---

## Section 2 — GitHub Repository

**Repository URL:** [YOUR GITHUB REPO LINK HERE]

The repository contains the complete source code for KigaliConnect. Key highlights:

- **28+ commits** documenting progressive development from project initialisation through authentication, listings CRUD, map integration, settings, and the test suite.
- **Clean Architecture** folder structure separating `domain/` (pure Dart), `data/` (Firebase), and `presentation/` (BLoC + UI).
- **README.md** documents all features, the Firestore schema, BLoC data flow, Firebase setup instructions, and how to run locally.
- **102 passing tests** covering domain model serialisation, all validator boundary cases, and BLoC behaviour with mockito mocks.

The README covers:
- Feature list with category/colour mapping
- Firestore schema for both collections with field types and purposes
- BLoC data flow diagram showing Events → BLoC → States → Firestore
- Firebase and Google Maps setup instructions
- Commands to run the app and the full test suite

---

## Section 3 — Demo Video

**Video Link:** [YOUR VIDEO LINK HERE]

**Duration:** 7–12 minutes

The demo video covers the following in order:

| Timestamp | Content |
|---|---|
| 0:00 – 0:30 | Introduction and app overview |
| 0:30 – 1:45 | Folder structure and Clean Architecture walkthrough |
| 1:45 – 3:30 | Authentication — registration, email verification, Firebase Console confirmation |
| 3:30 – 6:00 | Listings CRUD — create, edit, delete with real-time Firestore updates |
| 6:00 – 7:15 | Search and category filtering |
| 7:15 – 8:30 | Map view — colour-coded markers, detail screen, Get Directions |
| 8:30 – 9:30 | My Listings tab and navigation shell |
| 9:30 – 10:30 | Test suite — 102 tests passing |
| 10:30 – 11:15 | Deliverables walkthrough |
| 11:15 – 11:45 | Summary and closing |

Firebase Console is shown concurrently throughout the CRUD and authentication sections to demonstrate how app actions are reflected in the backend in real time.

---

## Section 4 — Design Summary

### 1. Application Overview

KigaliConnect is a Flutter mobile application that serves as a real-time city directory for Kigali, Rwanda. Authenticated users can browse, search, and navigate to essential public services and leisure locations, and contribute or manage their own listings.

---

### 2. Firestore Schema Design

Two top-level collections were chosen to keep data access simple and avoid deep nesting.

#### `users/{uid}`

Stores per-user profile and preferences. The document ID matches the Firebase Auth UID, enforcing strict ownership in security rules.

| Field | Type | Purpose |
|---|---|---|
| uid | String | Mirror of the document ID |
| email | String | Display only — Firebase Auth is the source of truth |
| displayName | String | Shown in Settings and listing attribution |
| createdAt | Timestamp | Account creation date |
| notificationsEnabled | Boolean | User preference, toggled in Settings |

#### `listings/{listingId}`

Stores all public place listings. The document ID is auto-generated by Firestore on creation.

| Field | Type | Purpose |
|---|---|---|
| id | String | Mirror of document ID for client-side operations |
| name | String | Display name of the place |
| category | String | Enum name serialised as string (e.g. `"hospital"`) |
| address | String | Human-readable street address |
| contactNumber | String | Phone number, validated 7–15 digits |
| description | String | Up to 500 characters |
| latitude | Number | Decimal degrees, -90 to 90 |
| longitude | Number | Decimal degrees, -180 to 180 |
| createdBy | String | UID of the creator — used for ownership checks |
| createdAt | Timestamp | Creation time |
| updatedAt | Timestamp | Last modification time |

**Security Rules:**
- Any authenticated user can read all listings.
- A user can only create a listing where `createdBy == request.auth.uid`.
- A user can only update or delete a listing where `resource.data.createdBy == request.auth.uid`.

---

### 3. Listing Model Design

The `Listing` domain class is a pure Dart immutable value object with no Flutter or Firebase imports. This enforces clean architecture — the domain layer has zero external dependencies.

Key decisions:

- **`copyWith()`** — enables immutable updates throughout the BLoC layer without mutation.
- **`==` / `hashCode`** — based on all business fields so `Equatable`-style state comparisons in `ListingsLoaded.props` work correctly.
- **`fromJson` / `toJson`** — the only place that touches `cloud_firestore.Timestamp`, keeping serialisation co-located with the model and out of the BLoC.
- **`category` as enum string** — `PlaceCategory` is serialised as its `.name` string (e.g. `"hospital"`), making Firestore documents human-readable and avoiding fragile integer indexes.

---

### 4. State Management — BLoC Architecture

The app uses **flutter_bloc 8.x** with a strict Events → BLoC → States pattern.

#### ListingsBloc Data Flow

```
UI                    ListingsBloc              Firestore
─────────────────     ────────────────────      ─────────────
ListingsSubscription  → _subscribe()          → watchListings()
Requested                                          │
                      ← _ListingsUpdated ──────────┘
                        _allListings = event.listings
                        emit(_buildLoaded())
                                │
                         ListingsLoaded {
                           allListings      ← all (for map markers)
                           listings         ← category-filtered
                           filteredListings ← category + search filtered
                         }

ListingsCategoryChanged → _activeCategory = cat
                          emit(_buildLoaded())   [instant, no Firestore call]

ListingsSearchChanged   → _searchQuery = query
                          emit(_buildLoaded())   [instant, no Firestore call]

ListingCreated          → repo.createListing()
                          emit(ListingsActionSuccess)
                          [stream fires automatically → _onListingsUpdated]
```

**Key decisions:**

- **Single stream, client-side filter**: always stream all listings and apply category/search filters in-memory. Category switching is instant with no additional Firestore queries.
- **`allListings` field**: the unfiltered master list is exposed on `ListingsLoaded` so `MapViewScreen` always shows every marker regardless of what filter is active on the Places tab.
- **Stream-driven UI on create**: rather than manually prepending to `_allListings` (which caused duplicates due to concurrent BLoC event processing), the create handler simply awaits the write and lets the Firestore stream update the UI via `_onListingsUpdated`.
- **Auto-resubscribe on error**: `_ListingsStreamErrored` is an internal event that calls `_subscribe()` again, keeping the real-time feed alive after a transient network error.

#### AuthBloc

Wraps `FirebaseAuthRepository` and handles the full authentication lifecycle — subscribes to `authStateChanges`, forces `user.reload()` on each state change to detect deleted/disabled accounts, enforces email verification before granting `AuthAuthenticated`, and supports Google Sign-In alongside email/password.

#### ThemeCubit

A lightweight `Cubit<ThemeMode>` backed by `SharedPreferences`. `loadSavedTheme()` is called before `runApp()` to prevent a flash of the wrong theme on startup.

---

### 5. Navigation Architecture

`AppShell` uses an `IndexedStack` with a `BottomNavigationBar` for four tabs: **Places**, **Map**, **My Listings**, **Settings**. `IndexedStack` preserves scroll position and BLoC subscriptions when switching tabs — no rebuilds, no re-subscription to Firestore.

A single `ListingsBloc` is provided above `AppShell` so all four tabs share the same real-time data stream. Creating a listing in the Places tab immediately shows the new marker on the Map tab with no extra Firestore round-trip.

---

### 6. Design Trade-offs

| Decision | Alternative Considered | Rationale |
|---|---|---|
| Client-side category filter | Server-side `where()` per category | Instant switching, no extra stream subscriptions, no race conditions between filter changes and creates |
| Stream-driven create (no optimistic prepend) | Optimistic prepend to `_allListings` | Concurrent BLoC event processing caused duplicates; Firestore local cache fires in <100ms so UX is equivalent |
| Single `ListingsBloc` above shell | Per-screen BLoC instances | Shared real-time state keeps map and directory always in sync |
| `IndexedStack` navigation | `Navigator` push/pop per tab | Preserves scroll position and avoids re-subscribing to Firestore on tab switch |
| Auto-geocoding on address input | Manual lat/lng entry only | Reduces friction for listing creation; falls back gracefully if geocoding fails |
| Immutable domain models | Mutable models | Safe for BLoC equality checks and `props` comparison; prevents accidental mutation in event handlers |

---

*KigaliConnect — Individual Assignment 2, African Leadership University, 2025*
