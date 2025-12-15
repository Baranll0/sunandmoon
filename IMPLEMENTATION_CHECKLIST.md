# Offline-First Firebase Implementation Checklist

## ✅ Tamamlanan

- [x] Firebase paketleri eklendi (firebase_core, firebase_auth, cloud_firestore, google_sign_in)
- [x] connectivity_plus eklendi
- [x] Hive local cache (LocalStateStore)
- [x] Remote state store (RemoteStateStore)
- [x] SyncManager (connectivity + lifecycle + debounce)
- [x] GameStateRepository (UI entegrasyonu)
- [x] Game controller entegrasyonu
- [x] Auth gate entegrasyonu
- [x] Firestore security rules
- [x] Domain models (User, GameProgress, CurrentRun, UserSettings)

## 🔧 Yapılması Gerekenler

### 1. Build Runner
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Firebase Console Setup
- [ ] Firebase projesi oluştur
- [ ] Authentication → Google provider enable
- [ ] Firestore Database oluştur
- [ ] `firestore.rules` dosyasını yükle
- [ ] Android: `google-services.json` ekle
- [ ] SHA-1/SHA-256 fingerprint'leri ekle

### 3. Resume Game UI
- [ ] App açılışında current run kontrolü
- [ ] Dialog: "Devam et" / "Yeniden başla"
- [ ] Current run'dan game state restore

### 4. Test Senaryoları
- [ ] Offline oynama → app kapat/aç → devam et
- [ ] Online sync test
- [ ] Debounce test (hamle spam)
- [ ] Level complete → progress kaydı
- [ ] Multi-device sync

### 5. Error Handling
- [ ] Network error retry
- [ ] Local cache corruption handling
- [ ] Firestore write failures

## 📝 Notlar

- SyncManager provider async olduğu için `.future` kullanılmalı
- GameStateRepository provider async olduğu için `.future` kullanılmalı
- Local cache her zaman source of truth
- Remote sync sadece online ise çalışır
- Debounce: 2 saniye (hamle spam önleme)
- Immediate flush: connectivity online, app paused, level complete

