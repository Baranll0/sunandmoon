import 'package:freezed_annotation/freezed_annotation.dart';
import 'mechanic_flag.dart';

part 'level_meta.freezed.dart';
part 'level_meta.g.dart';

/// Level metadata including mechanics and parameters
@freezed
class LevelMeta with _$LevelMeta {
  const factory LevelMeta({
    required int chapter,
    required int level,
    required int size,
    @Default([]) List<MechanicFlag> mechanics,
    @Default({}) Map<String, dynamic> params,
  }) = _LevelMeta;

  factory LevelMeta.fromJson(Map<String, dynamic> json) =>
      _$LevelMetaFromJson(json);
  
  /// Create LevelMeta from JSON with mechanics support
  factory LevelMeta.fromJsonWithMechanics(Map<String, dynamic> json) {
    final mechanics = <MechanicFlag>[];
    if (json['mechanics'] != null) {
      final mechanicsList = json['mechanics'] as List;
      for (final m in mechanicsList) {
        final flag = MechanicFlagExtension.fromString(m as String);
        if (flag != null) {
          mechanics.add(flag);
        }
      }
    }
    // Default to classic if no mechanics specified
    if (mechanics.isEmpty) {
      mechanics.add(MechanicFlag.classic);
    }
    
    return LevelMeta(
      chapter: json['chapter'] as int,
      level: json['level'] as int,
      size: json['size'] as int,
      mechanics: mechanics,
      params: json['params'] != null
          ? Map<String, dynamic>.from(json['params'] as Map)
          : {},
    );
  }
  
}

/// Extension for LevelMeta to add toJsonWithMechanics
extension LevelMetaExtension on LevelMeta {
  /// Convert to JSON with mechanics support
  Map<String, dynamic> toJsonWithMechanics() {
    return {
      'chapter': chapter,
      'level': level,
      'size': size,
      'mechanics': mechanics.map((m) => m.name).toList(),
      'params': params,
    };
  }
}

