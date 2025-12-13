# Game Presentation Layer - Riverpod State Management

## Overview

Bu katman, oyunun state management'ını Riverpod ile yönetir. `GameController` ve ilgili provider'lar oyun mantığını kontrol eder.

## Dosyalar

### `controllers/game_controller.dart`

Ana game controller ve provider'lar:

- **`GameRepository` Provider**: Puzzle generation için repository instance'ı sağlar
- **`GameStateNotifier`**: Oyun durumunu yöneten StateNotifier
- **`gameStateProvider`**: GameState'e erişim için convenience provider
- **`currentPuzzleProvider`**: Mevcut puzzle'a erişim için convenience provider
- **`gameStatusProvider`**: GameStatus'e erişim için convenience provider

### `utils/game_utils.dart`

Oyun işlemleri için yardımcı fonksiyonlar:

- Grid dönüşümleri (CellModel ↔ int)
- Puzzle tamamlanma kontrolü
- Hata işaretleme ve doğrulama
- İpucu ihlalleri alma

## Özellikler

### ✅ Tamamlanan Özellikler

1. **Yeni Oyun Başlatma**
   - `startNewGame(difficulty)` - Belirtilen zorlukta yeni oyun
   - `startDailyChallenge(difficulty)` - Günlük meydan okuma

2. **Hücre İşlemleri**
   - `onCellTap(row, col, {value})` - Hücre tıklama işleme
   - Boş → Güneş → Ay → Boş döngüsü
   - Verilen hücreleri düzenleme koruması

3. **Kalem Modu**
   - `togglePencilMode()` - Kalem modunu aç/kapat
   - `_handlePencilMark()` - Kalem işaretleri yönetimi

4. **Geri Al/Tekrarla**
   - `undo()` - Son hamleyi geri al
   - `redo()` - Geri alınan hamleyi tekrarla
   - 100 hamleye kadar geçmiş saklama

5. **Doğrulama**
   - `toggleAutoCheck()` - Otomatik hata kontrolü
   - Gerçek zamanlı hata işaretleme
   - GridValidator entegrasyonu

6. **İpucu Sistemi**
   - `showHint()` - İhlal eden satır/sütunu vurgula
   - 3 saniye sonra otomatik temizleme
   - İpucu sayacı

7. **Zamanlayıcı**
   - Speed Run ve Daily Challenge için otomatik başlatma
   - Duraklatma/devam ettirme desteği
   - Saniye bazlı zaman takibi

8. **Oyun Durumu**
   - Tamamlanma kontrolü
   - Duraklatma/devam ettirme
   - Oyun modu değiştirme (Zen/Speed Run/Daily)

## Kullanım Örnekleri

### Yeni Oyun Başlatma

```dart
final gameNotifier = ref.read(gameStateNotifierProvider.notifier);
await gameNotifier.startNewGame(PuzzleDifficulty.medium);
```

### Hücre Tıklama

```dart
final gameNotifier = ref.read(gameStateNotifierProvider.notifier);
gameNotifier.onCellTap(row, col);
// veya belirli bir değer ile
gameNotifier.onCellTap(row, col, value: GameConstants.cellSun);
```

### Geri Al/Tekrarla

```dart
final gameNotifier = ref.read(gameStateNotifierProvider.notifier);
gameNotifier.undo();
gameNotifier.redo();
```

### İpucu Gösterme

```dart
final gameNotifier = ref.read(gameStateNotifierProvider.notifier);
gameNotifier.showHint();
```

### State Okuma

```dart
// Widget içinde
final gameState = ref.watch(gameStateProvider);
final puzzle = ref.watch(currentPuzzleProvider);
final status = ref.watch(gameStatusProvider);

// Veya doğrudan notifier'dan
final gameNotifier = ref.read(gameStateNotifierProvider.notifier);
```

## Provider Yapısı

```
gameRepositoryProvider (Provider<GameRepository>)
    ↓
gameStateNotifierProvider (StateNotifierProvider<GameStateNotifier>)
    ↓
gameStateProvider (Provider<GameState>)
currentPuzzleProvider (Provider<PuzzleModel?>)
gameStatusProvider (Provider<GameStatus>)
```

## Notlar

- Timer otomatik olarak dispose edilir (ref.onDispose)
- Undo stack maksimum 100 hamle saklar
- Auto-check aktifken her hamle sonrası doğrulama yapılır
- İpucu gösterimi 3 saniye sonra otomatik temizlenir
- Verilen hücreler düzenlenemez

## Sonraki Adımlar

1. UI bileşenlerini bu provider'ları kullanacak şekilde güncelle
2. Animasyonlar ve haptik geri bildirim ekle
3. Ses efektleri entegrasyonu
4. Local storage ile oyun kaydetme/yükleme

