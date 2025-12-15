# Firebase Setup Guide

## 1. Firebase Console Setup

### 1.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "Tango Logic" (or your preferred name)
4. Enable Google Analytics (optional)
5. Create project

### 1.2 Enable Authentication
1. Go to **Authentication** → **Sign-in method**
2. Enable **Google** provider
3. Add your app's SHA-1/SHA-256 fingerprints (for Android)
4. Save

### 1.3 Enable Firestore
1. Go to **Firestore Database**
2. Click "Create database"
3. Start in **production mode** (we'll add rules)
4. Choose location (closest to your users)
5. Enable

### 1.4 Add Firestore Security Rules
1. Go to **Firestore Database** → **Rules**
2. Copy contents from `firestore.rules` file
3. Paste and publish

## 2. Android Setup

### 2.1 Add google-services.json
1. In Firebase Console, go to **Project Settings** → **Your apps**
2. Click Android icon
3. Enter package name: `com.example.sun_moon_puzzle` (check your `build.gradle`)
4. Download `google-services.json`
5. Place it in `android/app/` directory

### 2.2 Update build.gradle
1. Open `android/build.gradle`
2. Add to `dependencies`:
```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

3. Open `android/app/build.gradle`
4. Add at the bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 2.3 Get SHA-1/SHA-256
For debug:
```bash
cd android
./gradlew signingReport
```

For release:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Add SHA-1 and SHA-256 to Firebase Console → Authentication → Sign-in method → Google

## 3. iOS Setup (if applicable)

### 3.1 Add GoogleService-Info.plist
1. In Firebase Console, add iOS app
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/` directory
4. Add to Xcode project

### 3.2 Update Info.plist
Add URL scheme (Firebase will provide this)

## 4. Web Setup (if applicable)

### 4.1 Add Firebase Config
1. In Firebase Console, add Web app
2. Copy Firebase config
3. Add to `web/index.html` or use environment variables

## 5. Testing

### 5.1 Test Authentication
1. Run app
2. Click "Continue with Google"
3. Sign in with test account
4. Verify user appears in Firebase Console → Authentication

### 5.2 Test Firestore
1. Complete a level
2. Check Firebase Console → Firestore
3. Verify data in `users/{uid}/game/progress`

## 6. Troubleshooting

### Common Issues

**"Google Sign-In failed"**
- Check SHA-1/SHA-256 are added to Firebase Console
- Verify `google-services.json` is in correct location
- Check package name matches Firebase project

**"Permission denied"**
- Verify Firestore rules are published
- Check user is authenticated
- Verify UID matches document path

**"Firebase not initialized"**
- Check `google-services.json` exists
- Verify Firebase is initialized before use
- Check internet connection

## 7. Production Checklist

- [ ] Enable App Check (optional, for security)
- [ ] Set up Firebase Analytics
- [ ] Configure Crashlytics (optional)
- [ ] Review Firestore rules
- [ ] Test offline persistence
- [ ] Test multi-device sync
- [ ] Set up backup/export strategy

