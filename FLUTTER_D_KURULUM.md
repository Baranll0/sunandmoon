# Flutter D Sürücüsüne Kurulum

## ✅ D Sürücüsüne Kurulum Tamamen Sorunsuz!

Flutter'ı D sürücüsüne kurmak hiçbir sorun yaratmaz. Sadece PATH'e doğru yolu eklemeniz yeterli.

## 📋 Adım Adım Kurulum

### 1. Flutter SDK'yı İndirin
- https://docs.flutter.dev/get-started/install/windows
- "Download Flutter SDK" butonuna tıklayın
- ZIP dosyasını indirin

### 2. D Sürücüsüne Çıkarın
Örnek konumlar:
- `D:\flutter` ✅
- `D:\flutter_windows_3.38.4-stable\flutter` ✅ (ZIP'ten çıkarıldığı gibi)
- `D:\Development\flutter` ✅
- `D:\Programs\flutter` ✅
- `D:\src\flutter` ✅

**Önemli:** İçinde `bin` klasörü olmalı (örnek: `D:\flutter_windows_3.38.4-stable\flutter\bin`)

### 3. PATH'e Ekleyin

**Yöntem 1: PowerShell ile Otomatik Ekleme (Önerilen - Kalıcı)**
PowerShell'i yönetici olarak açın ve şu komutu çalıştırın:
```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";D:\flutter_windows_3.38.4-stable\flutter\bin", [EnvironmentVariableTarget]::User)
```
(Kendi yolunuzu kullanın: `D:\flutter_windows_3.38.4-stable\flutter\bin`)

**Yöntem 2: Sistem Ortam Değişkenleri (Manuel - Kalıcı)**
1. Windows tuşu + R → `sysdm.cpl` → Enter
2. "Gelişmiş" sekmesi → "Ortam Değişkenleri"
3. "Kullanıcı değişkenleri" veya "Sistem değişkenleri" altında "Path" seçin → "Düzenle"
4. "Yeni" → Flutter bin klasörünün yolunu ekleyin:
   ```
   D:\flutter_windows_3.38.4-stable\flutter\bin
   ```
   (veya kurduğunuz yola göre)

5. "Tamam" → "Tamam" → PowerShell'i yeniden başlatın

**Yöntem 3: PowerShell'de Geçici (Sadece bu oturum için)**
```powershell
$env:Path += ";D:\flutter_windows_3.38.4-stable\flutter\bin"
```
(Kendi yolunuzu kullanın)

### 4. Test Edin
```powershell
flutter doctor
```

### 5. Web Desteğini Etkinleştirin
```powershell
flutter config --enable-web
```

## ✅ Örnek Yol Yapısı

Eğer `D:\flutter_windows_3.38.4-stable\flutter` konumuna kurduysanız:
```
D:\flutter_windows_3.38.4-stable\
  └── flutter\
      ├── bin\
      │   └── flutter.bat  ← Bu dosya olmalı
      ├── packages\
      ├── examples\
      └── ...
```

PATH'e eklemeniz gereken: `D:\flutter_windows_3.38.4-stable\flutter\bin`

Eğer `D:\flutter` konumuna kurduysanız:
```
D:\flutter\
  ├── bin\
  │   └── flutter.bat  ← Bu dosya olmalı
  ├── packages\
  ├── examples\
  └── ...
```

PATH'e eklemeniz gereken: `D:\flutter\bin`

## 🎯 Projeyi Çalıştırma

Flutter kurulduktan sonra:

```powershell
# Proje klasörüne gidin (zaten oradasınız)
cd D:\MobileProject

# Bağımlılıkları yükleyin
flutter pub get

# Kod üretimi
flutter pub run build_runner build --delete-conflicting-outputs

# Chrome'da çalıştırın
flutter run -d chrome
```

## ⚠️ Notlar

- ✅ D sürücüsüne kurulum tamamen güvenli
- ✅ Performans farkı yok
- ✅ Tüm özellikler çalışır
- ✅ Sadece PATH'e doğru yolu eklemek önemli

## 🔍 PATH Kontrolü

PATH'e doğru eklenip eklenmediğini kontrol edin:

```powershell
$env:Path -split ';' | Select-String flutter
```

Bu komut Flutter yolunu gösterirse, PATH'e eklenmiş demektir.

## 🎉 Hazır!

Flutter'ı D sürücüsüne kurduktan ve PATH'e ekledikten sonra, projeyi çalıştırabilirsiniz!


