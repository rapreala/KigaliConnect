# KigaliConnect — Manual Setup Instructions

This document covers every step that **cannot be automated** — things that require browser-based console access, API key generation, or account credentials.

---

## 1. Firebase Console Setup

### 1.1 Enable Email/Password Authentication

1. Open [Firebase Console](https://console.firebase.google.com) → select project **kigali-connect-app**
2. Left sidebar → **Build → Authentication**
3. Click **Get started** (first time only)
4. **Sign-in method** tab → click **Email/Password**
5. Toggle **Enable** → click **Save**

### 1.2 Enable Google Sign-In

> **Requires the SHA-1 fingerprint from step 1.2a to be registered first.**

1. In **Authentication → Sign-in method** tab → click **Google**
2. Toggle **Enable**
3. Set **Project support email** (your Gmail address)
4. Click **Save**

#### 1.2a — Register the Android SHA-1 Fingerprint

Google Sign-In on Android requires your app's SHA-1 fingerprint to be registered in Firebase.

**Debug SHA-1 (use during development):**

```
49:D3:C4:49:14:FC:11:4D:C8:03:2A:EA:D5:9B:AC:89:70:0D:49:2A
```

**Debug SHA-256 (register both for completeness):**

```
D8:1A:C7:54:D6:F5:FA:10:79:6B:A0:D9:A7:C6:EA:7C:19:86:02:63:A7:81:E3:B3:F8:38:8E:AE:B5:C7:28:35
```

To register in Firebase Console:

1. Firebase Console → **Project Settings** (gear icon, top-left)
2. Scroll to **Your apps** → select the Android app (`com.kigaliconnect.kigali_connect`)
3. Click **Add fingerprint**
4. Paste the SHA-1 above → click **Save**
5. **Re-download `google-services.json`** after saving (the SHA-1 is now embedded in it):
   - Click **Download google-services.json** → replace `android/app/google-services.json`

> For a release build you will need a separate release SHA-1:
> `keytool -list -v -keystore <your-release.keystore> -alias <alias>` and register that too.

### 1.3 Create Firestore Database

1. Left sidebar → **Build → Firestore Database**
2. Click **Create database**
3. Select **Start in production mode** (you will apply security rules in step 1.4) (started it in debug mode)
4. Choose region: **europe-west1** (closest to Kigali) → click **Enable**
5. Wait for provisioning to complete

### 1.4 Apply Firestore Security Rules

1. In Firestore → **Rules** tab
2. Replace the existing rules with the following:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own profile
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    // Listings: any authenticated user can read
    // Create: only if createdBy matches the authenticated user
    // Update/Delete: only if the user owns the listing
    match /listings/{listingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
                    && request.resource.data.createdBy == request.auth.uid;
      allow update, delete: if request.auth != null
                             && resource.data.createdBy == request.auth.uid;
    }
  }
}
```

3. Click **Publish**
4. Verify — no red error banner appears

---

## 2. Google Maps API Key

The app requires a Google Maps API key for:
- `MapViewScreen` (full map with all listing markers)
- `ListingDetailScreen` (embedded 250px map preview)

### 2.1 Create the API Key

1. Open [Google Cloud Console](https://console.cloud.google.com)
2. Select the project linked to your Firebase project (or create a new one)
3. Left menu → **APIs & Services → Credentials**
4. Click **+ Create Credentials → API key**
5. Copy the generated key (you will use it in step 2.3)

### 2.2 Enable the Maps SDK for Android

1. In Google Cloud Console → **APIs & Services → Library**
2. Search for **Maps SDK for Android** → click it → click **Enable**
3. Also enable **Maps SDK for iOS** if you plan to run on iOS

### 2.3 Add the Key to AndroidManifest.xml

Open `android/app/src/main/AndroidManifest.xml` and find this line:

```xml
<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY"/>
```

Replace `YOUR_API_KEY` with your real key:

```xml
<meta-data android:name="com.google.android.geo.API_KEY" android:value="AIzaSy...your_actual_key..."/>
```

> ✅ **Done** — Android API key already set in `android/app/src/main/AndroidManifest.xml`.

### 2.4 (Optional) Restrict the API Key

To prevent unauthorised use of your key:

1. In Google Cloud Console → **APIs & Services → Credentials** → click your key
2. Under **Application restrictions** → select **Android apps**
3. Click **+ Add an item** → enter:
   - Package name: `com.kigaliconnect.kigali_connect`
   - SHA-1: `49:D3:C4:49:14:FC:11:4D:C8:03:2A:EA:D5:9B:AC:89:70:0D:49:2A` (debug)
4. Under **API restrictions** → select **Maps SDK for Android**
5. Click **Save**

---

## 3. iOS Setup (if targeting iOS)

### 3.1 Add API Key to AppDelegate

Open `ios/Runner/AppDelegate.swift` and add the Maps import and key:

```swift
import GoogleMaps

// inside application(_:didFinishLaunchingWithOptions:) before GeneratedPluginRegistrant.register
GMSServices.provideAPIKey("YOUR_API_KEY")
```

> ✅ **Done** — iOS API key already set in `ios/Runner/AppDelegate.swift`.

### 3.2 Verify GoogleService-Info.plist

Confirm `ios/Runner/GoogleService-Info.plist` was generated by `flutterfire configure`. If not, download it from:

Firebase Console → Project Settings → Your apps → iOS app → **Download GoogleService-Info.plist**

Place it in `ios/Runner/` and add it to the Xcode project.

---

## 4. Run the App Locally

```bash
# Install dependencies
cd "Mobile Dev_Individual Assignment 2"
flutter pub get

# Run on a connected device or emulator
flutter run

# Run on a specific device
flutter devices              # list available devices
flutter run -d <device-id>

# Build release APK
flutter build apk --release
```

### 4.1 Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Flutter | ≥ 3.10 | `flutter --version` |
| Dart | ≥ 3.0 | `dart --version` |
| Java | ≥ 17 | `java -version` |
| Android Studio | ≥ Flamingo | For emulator |
| Firebase CLI | any | `firebase --version` |

---

## 5. Environment Verification Checklist

Run these checks before the Phase 0 checkpoint:

```bash
# 1. Flutter analyze — must show "No issues found"
flutter analyze --no-pub

# 2. Build debug APK — must succeed
flutter build apk --debug

# 3. Confirm firebase_options.dart exists
ls lib/firebase_options.dart

# 4. Confirm google-services.json exists
ls android/app/google-services.json
```

In the Firebase Console, verify:
- [ ] `kigali-connect-app` project exists
- [ ] Email/Password auth is **Enabled** under Authentication → Sign-in method
- [ ] Google Sign-In is **Enabled** under Authentication → Sign-in method
- [ ] SHA-1 `49:D3:C4:49:14:FC:11:4D:C8:03:2A:EA:D5:9B:AC:89:70:0D:49:2A` registered under Project Settings → Android app
- [ ] `google-services.json` re-downloaded after SHA-1 registration
- [ ] Firestore database is **Active**
- [ ] Firestore security rules are **Published**

In `AndroidManifest.xml`, verify:
- [ ] `com.google.android.geo.API_KEY` value is **not** `YOUR_API_KEY`

---

## 6. Common Issues

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| Map shows grey/blank | API key missing or wrong | Replace `YOUR_API_KEY` in AndroidManifest.xml |
| Map shows "This page can't load Google Maps correctly" | Billing not enabled on Google Cloud project | Enable billing at console.cloud.google.com |
| `PlatformException(sign_in_failed)` on email/password | Firebase Auth not enabled | Enable Email/Password in Firebase Console |
| Google Sign-In silently fails / `ApiException: 10` | SHA-1 not registered or stale `google-services.json` | Register SHA-1 in Project Settings; re-download `google-services.json` |
| Google Sign-In button dismisses immediately | SHA-1 missing from Firebase project | See step 1.2a |
| `permission-denied` on Firestore write | Security rules not published | Publish rules from step 1.4 |
| `google-services.json` errors in build | Wrong package name or missing file | Re-run `flutterfire configure` |
| App crashes on launch with Firebase error | `firebase_options.dart` missing | Run `flutterfire configure --project=kigali-connect-app` |
