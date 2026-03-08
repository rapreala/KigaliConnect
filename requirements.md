# KigaliConnect — Requirements Document

## 1. Project Overview

**App Name:** KigaliConnect
**Platform:** Flutter (Android & iOS — must run on emulator or physical device)
**Backend:** Firebase Authentication + Cloud Firestore
**State Management:** flutter_bloc (full BLoC — Events + States)
**Purpose:** A city services and places directory app helping Kigali residents locate and navigate to essential public services and leisure locations.

---

## 2. Functional Requirements

### 2.1 Authentication

| ID | Requirement |
|----|-------------|
| AUTH-01 | Users must be able to sign up with email and password via Firebase Authentication |
| AUTH-02 | Users must be able to log in with email and password |
| AUTH-03 | Users must be able to log out securely |
| AUTH-04 | Email verification must be enforced — unverified users cannot access the app |
| AUTH-05 | On successful sign-up, a user profile document must be created in Firestore under `users/{uid}` |
| AUTH-06 | The app must listen to Firebase Auth state changes and route users accordingly (unauthenticated → Login, unverified → Verify Email, verified → Directory) |
| AUTH-07 | All listing operations must be scoped to the authenticated user's UID |
| AUTH-08 | Users must be able to sign in with Google via Firebase Authentication (Google Sign-In button on LoginScreen) |

### 2.2 Location Listings (CRUD)

| ID | Requirement |
|----|-------------|
| LIST-01 | Authenticated users must be able to create a new listing stored in Firestore |
| LIST-02 | All listings must be readable by any authenticated user in the shared directory |
| LIST-03 | Users must be able to update listings they created (identified by `createdBy == currentUser.uid`) |
| LIST-04 | Users must be able to delete listings they created |
| LIST-05 | Listing changes (create/update/delete) must be reflected in the UI immediately via state management |
| LIST-06 | Direct Firestore calls inside UI widgets are strictly prohibited |

**Each listing must contain:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Auto-generated Firestore document ID |
| `name` | String | Place or service name |
| `category` | String (enum) | Hospital, Police Station, Library, Restaurant/Café, Park, Tourist Attraction, Utility Office |
| `address` | String | Physical address in Kigali |
| `contactNumber` | String | Phone number |
| `description` | String | Brief description of the place/service |
| `latitude` | double | Geographic latitude |
| `longitude` | double | Geographic longitude |
| `createdBy` | String | UID of the user who created the listing |
| `createdAt` | Timestamp | Creation timestamp |
| `updatedAt` | Timestamp | Last update timestamp |

### 2.3 Directory Search and Filtering

| ID | Requirement |
|----|-------------|
| SEARCH-01 | Users must be able to search listings by name (case-insensitive, client-side) |
| SEARCH-02 | Users must be able to filter listings by category |
| SEARCH-03 | Search and filter can be combined simultaneously |
| SEARCH-04 | Results must update dynamically as Firestore data changes (via real-time stream) |
| SEARCH-05 | An empty state must be shown when no results match the search/filter |

### 2.4 Detail Page and Map Integration

| ID | Requirement |
|----|-------------|
| MAP-01 | Selecting a listing navigates to a detail page showing all listing fields |
| MAP-02 | The detail page must include an embedded Google Map (via `google_maps_flutter`) |
| MAP-03 | A marker must be placed on the map at the listing's stored latitude/longitude |
| MAP-04 | A "Get Directions" button must launch Google Maps with turn-by-turn navigation to the listing location |
| MAP-05 | Coordinates must come from Firestore — hardcoded coordinates are not acceptable |
| MAP-06 | Both map screens (MapViewScreen and ListingDetailScreen) must handle map loading failure gracefully — show an error message if the map cannot render (e.g. missing API key, no internet) |

### 2.5 State Management (BLoC)

| ID | Requirement |
|----|-------------|
| BLoC-01 | All Firestore read/write operations must go through a dedicated service layer |
| BLoC-02 | The service layer must be exposed to the UI via BLoC (Events + States) |
| BLoC-03 | Loading, success, and error states must be handled for all CRUD operations |
| BLoC-04 | `AuthBloc` must manage authentication state and route the user appropriately |
| BLoC-05 | `ListingsBloc` must manage the directory listings, my listings, search, and filter states |
| BLoC-06 | UI widgets must consume BLoC states via `BlocBuilder` / `BlocListener` — never via direct service calls |

### 2.6 Navigation

| ID | Requirement |
|----|-------------|
| NAV-01 | The app must use a `BottomNavigationBar` with 4 tabs |
| NAV-02 | Tab 1 — Directory: Browse all listings with search and filter |
| NAV-03 | Tab 2 — My Listings: View, edit, and delete the authenticated user's own listings |
| NAV-04 | Tab 3 — Map View: Full-screen map showing all listings as markers |
| NAV-05 | Tab 4 — Settings: User profile info and notification toggle |
| NAV-06 | Tapping a listing card navigates to a detail screen (pushed on top of the current tab) |
| NAV-07 | Add/Edit listing uses a form screen pushed modally or as a route |

### 2.7 Settings

| ID | Requirement |
|----|-------------|
| SET-01 | The Settings screen must display the authenticated user's display name and email |
| SET-02 | A toggle must allow users to enable or disable location-based notifications |
| SET-03 | The notification preference must be persisted in Firestore under `users/{uid}` |
| SET-04 | A logout button must be present and trigger `LogOutRequested` event on the `AuthBloc` |

---

## 3. Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-01 | The app must run on an Android emulator or physical Android/iOS device (not web-only) |
| NFR-02 | Firestore offline persistence must be enabled so listings load without internet |
| NFR-03 | All submitted code must be original — AI-generated code must not exceed 50% |
| NFR-04 | The app must follow clean architecture: domain → data → presentation separation |
| NFR-05 | Error messages must be shown to the user (not just printed to console) |
| NFR-06 | The app must handle network errors gracefully without crashing |
| NFR-07 | Form inputs must be validated before submission (name, contact, coordinates) |
| NFR-08 | Firebase credentials must not be exposed in the repository (use `firebase_options.dart` via FlutterFire CLI) |
| NFR-09 | A valid Google Maps API key must be configured in `AndroidManifest.xml` — the app must not be submitted with a placeholder or missing key |

---

## 4. Out of Scope

- Facebook / other social login — Google Sign-In is supported (see AUTH-08)
- In-app notifications (a local toggle simulation is sufficient)
- Payments or booking functionality
- Admin panel or moderation tools
- User-to-user messaging

---

## 5. Firestore Database Structure

```
Firestore Root
│
├── users/
│   └── {uid}/
│       ├── uid: string
│       ├── email: string
│       ├── displayName: string
│       ├── createdAt: timestamp
│       └── notificationsEnabled: boolean
│
└── listings/
    └── {listingId}/
        ├── id: string
        ├── name: string
        ├── category: string          // enum value e.g. "hospital"
        ├── address: string
        ├── contactNumber: string
        ├── description: string
        ├── latitude: number
        ├── longitude: number
        ├── createdBy: string         // user UID
        ├── createdAt: timestamp
        └── updatedAt: timestamp
```

**Firestore Security Rules (intended):**
- Any authenticated user can read all listings
- A user can only write (create/update/delete) listings where `createdBy == request.auth.uid`
- A user can only read/write their own user profile document

---

## 6. Place Categories

```dart
enum PlaceCategory {
  hospital,
  policeStation,
  library,
  restaurantCafe,
  park,
  touristAttraction,
  utilityOffice,
}
```

Display labels:
- `hospital` → "Hospital"
- `policeStation` → "Police Station"
- `library` → "Library"
- `restaurantCafe` → "Restaurant / Café"
- `park` → "Park"
- `touristAttraction` → "Tourist Attraction"
- `utilityOffice` → "Utility Office"
