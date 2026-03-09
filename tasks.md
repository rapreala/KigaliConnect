# Implementation Plan: KigaliConnect City Directory

## Overview

This implementation plan breaks down the KigaliConnect mobile application into discrete coding tasks for a single developer. The plan follows clean architecture principles (Domain → Data → Presentation) with a full BLoC state management pattern (Events + States) and Firebase backend integration.

**CRITICAL: This plan uses a foundation-first approach. Phase 0 MUST be completed before any feature work begins to prevent blockers and conflicts between layers.**

## Clean Architecture Folder Structure

**CRITICAL**: All code must follow the clean architecture folder structure defined in design.md "Folder Structure" section:

- **domain/**: Pure Dart — models, enums, validators (no Firebase, no Flutter imports)
- **data/**: Firebase layer — services and repositories that return domain models
- **presentation/**: UI layer — BLoC (events, states, blocs) + screens + widgets
- **config/**: App-wide configuration — theme, colors, routes
- **utils/**: Helper utilities — map launcher, location helpers

See design.md §2 for the complete folder structure. Task 0.1 includes the bash commands to create all folders.

## Execution Strategy

Build in strict layer order: **Domain → Data → BLoC → Widgets → Screens**. Never write a screen before its BLoC exists. Never write a BLoC before its repository exists. This ensures every layer compiles cleanly before the next is built.

---

## Tasks

### 🚨 Phase 0: Critical Foundation (MUST COMPLETE FIRST - BLOCKS ALL FEATURE WORK)

> NO FEATURE WORK CAN START UNTIL THESE TASKS ARE COMPLETE

These tasks establish the project foundation. Estimated time: 1–2 days.

- [x] 0.1 Project initialization and Firebase configuration - **BLOCKING TASK**
  - Create Flutter project: `flutter create kigali_connect --org com.kigaliconnect`
  - Add all dependencies to `pubspec.yaml`:
    - State: `flutter_bloc: ^8.1.6`, `equatable: ^2.0.5`
    - Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`
    - Maps: `google_maps_flutter`, `url_launcher`
    - Utilities: `intl`, `connectivity_plus`
    - Dev: `bloc_test`, `mockito`, `build_runner`, `flutter_lints`
  - Create Firebase project in Firebase Console (enable Auth + Firestore)
  - Enable Email/Password sign-in in Firebase Console Authentication settings
  - Run FlutterFire CLI: `flutterfire configure` to generate `firebase_options.dart`
  - Download `google-services.json` and place in `android/app/`
  - Add Google Maps API key and location permissions to `android/app/src/main/AndroidManifest.xml`:
    - Add `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY"/>` inside `<application>`
    - Add `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>` before `<application>`
    - Add `<uses-permission android:name="android.permission.INTERNET"/>` before `<application>`
  - Enable Firestore offline persistence in `main.dart`:

    ```dart
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    ```

  - Create the full folder structure:

    ```bash
    mkdir -p lib/domain/{models,validators}
    mkdir -p lib/data/{services,repositories}
    mkdir -p lib/presentation/blocs/{auth,listings,settings}
    mkdir -p lib/presentation/screens/{auth,directory,my_listings,map_view,detail,settings}
    mkdir -p lib/presentation/widgets/common
    mkdir -p lib/config
    mkdir -p lib/utils
    mkdir -p test/{unit,bloc,widget}
    # Note: lib/utils will contain only map_launcher.dart — location_helper.dart is not needed
    ```
  - Test Firebase connection (manually write and read a Firestore document)
  - _Requirements: NFR-01, NFR-07, NFR-08_
  - ⚠️ **MANUAL STEP REQUIRED**: Google Maps API key must be obtained from Google Cloud Console — see `SETUP.md`
  - ⚠️ **MANUAL STEP REQUIRED**: Firebase Auth + Firestore must be enabled in Firebase Console — see `SETUP.md`
  - **DELIVERABLE: Runnable Flutter project connected to Firebase with all folders in place** ✅

- [x] 0.2 Apply Firestore security rules - **BLOCKING TASK**
  - Open Firestore Console → Rules tab
  - Apply security rules from design.md §9:
    - `users/{uid}`: read/write only if `request.auth.uid == uid`
    - `listings/{listingId}`: any authenticated user can read; create only if `createdBy == uid`; update/delete only if `resource.data.createdBy == uid`
  - Publish rules and verify no errors in console
  - _Requirements: NFR-08, LIST-03, LIST-04_
  - ⚠️ **MANUAL STEP REQUIRED**: Rules must be pasted and published in Firebase Console — see `SETUP.md`
  - **DELIVERABLE: Firestore secured so users can only modify their own data** ✅

- [x] 0.3 App theme and common widgets - **BLOCKING TASK**
  - [x] 0.3.1 Create app theme
    - Created `lib/config/theme.dart` with `AppTheme` class and `AppColors`
    - Implemented **dark navy theme with orange accents** — matches the sample UI
    - Key colors: background `#0D1B2A`, surface `#162232`, primary (orange) `#FFB300`, text white, muted text `#90A4AE`
    - Defined `ThemeData` with `brightness: Brightness.dark`, `ColorScheme.dark(...)`, Material 3 enabled
    - Configured `AppBarTheme`, `BottomNavigationBarTheme`, `CardTheme`, `InputDecorationTheme`, `ElevatedButtonThemeData`, `ChipTheme`, `SnackBarTheme`
    - _Requirements: NFR-04_

  - [x] 0.3.2 Create reusable form widgets
    - Created `lib/presentation/widgets/common/app_button.dart` — primary/secondary variants, loading state, disabled state
    - Created `lib/presentation/widgets/common/app_text_field.dart` — label, hint, error text, obscure text toggle for password fields
    - _Requirements: AUTH-01, LIST-01_

  - [x] 0.3.3 Create common UI feedback widgets
    - Created `lib/presentation/widgets/common/loading_overlay.dart` — full-screen semi-transparent loader
    - Created `lib/presentation/widgets/common/error_message.dart` — styled red error banner with optional retry action
    - Created `lib/presentation/widgets/common/empty_state.dart` — centered icon + title + subtitle + optional action button
    - _Requirements: BLoC-03, NFR-05_

  - **DELIVERABLE: Complete widget library available for all screens** ✅

- [x] 0.4 Define all domain models and enums - **BLOCKING TASK**
  - [x] 0.4.1 Create enums
    - Created `lib/domain/models/enums.dart`
    - Defined `PlaceCategory` enum: `hospital`, `policeStation`, `library`, `restaurantCafe`, `park`, `touristAttraction`, `utilityOffice`
    - Added `PlaceCategoryExtension` with `displayName`, `iconData`, `iconColor` getters
    - Added `toJson()` / `fromJson()` to the extension
    - _Requirements: LIST-06, SEARCH-02_

  - [x] 0.4.2 Create Listing model
    - Created `lib/domain/models/listing.dart` with `Listing` class
    - Fields: `id`, `name`, `category`, `address`, `contactNumber`, `description`, `latitude`, `longitude`, `createdBy`, `createdAt`, `updatedAt`
    - Implemented `toJson()`, `fromJson()`, `copyWith()`, `==`, `hashCode`, `toString()`
    - _Requirements: LIST-06, MAP-05_

  - [x] 0.4.3 Create UserProfile model
    - Created `lib/domain/models/user_profile.dart` with `UserProfile` class
    - Fields: `uid`, `email`, `displayName`, `createdAt`, `notificationsEnabled`
    - Implemented `toJson()`, `fromJson()`, `copyWith()`, `==`, `hashCode`
    - _Requirements: AUTH-05, SET-01_

  - [x] 0.4.4 Create validators
    - Created `lib/domain/validators/listing_validator.dart` — `validateName`, `validateAddress`, `validateContactNumber`, `validateDescription`, `validateLatitude`, `validateLongitude`
    - Created `lib/domain/validators/auth_validator.dart` — `validateEmail`, `validatePassword`, `validateConfirmPassword`, `validateDisplayName`
    - _Requirements: LIST-01, AUTH-01, NFR-07_

  - **DELIVERABLE: All domain models and validators in place — no Firebase imports in this layer** ✅

- [x] 0.5 CHECKPOINT — Foundation complete
  - `flutter pub get` runs with no errors ✅
  - `firebase_options.dart` exists and app connects to Firebase ✅
  - All common widgets can be imported with no errors ✅
  - `Listing` and `UserProfile` models serialize/deserialize without errors ✅
  - No compilation errors across the entire project (`flutter analyze` passes) ✅
  - App builds debug APK successfully ✅
  - **CRITICAL: Do not proceed to Phase 1 until this checkpoint passes** — Checkpoint passed ✅

---

### ✅ Phase 1: Core Features (START AFTER PHASE 0 COMPLETE)

---

#### Authentication

- [x] 1. Implement authentication data layer
  - **Implementation note**: Combined `AuthService` + `UserService` into a single `FirebaseAuthRepository` for clean architecture. The abstract interface lives in `lib/domain/repositories/auth_repository.dart`; the Firebase implementation in `lib/data/repositories/firebase_auth_repository.dart`.
  - [x] 1.1 AuthService functionality — implemented in `FirebaseAuthRepository.signIn()` and `register()`
  - [x] 1.2 UserService functionality — implemented in `FirebaseAuthRepository._fetchProfile()` and `register()` (creates Firestore doc)
  - [x] 1.3 AuthRepository abstract interface — `lib/domain/repositories/auth_repository.dart`
  - _Requirements: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, BLoC-01_

- [x] 2. Implement AuthBloc
  - [x] 2.1 Define AuthEvent classes — `lib/presentation/blocs/auth/auth_event.dart`
    - `AuthCheckRequested`, `AuthSignInRequested`, `AuthRegisterRequested`, `AuthVerificationEmailRequested`, `AuthSignOutRequested`, `_AuthUserChanged` (internal)
  - [x] 2.2 Define AuthState classes — `lib/presentation/blocs/auth/auth_state.dart`
    - `AuthInitial`, `AuthLoading`, `AuthAuthenticated(UserProfile)`, `AuthEmailNotVerified`, `AuthUnauthenticated`, `AuthFailure(message)`, `AuthVerificationEmailSent`
  - [x] 2.3 Implement AuthBloc — `lib/presentation/blocs/auth/auth_bloc.dart`
    - Subscribes to `authStateChanges` stream; maps Firebase errors to user-friendly messages
  - [ ]* 2.4 Write BLoC tests for AuthBloc — **Phase 2 task**
    - _Requirements: BLoC-03, BLoC-04_

- [x] 3. Build authentication UI screens
  - [x] 3.1 LoginScreen — `lib/presentation/screens/auth/login_screen.dart`
  - [x] 3.2 RegisterScreen — `lib/presentation/screens/auth/register_screen.dart` (replaces `signup_screen.dart` naming)
  - [x] 3.3 EmailVerificationScreen — `lib/presentation/screens/auth/email_verification_screen.dart`
  - [x] 3.4 AuthGate + main.dart wiring — `lib/presentation/screens/auth/auth_gate.dart`
    - Routes: `AuthInitial`/`AuthLoading` → spinner, `AuthEmailNotVerified` → EmailVerificationScreen, `AuthAuthenticated` → AppShell, else → LoginScreen
  - [x] 3.5 Google Sign-In — second auth provider alongside email/password
    - `pubspec.yaml`: added `google_sign_in: ^6.2.1`
    - Domain: `AuthRepository.signInWithGoogle()` abstract method
    - Data: `FirebaseAuthRepository.signInWithGoogle()` — Google picker → Firebase credential → Firestore profile upsert
    - BLoC: `AuthGoogleSignInRequested` event + `_onGoogleSignInRequested` handler; cancellation → `AuthUnauthenticated`; Google users bypass email verification (emailVerified always true)
    - UI: `LoginScreen` — OR divider + `OutlinedButton.icon` with Google SVG icon (network image with fallback)
    - ⚠️ **MANUAL STEP REQUIRED**: Enable Google provider in Firebase Console, register SHA-1, re-download `google-services.json` — see `SETUP.md §1.2`
    - Debug SHA-1: `49:D3:C4:49:14:FC:11:4D:C8:03:2A:EA:D5:9B:AC:89:70:0D:49:2A`
  - _Requirements: AUTH-02, AUTH-04, AUTH-06, AUTH-08, BLoC-06_

- [ ] 4. Checkpoint — Authentication complete
  - Sign up a new user → verify Firebase Console shows user → confirm `users/{uid}` doc created
  - Log in with unverified account → lands on EmailVerificationScreen
  - Verify email via link → re-open app → lands on AppShell
  - Log out → returns to LoginScreen
  - Tap "Continue with Google" → Google account picker → signs in → lands on AppShell

---

#### Listings CRUD

- [x] 5. Implement listings data layer ✅
  - **Implementation note**: Combined `ListingService` + `ListingRepository` into `FirebaseListingsRepository`. Abstract interface in `lib/domain/repositories/listings_repository.dart`.
  - [x] 5.1 + 5.2 — `lib/data/repositories/firebase_listings_repository.dart`
    - `watchListings({PlaceCategory? category})` — real-time stream, optional category filter
    - `getListingById(id)`, `createListing()`, `updateListing()`, `deleteListing()`
  - _Requirements: LIST-01, LIST-02, LIST-03, LIST-04, BLoC-01_

- [x] 6. Implement ListingsBloc
  - [x] 6.1 ListingsEvent — `lib/presentation/blocs/listings/listings_event.dart`
    - `ListingsSubscriptionRequested`, `ListingsCategoryChanged`, `ListingsSearchChanged`, `ListingCreated`, `ListingUpdated`, `ListingDeleted`, `_ListingsUpdated` (internal)
  - [x] 6.2 ListingsState — `lib/presentation/blocs/listings/listings_state.dart`
    - `ListingsInitial`, `ListingsLoading`, `ListingsLoaded(listings, filteredListings, selectedCategory, searchQuery)`, `ListingsActionSuccess(message)`, `ListingsError(message)`
  - [x] 6.3 ListingsBloc — `lib/presentation/blocs/listings/listings_bloc.dart`
    - Manages Firestore real-time subscription; client-side search filter in `_applyFilter()`
  - [ ]* 6.4 Write BLoC tests for ListingsBloc — **Phase 2 task**
  - _Requirements: LIST-05, SEARCH-03, SEARCH-04, BLoC-02, BLoC-03, BLoC-05, BLoC-06_

- [x] 7. Build listing card widget
  - Created `lib/presentation/widgets/listings/listing_card.dart`
  - Dark card with coloured category icon badge, name, address, category chip, chevron arrow
  - Created `lib/presentation/widgets/listings/category_filter_bar.dart` — horizontally scrollable `FilterChip` row
  - _Requirements: LIST-02, SEARCH-04_

- [x] 8. Build listings screens
  - [x] 8.1 Search bar — embedded in `ListingsScreen` AppBar `PreferredSize` widget
  - [x] 8.2 CategoryFilterBar — `lib/presentation/widgets/listings/category_filter_bar.dart`
  - [x] 8.3 ListingsScreen (DirectoryScreen) — `lib/presentation/screens/listings/listings_screen.dart`
    - Search bar + category filter + `ListView` of `ListingCard`; FAB to add listing
  - [x] 8.4 ListingFormScreen — `lib/presentation/widgets/listings/listing_form.dart` (shared form widget)
    - Add: `lib/presentation/screens/listings/add_listing_screen.dart`
    - Edit: `lib/presentation/screens/listings/edit_listing_screen.dart`
  - [x] 8.5 My Listings flow — **implementation note**: edit/delete gated by `canEdit` flag (only shown to the listing creator) rather than a separate "My Listings" tab; simplifies navigation to 3 tabs
  - _Requirements: LIST-01, LIST-02, LIST-03, LIST-04, LIST-05, SEARCH-01, SEARCH-02, BLoC-06_

- [x] 9. Checkpoint — Listings CRUD complete ✅
  - Create a listing → appears in list and Firebase Console in real time
  - Edit listing → changes reflected immediately
  - Delete listing → removed immediately
  - Search by name → correct results
  - Filter by category → correct results

---

#### Map Integration

- [x] 10. Implement map utilities
  - **Implementation note**: `url_launcher` called directly in `ListingDetailScreen._openInMaps()` rather than a separate utility file — keeps navigation logic co-located with the detail screen
  - _Requirements: MAP-04_

- [x] 11. Build MapViewScreen and ListingDetailScreen
  - [x] 11.1 MapViewScreen — `lib/presentation/screens/map/map_view_screen.dart`
    - Kigali centre `LatLng(-1.9441, 30.0619)`, zoom 13
    - Builds `Set<Marker>` from all listings with per-category `BitmapDescriptor` hue
    - Tap marker `infoWindow.onTap` → navigates to `ListingDetailScreen`
    - `ListingsError` state → `ErrorMessage` widget with retry
    - `_mapLoadFailed` flag → `ErrorMessage` if map widget fails to load
  - [x] 11.2 ListingDetailScreen — `lib/presentation/screens/listings/listing_detail_screen.dart`
    - Embedded `GoogleMap` (250px height) with single marker; zoom/scroll gestures disabled
    - "Get Directions" FAB opens `https://www.google.com/maps/search/?api=1&query=lat,lng`
    - Tappable phone number launches system dialler
    - Edit/delete actions shown only when `canEdit == true`
  - ⚠️ **MANUAL STEP REQUIRED**: Replace `YOUR_API_KEY` in `AndroidManifest.xml` — see `SETUP.md`
  - _Requirements: MAP-01, MAP-02, MAP-03, MAP-04, MAP-05, MAP-06_

- [x] 12. Checkpoint — Map integration complete ✅
  - MapViewScreen shows all listing markers at correct coordinates
  - Tap marker → ListingDetailScreen opens with correct data
  - Embedded map renders with marker at correct position
  - Tap "Get Directions" → Google Maps opens
  - ⚠️ Map will show blank/error until real API key is added

---

#### Settings

- [x] 13. Implement SettingsCubit
  - [x] 13.1 SettingsState — `lib/presentation/blocs/settings/settings_state.dart`
    - `SettingsInitial`, `SettingsLoaded(UserProfile)`, `SettingsSaving(UserProfile)`, `SettingsError(UserProfile, message)`
  - [x] 13.2 SettingsCubit — `lib/presentation/blocs/settings/settings_cubit.dart`
    - `loadProfile(UserProfile)`, `toggleNotifications(uid, enabled)` — updates Firestore `users/{uid}.notificationsEnabled`
  - _Requirements: SET-01, SET-02, SET-03_

- [x] 14. Build SettingsScreen
  - Created `lib/presentation/screens/settings/settings_screen.dart`
  - Profile card with `CircleAvatar` initials, display name, email
  - `SwitchListTile` for notifications toggle — persisted to Firestore
  - Sign Out button dispatches `AuthSignOutRequested` to `AuthBloc`
  - _Requirements: SET-01, SET-02, SET-03, SET-04_

- [x] 15. Checkpoint — Settings complete ✅
  - Settings screen displays correct user profile
  - Toggle notifications → Firestore `notificationsEnabled` updates
  - Tap Sign Out → returns to LoginScreen

---

#### Navigation Shell

- [x] 16. Build AppShell (MainNavigationScreen)
  - Created `lib/presentation/screens/shell/app_shell.dart`
  - `IndexedStack` with 3 tabs (preserves state): `ListingsScreen`, `MapViewScreen`, `SettingsScreen`
  - `BottomNavigationBar`: Places (`Icons.list_alt`), Map (`Icons.map`), Settings (`Icons.settings`)
  - **Implementation note**: 3-tab layout (Places / Map / Settings) rather than 4, since My Listings is accessed via edit/delete actions within the Places tab — keeps the nav bar clean
  - _Requirements: NAV-01, NAV-02, NAV-03, NAV-04, NAV-05_

- [x] 17. Checkpoint — Navigation complete ✅
  - All 3 tabs render without error
  - Switching tabs preserves scroll position (`IndexedStack`)
  - Map tab shows same listings as Places tab (shared `ListingsBloc`)
  - Creating a listing in Places tab immediately appears in Map tab

---

### ⬜ Phase 2: Polish, Testing & Submission

- [x] 18. Write unit tests for domain layer ✅
  - Create `test/unit/listing_model_test.dart` — `toJson`/`fromJson` round-trip, `copyWith`
  - Create `test/unit/listing_validator_test.dart` — all validators, boundary cases
  - Create `test/unit/auth_validator_test.dart` — email regex, password length
  - Create `test/bloc/auth_bloc_test.dart` — mock `AuthRepository` with `mockito`
  - Create `test/bloc/listings_bloc_test.dart` — mock `ListingsRepository`
  - _Requirements: NFR-04, NFR-07, BLoC-03, BLoC-04, BLoC-05_

- [ ] 19. Run full end-to-end manual test on Android emulator
  - Sign up → verify email → create 5 listings across different categories
  - Edit, delete, search, filter, map view, directions, settings toggle, logout

- [ ] 20. Write README.md
  - App name, description, screenshots
  - Features list, Firestore schema, BLoC data flow explanation
  - Firebase setup instructions, how to run locally
  - _Requirements: Code Quality rubric_

- [ ] 21. Write Design Summary Document (1–2 pages PDF)
  - Firestore schema, Listing model design, BLoC data flow diagram, design trade-offs

- [ ] 22. Write Implementation Reflection (PDF section)
  - Document ≥2 Firebase integration errors encountered with screenshots + resolutions
  - _Requirements: Deliverables rubric_

- [ ] 23. Verify Git commit history
  - Confirm ≥10 meaningful commits; push final code to GitHub

- [ ] 24. Record demo video (7–12 minutes)
  - Auth flow → CRUD → search/filter → map → directions → settings → code walkthrough

- [ ] 25. Final submission checklist
  - [ ] GitHub repository link confirmed public and accessible
  - [ ] README.md complete with all required sections
  - [ ] `flutter analyze` passes with no issues
  - [ ] App runs on Android emulator without crashes
  - [ ] Demo video is between 7–12 minutes
  - [ ] Design Summary PDF (1–2 pages) complete
  - [ ] Implementation Reflection PDF with ≥2 errors + screenshots
  - [ ] All items combined into single submission PDF
  - **DELIVERABLE: Complete submission PDF + GitHub repo + demo video uploaded**
