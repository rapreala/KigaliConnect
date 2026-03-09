# KigaliConnect — City Directory & Navigation

A Flutter mobile application that helps users discover, navigate to, and manage essential public services and leisure locations across Kigali, Rwanda.

---

## Features

| Feature | Details |
|---|---|
| **Authentication** | Email/password sign-up with email verification, Google Sign-In, profile stored in Firestore |
| **Place Directory** | Browse all Kigali listings with real-time Firestore updates |
| **Category Filter** | Instantly filter by Hospital, Police Station, Library, Restaurant/Café, Park, Tourist Attraction, Utility Office |
| **Full-text Search** | Search across name, address, and description fields |
| **CRUD Listings** | Create, edit, and delete your own listings with live auto-geocoding from address |
| **My Listings Tab** | Dedicated tab showing only your own listings with edit/delete actions |
| **Map View** | Google Maps with colour-coded markers per category; tap to open detail screen |
| **Get Directions** | One-tap navigation opens Google Maps with route to selected place |
| **Settings** | Dark/light theme toggle (persisted via SharedPreferences), notifications preference, sign out |
| **Offline Support** | Firestore persistence cache — browse previously loaded data without internet |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| State Management | flutter_bloc 8.x — BLoC pattern (Events + States) |
| Backend | Firebase Auth + Cloud Firestore |
| Maps | google_maps_flutter + url_launcher |
| Geocoding | geocoding package — address → lat/lng |
| Theme Persistence | shared_preferences |
| Testing | flutter_test, bloc_test, mockito |

---

## Project Structure

```
lib/
├── config/           # Theme, colours, spacing constants
├── domain/
│   ├── models/       # Listing, UserProfile, PlaceCategory enum
│   ├── repositories/ # Abstract interfaces (no Firebase imports)
│   └── validators/   # Form validation — auth and listing fields
├── data/
│   └── repositories/ # Firebase implementations of domain interfaces
└── presentation/
    ├── blocs/        # AuthBloc, ListingsBloc, SettingsCubit, ThemeCubit
    ├── screens/      # auth/, listings/, map/, settings/, shell/
    └── widgets/      # Common and listing-specific reusable widgets
test/
├── unit/             # Model serialisation, validator boundary cases
└── bloc/             # BLoC tests with mockito mocks
```

---

## Firestore Schema

### `users/{uid}`
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "createdAt": "Timestamp",
  "notificationsEnabled": "bool"
}
```

### `listings/{listingId}`
```json
{
  "id": "string",
  "name": "string",
  "category": "string (enum name)",
  "address": "string",
  "contactNumber": "string",
  "description": "string",
  "latitude": "number",
  "longitude": "number",
  "createdBy": "string (uid)",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

**Security rules:**
- `users/{uid}` — read/write only if `request.auth.uid == uid`
- `listings/{id}` — any authenticated user can read; create requires `createdBy == uid`; update/delete requires `resource.data.createdBy == uid`

---

## BLoC Data Flow

```
UI Event ──► ListingsBloc ──► ListingsRepository ──► Firestore
                │                                        │
                │          real-time stream              │
                ◄────────────────────────────────────────┘
                │
                ▼
         ListingsState
    ┌─────────────────────┐
    │  allListings        │  ← all Firestore docs (used by MapViewScreen)
    │  listings           │  ← category-filtered
    │  filteredListings   │  ← category + search filtered (used by Places tab)
    │  selectedCategory   │
    │  searchQuery        │
    └─────────────────────┘
```

- **Client-side filtering**: category and search filters are applied in-memory so switching is instant without a new Firestore round-trip.
- **Optimistic updates**: create/update/delete mutate `_allListings` immediately before Firestore confirms, so the UI responds instantly.
- **Auto-resubscribe**: stream errors trigger `_ListingsStreamErrored` which restarts the Firestore subscription to keep real-time updates alive.

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.10
- Android Studio / VS Code with Flutter plugin
- Firebase project with Auth and Firestore enabled
- Google Maps API key with Maps SDK for Android enabled

### Firebase Setup

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password** and **Google** sign-in providers
3. Enable **Cloud Firestore** (start in production mode)
4. Run `flutterfire configure` to generate `lib/firebase_options.dart`
5. Place `google-services.json` in `android/app/`
6. Apply security rules from the schema section above

### Google Maps Setup

1. Obtain an API key from [Google Cloud Console](https://console.cloud.google.com)
2. Enable **Maps SDK for Android** for the key
3. Replace the value in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="YOUR_API_KEY_HERE"/>
   ```

### Run Locally

```bash
flutter pub get
flutter run
```

### Run Tests

```bash
# Unit and BLoC tests (102 tests)
flutter test test/unit/ test/bloc/

# Regenerate mockito mocks if models change
dart run build_runner build --delete-conflicting-outputs
```

---

## Place Categories

| Category | Colour |
|---|---|
| Hospital | Red |
| Police Station | Blue |
| Library | Purple |
| Restaurant / Café | Orange |
| Park | Green |
| Tourist Attraction | Yellow |
| Utility Office | Cyan |

---

## Author

Developed as Individual Assignment 2 — Mobile Development
African Leadership University, 2025
