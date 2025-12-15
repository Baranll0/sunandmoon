# Sync Merge Rules & Timestamp Logic

## Timestamp Strategy

### Local Timestamp (`localUpdatedAtMs`)
- **Purpose**: Reliable conflict resolution when offline
- **Type**: `int` (milliseconds since epoch)
- **Set on**: Every local save
- **Used for**: Conflict resolution (comparing local vs remote)

### Server Timestamp (`updatedAt`)
- **Purpose**: Firestore server timestamp for audit
- **Type**: `DateTime` (Firestore Timestamp)
- **Set on**: Remote writes only
- **Used for**: Display, sorting (not conflict resolution)

### Conflict Resolution Logic
```dart
// Compare localUpdatedAtMs (NOT serverTimestamp)
if (remote.localUpdatedAtMs > local.localUpdatedAtMs) {
  // Use remote
} else {
  // Use local
}
```

**Why?** Server timestamps can be null/ambiguous when offline. Local timestamps are always available and comparable.

## Progress Merge Strategy

### Rules (NOT Latest Wins)

When both local and remote progress exist:

1. **unlockedChapter**: `max(local, remote)`
   - Take the highest chapter reached

2. **unlockedLevel**: `max(local, remote)` for the merged chapter
   - If same chapter, take max level
   - If different chapters, take level from the higher chapter

3. **completed**: Union (set merge)
   - Combine all completed levels from both
   - Remove duplicates
   - Sort per chapter

4. **stats**: MAX (not SUM)
   - `totalSolved`: `max(local, remote)` - Avoid double-counting
   - `totalHintsUsed`: `max(local, remote)`
   - `totalPlaySeconds`: `max(local, remote)`
   - `totalMoves`: `max(local, remote)`
   
   **Note**: Using MAX instead of SUM to avoid double-counting if user plays same level on multiple devices. If stats should be truly cumulative, change to SUM.

5. **localUpdatedAtMs**: `max(local, remote)`
   - Use the newer timestamp

### Example
```
Local:  {chapter: 2, level: 5, completed: {"1": [1,2,3,4,5], "2": [1,2]}, stats: {totalSolved: 7}}
Remote: {chapter: 2, level: 3, completed: {"1": [1,2,3,4,5,6,7,8], "2": [1]}, stats: {totalSolved: 9}}

Merged: {chapter: 2, level: 5, completed: {"1": [1,2,3,4,5,6,7,8], "2": [1,2]}, stats: {totalSolved: 9}}
```

## CurrentRun Strategy

### Latest Wins (LWW) with Device Check

1. **Compare**: `localUpdatedAtMs` (local timestamp)
2. **Newer wins**: Use the one with higher `localUpdatedAtMs`
3. **Device check**:
   - If remote is newer AND `deviceId` differs → Keep remote (log warning)
   - Otherwise → Keep local

### Device ID
- Generated once per device (UUID v4)
- Stored in SharedPreferences
- Added to CurrentRunModel on save
- Used to detect multi-device conflicts

## Diff Check (Skip Duplicate Writes)

### Hash-based Comparison
- Compute hash of data (excluding timestamps)
- Compare with last flushed hash
- If identical → Skip write
- If different → Write and update hash

### Hash Computation
```dart
// Remove timestamps
data.remove('updatedAt');
data.remove('lastActionAt');
data.remove('localUpdatedAtMs');
// Compute hash
final hash = jsonEncode(data).hashCode.toString();
```

### Benefits
- Reduces Firestore writes
- Saves bandwidth
- Reduces costs
- Still maintains debounce (2s)

## ClearCurrentRun Behavior

### Local
1. Delete `currentRun` key from Hive
2. Clear dirty flag
3. Clear last flushed hash

### Remote
1. Delete Firestore doc: `users/{uid}/state/currentRun`
2. Retry on failure (3 attempts with backoff)

### Result
- `resumeGame()` returns `null` after clear
- No orphaned data

## Retry Logic

### Retry Conditions
Only retry on:
- `unavailable` (network error)
- `deadline-exceeded` (timeout)
- `internal` (server error)
- Network-related errors

### Retry Schedule
- Attempt 1: Immediate
- Attempt 2: 300ms delay
- Attempt 3: 800ms delay
- Attempt 4: 1500ms delay

### Non-Retryable Errors
- Permission denied
- Invalid argument
- Not found (for deletes)

## Console Logs

### Merge Operations
- `[SYNC] mergeProgress applied` - Progress merge completed
- `[SYNC] Current run: remote newer from different device` - Multi-device conflict

### Skip Operations
- `[SYNC] Skipped write (no diff): Progress` - Progress unchanged
- `[SYNC] Skipped write (no diff): CurrentRun` - Current run unchanged

### Clear Operations
- `[REMOTE] Current run cleared: {uid}` - Remote delete successful
- `[REPO] Current run cleared (local + remote)` - Both cleared

### Timestamp Logs
- `[LOCAL] Progress saved (localUpdatedAtMs: {timestamp})`
- `[LOCAL] Current run saved (localUpdatedAtMs: {timestamp})`

## Data Loss Prevention

### Progress
- ✅ Merge strategy (no data loss)
- ✅ Union of completed levels
- ✅ Max of unlocked chapter/level

### CurrentRun
- ✅ Device ID tracking
- ✅ Warning on multi-device conflicts
- ✅ Latest wins (but with device awareness)

### General
- ✅ Local cache always saved first
- ✅ Retry on network errors
- ✅ Diff check prevents unnecessary writes
- ✅ Clear operations are atomic (local + remote)

