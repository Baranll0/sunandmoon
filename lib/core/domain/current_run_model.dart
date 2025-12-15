import 'package:freezed_annotation/freezed_annotation.dart';

part 'current_run_model.freezed.dart';
part 'current_run_model.g.dart';

/// Current run state - saves the game in progress
@freezed
class CurrentRunModel with _$CurrentRunModel {
  const factory CurrentRunModel({
    required int chapter,
    required int level,
    required int gridSize,
    required List<List<int>> givens, // Initial puzzle state
    required List<List<int>> currentGrid, // Current filled state
    @Default([]) List<List<int>> notes, // Pencil mode notes (optional)
    @Default(0) int movesCount,
    @Default(0) int elapsedSeconds,
    @Default(0) int hintsUsedThisLevel,
    @Default(0) int freeHintsRemaining,
    @Default(0) int rewardedHintsEarned,
    @Default(true) bool mistakesEnabled,
    @Default(true) bool autoCheckEnabled,
    @Default(false) bool pencilMode,
    @TimestampConverter() DateTime? lastActionAt,
    @TimestampConverter() DateTime? updatedAt, // Server timestamp (Firestore)
    @Default(0) int localUpdatedAtMs, // Local timestamp in milliseconds (for conflict resolution)
    String? deviceId, // Device identifier (for multi-device handling)
    @Default(1) int schemaVersion,
  }) = _CurrentRunModel;

  factory CurrentRunModel.fromJson(Map<String, dynamic> json) =>
      _$CurrentRunModelFromJson(json);
}

/// Timestamp converter for Firestore
class TimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const TimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is DateTime) return json;
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    if (json is String) return DateTime.parse(json);
    // Firestore Timestamp
    if (json is Map && json['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        json['_seconds'] * 1000 + (json['_nanoseconds'] ?? 0) ~/ 1000000,
      );
    }
    return null;
  }

  @override
  dynamic toJson(DateTime? object) {
    if (object == null) return null;
    return object.toIso8601String();
  }
}

