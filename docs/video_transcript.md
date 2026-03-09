# KigaliConnect — Demo Video Transcript

**Target duration:** 10–12 minutes
**Setup before recording:**
- Android emulator running with app open on Login screen
- Firebase Console open in browser (Authentication + Firestore tabs)
- VS Code open with project loaded
- Terminal ready to run `flutter test`

---

## [0:00 – 0:30] Introduction

> "Hi, my name is [Your Name] and this is my demo for Individual Assignment 2 — KigaliConnect, a Flutter city directory app for Kigali, Rwanda. The app lets authenticated users browse, create, and manage listings for public services and places, view them on a live Google Map, and filter by category or search by keyword. Everything is backed by Firebase Auth and Cloud Firestore with real-time updates. I'll walk through each feature and show the implementation code as I go."

---

## [0:30 – 1:45] Folder Structure & Architecture

**On screen: VS Code, open the root `lib/` folder in the Explorer panel**

> "Let me start with the architecture. The project follows Clean Architecture with three layers."

> "The `domain/` folder is pure Dart — no Firebase imports, no Flutter imports. It holds our models like `Listing` and `UserProfile`, the abstract repository interfaces, and all validators."

**Click open `lib/domain/models/listing.dart`**

> "Here's the `Listing` model. It's an immutable value object with `copyWith`, `toJson`, `fromJson`, and proper equality. The `category` field is a `PlaceCategory` enum serialised as its name string — so Firestore documents are human-readable."

**Click open `lib/domain/repositories/listings_repository.dart`**

> "The `ListingsRepository` abstract interface defines `watchListings`, `createListing`, `updateListing`, and `deleteListing`. The UI never talks to Firebase directly — it only talks to this interface."

**Click open `lib/data/repositories/firebase_listings_repository.dart`**

> "Down in the `data/` layer, `FirebaseListingsRepository` implements that interface using the actual Firestore SDK. This is the only file in the entire project that imports `cloud_firestore`. The UI layer has zero knowledge of Firebase."

> "And finally the `presentation/` layer holds BLoCs, screens, and widgets. UI widgets rebuild in response to BLoC state — they never call Firebase APIs themselves."

---

## [1:45 – 3:30] Authentication

**On screen: Emulator on Login screen → navigate to Register, type email and password, tap Create Account**

> "I'll register a new account. The app lands on the Email Verification screen. If I check Firebase Console, the user exists but isn't verified yet — the app blocks access until that changes."

**Switch to VS Code, open `auth_bloc.dart`, scroll to `_onRegisterRequested`**

> "In `_onRegisterRequested`, after `register()` succeeds we call `sendEmailVerification()` and emit `AuthEmailNotVerified`. `AuthGate` sees that state and holds the user on the verification screen."

**Scroll to `_onAuthUserChanged`**

> "When Firebase fires an auth state change, `_onAuthUserChanged` calls `user.reload()` to fetch a fresh token, then reads `refreshed.emailVerified`. If it's still false, we stay put. Once the user clicks the link, the next poll returns `emailVerified: true`, we call `getCurrentUserProfile()` to load the already-existing Firestore document, and emit `AuthAuthenticated`."

**Switch to Firestore → users collection — show the user document**

> "That document was written at registration — there's no `verified` field in Firestore at all. Email verification state lives entirely in Firebase Auth, not in our database."

**Click verification link → watch app navigate to AppShell automatically**

> "The `EmailVerificationScreen` polls every 3 seconds. As soon as Firebase confirms the email, the BLoC emits `AuthAuthenticated` and the app navigates without any button press."
---

## [3:30 – 6:00] State Management & Listings CRUD

**On screen: VS Code, open `lib/presentation/blocs/listings/listings_bloc.dart`**

> "Now let me explain the core state management. The `ListingsBloc` is the heart of the app."

**Scroll to `_subscribe()`**

> "When `ListingsSubscriptionRequested` is dispatched, we call `_subscribe()` which opens a real-time Firestore stream. Every time Firestore pushes an update — whether it's a new listing, an edit, or a deletion — the stream fires and we add a `_ListingsUpdated` event."

**Scroll to `_buildLoaded()`**

> "The `_buildLoaded` method builds our `ListingsLoaded` state from `_allListings`. Notice it produces three lists: `allListings` — the raw unfiltered master list, `listings` — filtered by the active category, and `filteredListings` — filtered by category AND search query. The Map screen uses `allListings` so it always shows every marker regardless of what filter the Places tab has active."

**Open `lib/presentation/blocs/listings/listings_state.dart`**

> "Here's the `ListingsLoaded` state. It extends `Equatable` so BLoC automatically compares states and only rebuilds widgets when something actually changed."

**Switch to emulator — Places tab**

> "Let me create a listing now. I'll tap the FAB."

**Open `lib/presentation/screens/listings/add_listing_screen.dart`**

> "The `AddListingScreen` uses a `ListingForm` widget."

**On emulator: type an address, tap the geocode button**

> "I'll type a real Kigali address and tap the location button — that triggers the `geocoding` package to convert the address text to latitude and longitude automatically."

**Open `lib/presentation/widgets/listings/listing_form.dart`, scroll to `_geocodeAddress`**

> "Here in `ListingForm._geocodeAddress`, we call `locationFromAddress()` from the geocoding package, then populate the lat/lng fields. If it fails, the user sees a snackbar and can still enter coordinates manually."

**On emulator: fill remaining fields, tap Save**

> "Save dispatches `ListingCreated` to the BLoC."

**Switch to VS Code, scroll to `_onListingCreated` in listings_bloc.dart**

> "In `_onListingCreated` — we call `_repo.createListing()`, then immediately prepend the new listing to `_allListings` before Firestore even confirms. This is an optimistic update — the UI responds instantly. Then we emit `ListingsActionSuccess` — which shows a snackbar — followed by `_buildLoaded()` which rebuilds the list."

**Switch to Firebase Console → Firestore → listings collection**

> "Firestore Console shows the new document was written with all fields including the auto-geocoded coordinates."

**Switch to emulator — tap the listing to open detail, then tap Edit**

> "Now I'll edit it."

**Change the name, tap Save**

**Switch to VS Code, scroll to `_onListingUpdated`**

> "Same optimistic pattern in `_onListingUpdated` — we call `repo.updateListing()`, replace the item in `_allListings` by ID, emit success, then rebuild. The `ListingDetailScreen` wraps itself in a `BlocConsumer` that looks up the listing by ID from the live state — so it shows the updated name immediately without any navigation."

**Switch to emulator — delete a listing**

**Scroll to `_onListingDeleted` in the BLoC**

> "And delete removes it from `_allListings` and calls `repo.deleteListing()`. After deletion, `ListingDetailScreen`'s listener detects the listing is no longer in state and auto-pops back to the list."

---

## [6:00 – 7:15] Search & Category Filtering

**On screen: emulator — Places tab with several listings**

> "Now search and filtering."

**Type 'hospital' in the search bar**

> "Results update instantly as I type — no Firestore round-trip."

**Switch to VS Code, open `listings_bloc.dart`, scroll to `_onSearchChanged` and `_buildLoaded`**

> "In `_onSearchChanged` we just update `_searchQuery` and call `_buildLoaded()`. The filter runs in memory across the `_allListings` master list — checking name, address, and description fields. No new Firestore query needed."

**On emulator: clear search, tap a category chip — e.g. Hospital**

> "Category filtering is also instant."

**Scroll to `_onCategoryChanged`**

> "Same pattern — `_activeCategory` is updated and `_buildLoaded()` rebuilds the filtered list client-side. Notice the empty state message — if there are no listings in a category, we show a contextual prompt with the category name and an Add button."

**Tap a category with no listings to show empty state**

> "The empty state tells the user exactly what's missing and gives them a shortcut to create one."

---

## [7:15 – 8:30] Map Integration

**On screen: emulator — tap the Map tab**

> "The Map tab shows every listing as a colour-coded marker. Hospital listings are red, parks are green, police stations are blue, and so on."

**Switch to VS Code, open `lib/presentation/screens/map/map_view_screen.dart`**

> "In `MapViewScreen.build`, we read `state.allListings` — not `listings` — so the map always shows everything regardless of the search or category filter active on the Places tab."

**Scroll to `_buildMarkers`**

> "Each `Listing` becomes a `Marker`. The `infoWindow.onTap` callback navigates to `ListingDetailScreen` passing `canEdit: true` if the current user's UID matches `listing.createdBy`."

**Scroll to `_categoryHue`**

> "The `_categoryHue` switch maps each `PlaceCategory` enum value to a Google Maps `BitmapDescriptor` hue constant — red for hospitals, blue for police, and so on."

**On emulator: tap a marker, tap the info window, show the detail screen with embedded map**

> "Tapping the info window opens the detail screen. The detail screen embeds its own smaller `GoogleMap` with scroll and zoom gestures disabled — it's just a preview. The coordinates come directly from the Firestore document."

**Tap Get Directions**

> "Get Directions opens Google Maps with a `google.com/maps/search` URL containing the stored latitude and longitude."

**Open `listing_detail_screen.dart`, show `_openInMaps`**

> "Here's `_openInMaps` — we build a URI with the listing's Firestore coordinates and launch it with `url_launcher`."

---

## [8:30 – 9:30] My Listings Tab & Navigation

**On screen: emulator — tap the My Listings tab**

> "The My Listings tab is a dedicated view showing only the current user's listings — filtered by `createdBy == currentUser.uid`."

**Open `lib/presentation/screens/listings/my_listings_screen.dart`**

> "In `MyListingsScreen`, we read `state.allListings` and filter in-place. Every card opens `ListingDetailScreen` with `canEdit: true`, so edit and delete buttons are always shown for the user's own listings."

**Switch to VS Code, open `lib/presentation/screens/shell/app_shell.dart`**

> "The shell uses an `IndexedStack` — all four tabs are alive simultaneously. Switching tabs preserves scroll position and BLoC subscriptions. There's one `ListingsBloc` provided above the shell so Places, Map, and My Listings all share the same real-time stream."

**On emulator — tap Settings tab**

> "Settings shows the user's display name and email from their Firestore profile."

**Open `lib/presentation/screens/settings/settings_screen.dart`**

> "The `SettingsCubit` loads the `UserProfile` from `AuthBloc`'s state. The notifications toggle calls `repo.updateDoc` on `users/{uid}.notificationsEnabled`. The dark mode switch uses `ThemeCubit` — let me show that."

**Toggle dark mode on emulator**

**Open `lib/presentation/blocs/settings/theme_cubit.dart`**

> "The `ThemeCubit` wraps `SharedPreferences`. `toggleTheme()` persists the choice and emits the new `ThemeMode`. In `main.dart`, `loadSavedTheme()` is called before `runApp()` so there's no flash of the wrong theme on startup."

---

## [9:30 – 10:30] Tests & Code Quality

**On screen: VS Code terminal**

```
flutter test test/unit/ test/bloc/
```

> "Let me run the test suite."

**Show the terminal output — 102 tests passing**

> "102 tests pass. The test suite covers three areas: domain model serialisation round-trips and `copyWith`, all validator boundary cases — for example, latitude must be between -90 and 90, phone numbers 7 to 15 digits — and BLoC tests using mockito mocks of the repository interfaces."

**Open `test/bloc/listings_bloc_test.dart`**

> "Here's an example BLoC test — `ListingDeleted` should emit `ListingsActionSuccess` then `ListingsLoaded` with the item removed. The mock repository stubs out the Firestore call so these run in under a second with no network."

---

## [10:30 – 11:15] Deliverables Reference

**On screen: VS Code — open `docs/design_summary.md`**

> "I've prepared two supporting documents. The design summary covers the Firestore schema for both collections, the Listing model design decisions — why it's immutable, why category is an enum string — the BLoC data flow diagram, and a trade-off comparison table explaining decisions like client-side filtering versus server-side queries."

**Open `docs/implementation_reflection.md`**

> "The implementation reflection documents five Firebase integration errors I encountered: the Pigeon type-cast crash from calling `updateDisplayName` immediately after registration, stale cached auth state for deleted users, the empty-screen bug caused by a server-side filter race condition, Firestore streams dying silently after a network error, and the Google Maps grey-tile issue caused by the Maps SDK not being enabled in Google Cloud Console. Each error includes the diagnosis and the exact code fix that resolved it."

---

## [11:15 – 11:45] Closing

**On screen: emulator — show the full app running**

> "To summarise: KigaliConnect is a full-stack Flutter app with Clean Architecture separating domain, data, and presentation layers. State is managed entirely by BLoC with real-time Firestore streams, optimistic updates, and auto-resubscribe on error. Authentication enforces email verification before granting access. All four CRUD operations reflect immediately in the UI across the Directory, My Listings, and Map screens without any manual refresh. The repository has 28 commits documenting progressive development from project init through authentication, listings, maps, settings, and the test suite. Thank you."

---

## Recording Checklist

Before pressing record, confirm:

- [ ] Emulator is booted and logged OUT (to show sign-up live)
- [ ] Firebase Console is open with **Authentication** and **Firestore** tabs ready
- [ ] VS Code has the project open and **Explorer** panel visible
- [ ] Terminal is open at the project root
- [ ] A few test listings already exist in Firestore for the map/filter demos
- [ ] Screen recorder captures both emulator and VS Code side-by-side (or switch between them)
- [ ] Microphone levels tested — no background noise

## Suggested Screen Layout

```
┌────────────────────┬──────────────────────────────┐
│   Android Emulator │      VS Code / Browser        │
│   (left half)      │      (right half)             │
└────────────────────┴──────────────────────────────┘
```

Alternatively record full-screen VS Code and use `flutter run` in a floating emulator window that you bring to front when showing app behaviour.
