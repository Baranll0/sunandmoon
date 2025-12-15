# Eksik Kalan İşler - Missing Items Checklist

## ✅ Tamamlananlar

1. ✅ **Chapter/Level Structure** - Yeni yapı implement edildi (Ch1:10, Ch2:60, Ch3:70, Ch4:60)
2. ✅ **Mechanic System** - Model, enum, registry oluşturuldu
3. ✅ **Journey Map Path Fix** - Path scroll ile birlikte hareket ediyor
4. ✅ **Victory Dialog** - Sadece "Next Level" butonu var
5. ✅ **Next Level Flow** - Journey Map'e navigate ediyor, focus yapıyor
6. ✅ **Language Switcher** - Settings'te dropdown var (TR/EN/DE/FR)
7. ✅ **Chapter Difficulty Mapping** - Yeni yapıya göre güncellendi
8. ✅ **Progress Update** - Doğru şekilde cumulative stats hesaplanıyor

## ⚠️ Eksik Kalanlar

### 1. Level Pack Generation (ÖNEMLİ)
**Durum:** Henüz çalıştırılmadı

**Yapılacak:**
```bash
dart tool/build_level_packs.dart --chapters=1..4
```

**Kontrol:**
- [ ] `assets/levels/chapter_01.json` - 10 level içermeli
- [ ] `assets/levels/chapter_02.json` - 60 level içermeli
- [ ] `assets/levels/chapter_03.json` - 70 level içermeli
- [ ] `assets/levels/chapter_04.json` - 60 level içermeli
- [ ] `assets/levels/index.json` - Metadata güncellenmeli
- [ ] Her level JSON'da `mechanics` ve `params` field'ları olmalı

### 2. Mechanics UI Entegrasyonu
**Durum:** Backend hazır, UI entegrasyonu yok

**Yapılacak:**
- [ ] Level başlangıç ekranında mechanic badge'leri göster
- [ ] Mechanic açıklamalarını help/rules ekranında göster
- [ ] Game controller'da `moveLimit` enforcement
- [ ] Game controller'da `mistakeLimit` enforcement
- [ ] `regions` mechanic için UI gösterimi (board'da region boundaries)

**Dosyalar:**
- `lib/features/game/presentation/screens/game_screen.dart` - Mechanic badge ekle
- `lib/features/game/presentation/controllers/game_controller.dart` - Limit enforcement

### 3. Localization - ARB Migration (İsteğe Bağlı)
**Durum:** Mevcut AppStrings sistemi çalışıyor, ARB migration büyük refactoring

**Yapılacak:**
- [ ] `app_en.arb`, `app_tr.arb`, `app_de.arb`, `app_fr.arb` dosyaları oluştur
- [ ] `flutter_localizations` + `intl` entegrasyonu
- [ ] `AppStrings` class'ını ARB'den okuyacak şekilde refactor et
- [ ] Tüm hardcoded string'leri kontrol et ve ARB'ye ekle

**Not:** Mevcut sistem çalışıyor, bu isteğe bağlı bir iyileştirme.

### 4. Unlock Animation İyileştirmeleri
**Durum:** Temel unlock animation var, path reveal animation yok

**Yapılacak:**
- [ ] Path segment reveal animation (önceki node'dan sonraki node'a çizim)
- [ ] Lock icon crack animation
- [ ] Smooth transition testleri

**Dosyalar:**
- `lib/features/home/screens/saga_map_screen.dart` - Path reveal animation
- `lib/features/home/screens/saga_map_screen.dart` - Lock crack animation

### 5. Test ve Doğrulama
**Durum:** Manual test gerekiyor

**Test Checklist:**
- [ ] Chapter 1'de 10 level var mı?
- [ ] Chapter 2'de 60 level var mı?
- [ ] Chapter 3'te 70 level var mı?
- [ ] Chapter 4'te 60 level var mı?
- [ ] Journey Map'te path scroll ile birlikte hareket ediyor mu?
- [ ] Level complete → Next Level → Journey Map'e gidiyor mu?
- [ ] Next node focus ediliyor mu?
- [ ] Unlock animation çalışıyor mu?
- [ ] Progress doğru kaydediliyor mu?
- [ ] Offline-first sync çalışıyor mu?

## 📝 Notlar

- **Level Pack Generation** en önemli eksik - level'lar generate edilmeden oyun çalışmaz
- **Mechanics UI** kullanıcı deneyimi için önemli ama oyun çalışır durumda
- **ARB Migration** isteğe bağlı - mevcut sistem yeterli
- **Unlock Animation** iyileştirmeleri nice-to-have

## 🚀 Hızlı Başlangıç

En önemli eksik olan level pack generation'ı çalıştır:

```bash
cd D:\MobileProject
dart tool/build_level_packs.dart --chapters=1..4
```

Bu komut:
1. 4 chapter için level'ları generate eder
2. `assets/levels/chapter_XX.json` dosyalarını oluşturur
3. `assets/levels/index.json` dosyasını günceller
4. Her level'a mechanics ve params ekler

