import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings_model.freezed.dart';
part 'user_settings_model.g.dart';

/// User settings model for Firestore
@freezed
class UserSettingsModel with _$UserSettingsModel {
  const factory UserSettingsModel({
    @Default('en') String language,
    @Default(true) bool sound,
    @Default(true) bool haptic,
    @Default(true) bool autoCheck,
    @TimestampConverter() DateTime? updatedAt,
  }) = _UserSettingsModel;

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsModelFromJson(json);
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

