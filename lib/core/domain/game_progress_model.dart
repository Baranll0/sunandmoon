import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_progress_model.freezed.dart';
part 'game_progress_model.g.dart';

/// Game progress model for Firestore
@freezed
class GameProgressModel with _$GameProgressModel {
  const factory GameProgressModel({
    required int unlockedChapter,
    required int unlockedLevel,
    @Default({}) Map<String, List<int>> completed, // "chapter": [level1, level2, ...]
    @Default(GameStats()) GameStats stats,
    @TimestampConverter() DateTime? updatedAt, // Server timestamp (Firestore)
    @Default(0) int localUpdatedAtMs, // Local timestamp in milliseconds (for conflict resolution)
  }) = _GameProgressModel;

  factory GameProgressModel.fromJson(Map<String, dynamic> json) =>
      _$GameProgressModelFromJson(json);
}

/// Game statistics
@freezed
class GameStats with _$GameStats {
  const factory GameStats({
    @Default(0) int totalSolved,
    @Default(0) int totalHintsUsed,
    @Default(0) int totalPlaySeconds,
    @Default(0) int totalMoves,
  }) = _GameStats;

  factory GameStats.fromJson(Map<String, dynamic> json) =>
      _$GameStatsFromJson(json);
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

