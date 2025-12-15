# Phase 2: Offline-First Sync Hardening - Complete

## ✅ Tamamlanan İyileştirmeler

### A) Local Timestamp for Conflict Resolution
- ✅ `localUpdatedAtMs: int` eklendi (GameProgressModel, CurrentRunModel)
- ✅ Her local save'de `localUpdatedAtMs = DateTime.now().millisecondsSinceEpoch`
- ✅ Remote write'da hem `localUpdatedAtMs` hem `serverTimestamp` kaydediliyor
- ✅ Conflict resolution artık `localUpdatedAtMs` kullanıyor (serverTimestamp değil)

### B) Progress Merge Strategy (Latest Wins Yerine)
- ✅ `_mergeProgress()` implement edildi
- ✅ `unlockedChapter`: `max(local, remote)`
- ✅ `unlockedLevel`: Chapter'a göre max
- ✅ `completed`: Union (set merge, duplicates removed)
- ✅ `stats`: MAX (double-counting önleme)
- ✅ `localUpdatedAtMs`: max(local, remote)

### C) CurrentRun Strategy
- ✅ LWW (Latest Wins) with `localUpdatedAtMs`
- ✅ `deviceId` eklendi (UUID v4, SharedPreferences)
- ✅ Multi-device conflict detection
- ✅ Warning log when different device

### D) Diff Check (Skip Duplicate Writes)
- ✅ Hash-based comparison
- ✅ `lastFlushedProgressHash` ve `lastFlushedRunHash` Hive'da saklanıyor
- ✅ Timestamp'ler hash'ten exclude ediliyor
- ✅ Identical hash → skip write
- ✅ Debounce korunuyor (2s) + diff check

### E) Retry with Backoff
- ✅ `_saveWithRetry()` implement edildi
- ✅ 3 attempts: 300ms, 800ms, 1500ms delays
- ✅ Sadece network/unavailable errors için retry
- ✅ Non-retryable errors: permission denied, invalid argument

### F) ClearCurrentRun Behavior
- ✅ Local: Delete key + clear dirty flag + clear hash
- ✅ Remote: Delete Firestore doc (with retry)
- ✅ `resumeGame()` returns `null` after clear
- ✅ Atomic operation (local + remote)

## 📁 Değiştirilen Dosyalar

### Domain Models
- `lib/core/domain/game_progress_model.dart` - `localUpdatedAtMs` eklendi
- `lib/core/domain/current_run_model.dart` - `localUpdatedAtMs` + `deviceId` eklendi

### Services
- `lib/core/services/local_state_store.dart` - Local timestamp kaydı + hash storage
- `lib/core/services/remote_state_store.dart` - Retry logic + hash computation
- `lib/core/services/sync_manager.dart` - Merge strategy + diff check + local timestamp conflict resolution

### Repositories
- `lib/core/repositories/game_state_repository.dart` - Device ID + local timestamp

### Utils
- `lib/core/utils/device_id_service.dart` - Device ID management (YENİ)

### Documentation
- `SYNC_MERGE_RULES.md` - Merge rules + timestamp logic (YENİ)
- `PHASE2_HARDENING_SUMMARY.md` - Bu dosya

## 🔧 Teknik Detaylar

### Conflict Resolution Flow
```
1. Load local + remote
2. Compare localUpdatedAtMs (NOT serverTimestamp)
3. Progress: Merge (not latest wins)
4. CurrentRun: Latest wins + device check
5. Save merged/selected state
```

### Diff Check Flow
```
1. Compute hash (data - timestamps)
2. Compare with lastFlushedHash
3. If identical → Skip write
4. If different → Write + update hash
```

### Retry Flow
```
1. Attempt write
2. On network error → Wait 300ms → Retry
3. On network error → Wait 800ms → Retry
4. On network error → Wait 1500ms → Retry
5. On non-retryable error → Fail immediately
```

## 📊 Console Logs

### Merge
- `[SYNC] mergeProgress applied`

### Skip
- `[SYNC] Skipped write (no diff): Progress`
- `[SYNC] Skipped write (no diff): CurrentRun`

### Clear
- `[SYNC] remote delete currentRun: {uid}`

### Timestamp
- `[LOCAL] Progress saved (localUpdatedAtMs: {timestamp})`
- `[LOCAL] Current run saved (localUpdatedAtMs: {timestamp})`

### Multi-Device
- `[SYNC] Current run: remote newer from different device ({deviceId1} vs {deviceId2}) - keeping remote`

## 🧪 Test Senaryoları

### 1. Conflict Resolution
- [ ] Local offline changes → Remote newer → Merge applied
- [ ] Remote offline changes → Local newer → Merge applied
- [ ] Both changed → Merge (no data loss)

### 2. Diff Check
- [ ] Same data → Skip write
- [ ] Different data → Write
- [ ] Hash stored correctly

### 3. Retry
- [ ] Network error → Retry 3 times
- [ ] Permission error → Fail immediately
- [ ] Success after retry

### 4. ClearCurrentRun
- [ ] Local cleared
- [ ] Remote cleared
- [ ] resumeGame() returns null

### 5. Multi-Device
- [ ] Device 1 saves → Device 2 loads → Device ID warning
- [ ] Latest wins with device awareness

## ⚠️ Yapılması Gerekenler

1. **Build Runner**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Test**
   - Conflict resolution testleri
   - Merge strategy testleri
   - Diff check testleri
   - Retry logic testleri

3. **Stats Strategy Decision**
   - Şu an MAX kullanılıyor (double-counting önleme)
   - Eğer stats gerçekten cumulative ise SUM'a geçilebilir
   - Karar: MAX (dokümante edildi)

## 📝 Notlar

- **localUpdatedAtMs** her zaman set edilmeli (offline conflict resolution için kritik)
- **deviceId** current run için multi-device tracking
- **Hash comparison** timestamps exclude ediyor (sadece data değişikliği kontrol ediliyor)
- **Merge strategy** progress için data loss önleme
- **Retry** sadece network errors için (permission errors retry edilmez)

