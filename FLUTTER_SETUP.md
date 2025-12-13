# Flutter Kurulum Rehberi

## Flutter PATH Sorunu

Flutter komutu tanınmıyor. Flutter'ı kurmanız veya PATH'e eklemeniz gerekiyor.

## Çözüm 1: Flutter'ı PATH'e Ekleme

### Windows'ta Flutter PATH'e Ekleme:

1. **Flutter SDK'nın konumunu bulun:**
   - Genellikle: `C:\src\flutter` veya `C:\flutter`
   - Veya kendi kurulum konumunuz

2. **Sistem Değişkenlerine Ekleme:**
   - Windows tuşu + R → `sysdm.cpl` yazın → Enter
   - "Gelişmiş" sekmesi → "Ortam Değişkenleri"
   - "Sistem değişkenleri" altında "Path" seçin → "Düzenle"
   - "Yeni" → Flutter bin klasörünün yolunu ekleyin:
     ```
     C:\src\flutter\bin
     ```
     (veya Flutter'ın kurulu olduğu klasör\bin)

3. **PowerShell'i Yeniden Başlatın:**
   - Mevcut PowerShell penceresini kapatın
   - Yeni bir PowerShell açın
   - `flutter doctor` komutunu tekrar deneyin

### PowerShell'de Geçici Olarak PATH'e Ekleme:

```powershell
$env:Path += ";C:\src\flutter\bin"
```

(Flutter'ın kurulu olduğu yolu kullanın)

## Çözüm 2: Flutter'ı Kurma

Eğer Flutter kurulu değilse:

### Windows'ta Flutter Kurulumu:

1. **Flutter SDK'yı İndirin:**
   - https://docs.flutter.dev/get-started/install/windows
   - ZIP dosyasını indirin ve çıkarın
   - Önerilen konum: `C:\src\flutter`

2. **PATH'e Ekleyin:**
   - Yukarıdaki "Çözüm 1" adımlarını takip edin

3. **Flutter Doctor Çalıştırın:**
   ```bash
   flutter doctor
   ```

4. **Eksik Bileşenleri Kurun:**
   - Flutter doctor size eksik olanları gösterecek
   - Android Studio, VS Code, Chrome vb. kurmanız gerekebilir

## Web Desteği İçin:

Flutter kurulduktan sonra web desteğini etkinleştirin:

```bash
flutter config --enable-web
```

## Hızlı Kontrol:

Flutter'ın kurulu olup olmadığını kontrol edin:

```powershell
# Flutter'ın olası konumlarını kontrol edin
Test-Path "C:\src\flutter\bin\flutter.bat"
Test-Path "C:\flutter\bin\flutter.bat"
Test-Path "$env:USERPROFILE\flutter\bin\flutter.bat"
```

Eğer bunlardan biri `True` dönerse, Flutter kurulu demektir, sadece PATH'e eklemeniz gerekiyor.

## Alternatif: Flutter'ı Bulma

Eğer Flutter kuruluysa ama nerede olduğunu bilmiyorsanız:

```powershell
# Tüm sürücülerde flutter.bat dosyasını arayın (uzun sürebilir)
Get-ChildItem -Path C:\ -Filter flutter.bat -Recurse -ErrorAction SilentlyContinue | Select-Object FullName
```

## Sonraki Adımlar:

1. Flutter'ı PATH'e ekleyin veya kurun
2. PowerShell'i yeniden başlatın
3. `flutter doctor` komutunu çalıştırın
4. Web desteğini etkinleştirin: `flutter config --enable-web`
5. Projeye dönün ve `flutter pub get` çalıştırın
6. `flutter run -d chrome` ile tarayıcıda çalıştırın

## Yardım:

- Flutter dokümantasyonu: https://docs.flutter.dev/get-started/install/windows
- Flutter kurulum sorunları: https://docs.flutter.dev/get-started/install/windows#troubleshooting

