import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User model for Firebase Auth
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    String? displayName,
    String? email,
    String? photoURL,
    @Default('en') String locale,
    @Default('1.0.0') String appVersion,
    DeviceInfo? device,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? lastSeenAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

/// Device information
@freezed
class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String platform,
    String? model,
    String? osVersion,
  }) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
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

