import 'package:flutter/material.dart';
import '../../../core/services/level_manager.dart';
import '../../game/domain/models/level_model.dart';

/// Controller for Journey Map animations and navigation
class JourneyMapController {
  final ScrollController scrollController;
  
  JourneyMapController(this.scrollController);
  
  /// Scroll to a specific level node
  Future<void> scrollToNode(LevelModel level, {double offsetNodes = 0.0}) async {
    if (!scrollController.hasClients) return;
    
    // Calculate node position
    // CRITICAL: Match the layout calculation in _computeNodeLayouts
    const double nodeHeight = 120.0;
    const double chapterHeaderHeightFirst = 100.0; // First chapter header (no top margin)
    const double chapterHeaderHeightSubsequent = 124.0; // Subsequent chapter headers (with top margin)
    const double topPadding = 0.0; // No top padding - Chapter 1 starts at top
    
    double targetY = topPadding;
    
    // Add chapter headers before this level
    for (int ch = 1; ch < level.chapter; ch++) {
      // First chapter has no top margin, subsequent chapters do
      if (ch == 1) {
        targetY += chapterHeaderHeightFirst;
      } else {
        targetY += chapterHeaderHeightSubsequent;
      }
      targetY += LevelManager.getLevelsPerChapter(ch) * nodeHeight;
    }
    
    // Add chapter header for current chapter
    if (level.chapter > 0) {
      if (level.chapter == 1) {
        targetY += chapterHeaderHeightFirst; // First chapter: no top margin
      } else {
        targetY += chapterHeaderHeightSubsequent; // Subsequent chapters: with top margin
      }
    }
    
    // Add node position within chapter
    targetY += (level.level - 1) * nodeHeight;
    
    // Apply offset (negative = scroll up to show previous levels)
    targetY -= offsetNodes * nodeHeight;
    
    // Animate scroll
    await scrollController.animateTo(
      targetY.clamp(0.0, scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }
  
  /// Animate unlock to next node (with unlock animation)
  Future<void> animateUnlockTo(LevelModel nextLevel) async {
    // First scroll to the node
    await scrollToNode(nextLevel);
    
    // Unlock animation will be handled by the widget state
    // This method just ensures we're scrolled to the right position
  }
  
  int _getLevelIndex(LevelModel level) {
    int index = 0;
    for (int ch = 1; ch < level.chapter; ch++) {
      index += LevelManager.getLevelsPerChapter(ch);
    }
    index += level.level - 1;
    return index;
  }
}

