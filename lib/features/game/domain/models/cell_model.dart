import 'package:freezed_annotation/freezed_annotation.dart';

part 'cell_model.freezed.dart';
part 'cell_model.g.dart';

/// Represents a single cell in the puzzle grid
@freezed
class CellModel with _$CellModel {
  const factory CellModel({
    /// The value in the cell: 0 = empty, 1 = Sun, 2 = Moon
    required int value,
    
    /// Whether this cell is a given (pre-filled) or user-placed
    @Default(false) bool isGiven,
    

    @Default([]) List<int> pencilMarks,
    
    /// Whether this cell is currently highlighted (for hints)
    @Default(false) bool isHighlighted,
    
    /// Whether this cell has an error (violates rules)
    @Default(false) bool hasError,
  }) = _CellModel;

  factory CellModel.fromJson(Map<String, dynamic> json) =>
      _$CellModelFromJson(json);
}

