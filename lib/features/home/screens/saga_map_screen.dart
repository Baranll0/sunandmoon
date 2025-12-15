import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/services/level_manager.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/providers/sync_providers.dart';
import '../../../../core/repositories/game_state_repository.dart';
import '../../../../core/domain/current_run_model.dart';
import '../../game/domain/models/level_model.dart';
import '../../game/presentation/controllers/game_controller.dart';
import '../../game/presentation/screens/game_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'home_screen.dart';
import '../controllers/journey_map_controller.dart';

/// Journey Screen - Linear progression like Candy Crush
/// Renamed from SagaMapScreen to JourneyScreen
class JourneyScreen extends ConsumerStatefulWidget {
  final LevelModel? focusLevel; // Optional: level to focus on when screen loads

  const JourneyScreen({super.key, this.focusLevel});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> with TickerProviderStateMixin {
  LevelModel? _currentProgress;
  LevelModel? _maxUnlockedLevel;
  Set<String> _completedLevels = {};
  final ScrollController _scrollController = ScrollController();
  late final JourneyMapController _mapController;
  bool _isLoading = true;
  bool _loadError = false;
  LevelModel? _visuallyLockedLevel; // Level forced to be visually locked (until animation)
  LevelModel? _newlyUnlockedLevel; // Track newly unlocked level for animation
  LevelModel? _pathRevealTargetLevel; // Level to which path is being revealed (before unlock)
  late AnimationController _pathRevealController;
  double _pathRevealProgress = 1.0; // 0.0 to 1.0

  @override
  @override
  void initState() {
    super.initState();
    // CRITICAL: If a focus level is provided (we just beat a level), 
    // treat it as "visually locked" initially so we can animate the unlock.
    if (widget.focusLevel != null) {
      _visuallyLockedLevel = widget.focusLevel;
    }
    
    _mapController = JourneyMapController(_scrollController);
    _pathRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500), // Slower path filling (2.5s)
    );
    _pathRevealController.addListener(() {
      if (mounted) {
        setState(() {
          _pathRevealProgress = _pathRevealController.value;
        });
      }
    });
    
    // Start loading progress
    _loadProgress();
  }

  // ...





  @override
  void dispose() {
    _scrollController.dispose();
    _pathRevealController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    print('DEBUG: _loadProgress started');
    setState(() {
      _isLoading = true;
      _loadError = false;
    });

    try {
      // CRITICAL FIX: Use GameStateRepository (Hive) instead of ProgressService (SharedPreferences)
      print('DEBUG: Reading gameStateRepositoryProvider...');
      final gameStateRepo = await ref.read(gameStateRepositoryProvider.future);
      print('DEBUG: gameStateRepositoryProvider read. Loading progress...');
      
      // Load progress from GameStateRepository (Hive)
      final progressModel = gameStateRepo.getCurrentProgress();
      print('DEBUG: Progress loaded: $progressModel');
      
      // Load current run (if user has an active game)
      final currentRun = gameStateRepo.resumeGame();
      print('DEBUG: Current run loaded: $currentRun');
      
      // Determine current progress: use currentRun if exists, otherwise use progressModel
      LevelModel? currentProgress;
      if (currentRun != null) {
        // User has an active game - this is where they left off
        currentProgress = LevelModel(chapter: currentRun.chapter, level: currentRun.level);
      } else if (progressModel != null) {
        // No active game - use the last unlocked level as current progress
        // unlockedLevel is the highest level the user has reached (not necessarily completed)
        currentProgress = LevelModel(
          chapter: progressModel.unlockedChapter,
          level: progressModel.unlockedLevel,
        );
      }
      
      // Determine max unlocked level from progressModel
      LevelModel? maxUnlocked;
      if (progressModel != null) {
        maxUnlocked = LevelModel(
          chapter: progressModel.unlockedChapter,
          level: progressModel.unlockedLevel,
        );
      }
      
      // Convert completed levels from progressModel to Set<String>
      Set<String> completedLevels = {};
      if (progressModel != null) {
        for (final entry in progressModel.completed.entries) {
          final chapter = entry.key;
          final levels = entry.value;
          for (final level in levels) {
            completedLevels.add('${chapter}_$level');
          }
        }
      }
      
      // Fallback: Also check ProgressService for backward compatibility
      if (progressModel == null) {
        print('DEBUG: progressModel is null, checking legacy ProgressService...');
        final progress = await ProgressService.getCurrentProgress()
            .timeout(const Duration(seconds: 2));
        print('DEBUG: Legacy progress: $progress');
        final maxUnlockedLegacy = await ProgressService.getMaxUnlockedLevel()
            .timeout(const Duration(seconds: 2));
        print('DEBUG: Legacy maxUnlocked: $maxUnlockedLegacy');
        final completedLegacy = await ProgressService.getCompletedLevels()
            .timeout(const Duration(seconds: 2));
        print('DEBUG: Legacy completed: ${completedLegacy.length}');
        
        currentProgress = currentProgress ?? progress;
        maxUnlocked = maxUnlocked ?? maxUnlockedLegacy;
        completedLevels = completedLevels.isEmpty 
            ? completedLegacy.map((l) => '${l.chapter}_${l.level}').toSet()
            : completedLevels;
      }
      
      print('DEBUG: Progress logic complete. Updating UI...');
      if (mounted) {
        // Check if a new level was unlocked
        final previousMaxUnlocked = _maxUnlockedLevel;
        LevelModel? newlyUnlocked;
        if (maxUnlocked != null && previousMaxUnlocked != null) {
          final prevId = LevelManager.getLevelId(previousMaxUnlocked.chapter, previousMaxUnlocked.level);
          final newId = LevelManager.getLevelId(maxUnlocked.chapter, maxUnlocked.level);
          if (newId > prevId) {
            newlyUnlocked = maxUnlocked;
          }
        } else if (maxUnlocked != null && previousMaxUnlocked == null) {
          newlyUnlocked = maxUnlocked;
        }

        print('DEBUG: Setting state with loaded data...');
        setState(() {
          _currentProgress = currentProgress;
          _maxUnlockedLevel = maxUnlocked;
          _completedLevels = completedLevels;
          _isLoading = false;
          _newlyUnlockedLevel = newlyUnlocked;
        });
        print('DEBUG: State updated. _isLoading is false.');
        
        // CRITICAL: Handle scroll and animations
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!_scrollController.hasClients) return;
          
          // Wait for layout to settle
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (widget.focusLevel != null) {
             print('DEBUG: Handling level completion flow...');
            // Case 1: focusLevel provided (after level completion) - play completion + unlock animation sequence
            await _handleLevelCompletionFlow(widget.focusLevel!);
          } else if (_currentProgress != null) {
             print('DEBUG: Initial scroll to current progress...');
            // Case 2: Normal load - scroll to current progress (where user left off)
            // CRITICAL: If current progress is completed, it means user finished it but didn't start next level
            // In this case, scroll to the next level (or stay at current if it's the last)
            final currentLevelId = LevelManager.getLevelId(_currentProgress!.chapter, _currentProgress!.level);
            final isCurrentCompleted = _completedLevels.contains('${_currentProgress!.chapter}_${_currentProgress!.level}');
            
            LevelModel? targetLevel;
            if (isCurrentCompleted) {
              // Current level is completed - scroll to next level (if exists)
              targetLevel = LevelManager.getNextLevel(_currentProgress!);
            } else {
              // Current level is not completed - scroll to it (user left off here)
              targetLevel = _currentProgress;
            }
            
            if (targetLevel != null) {
              // CRITICAL: Scroll to target level but show 2-3 previous levels above it
              // This ensures user can see their recent progress, not just the current level
              await _mapController.scrollToNode(targetLevel, offsetNodes: 2.5);
            }
          }
        });
      }
    } catch (e) {
      print('DEBUG: Error in _loadProgress: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = true;
        });
      }
    }
  }

  // _scrollToLevel and _getLevelIndex removed - now using JourneyMapController

  /// Handle level completion flow: completion animation + unlock animation
  Future<void> _handleLevelCompletionFlow(LevelModel nextLevel) async {
    // Find the completed level (previous level)
    final completedLevel = LevelManager.getPreviousLevel(nextLevel);
    if (completedLevel == null) return;
    
    // Step 1: Scroll to completed level first (to show completion)
    // Show 2-3 previous levels above it for context
    await _mapController.scrollToNode(completedLevel, offsetNodes: 2.5);
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Step 2: Ensure completed level is marked in state (refresh UI)
    // The level should already be in _completedLevels from _loadProgress
    setState(() {
      // Force rebuild to show completion (orange checkmark)
    });
    await Future.delayed(const Duration(milliseconds: 800)); // Show completion briefly
    
    // Step 3: Scroll to next level (the newly unlocked one) - but keep it locked visually
    // Scroll to show the path segment connecting completed to next level
    await _mapController.scrollToNode(nextLevel, offsetNodes: 1.5);
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Step 4: Check if this level is newly unlocked
    final nextLevelId = LevelManager.getLevelId(nextLevel.chapter, nextLevel.level);
    final maxId = _maxUnlockedLevel != null 
        ? LevelManager.getLevelId(_maxUnlockedLevel!.chapter, _maxUnlockedLevel!.level)
        : 0;
    
    // Step 5: If this is the newly unlocked level, play sequential animations:
    // First: Path reveal (draw the connecting line)
    // Then: Lock break animation (unlock the node)
    if (nextLevelId == maxId && !_completedLevels.contains('${nextLevel.chapter}_${nextLevel.level}')) {
      // PHASE 1: Path reveal animation (draw the path segment)
      // Start path reveal WITHOUT setting _newlyUnlockedLevel yet
      // This ensures the path draws first, then the lock breaks
      // CRITICAL: Force progress to 0 first and rebuild
      setState(() {
        _pathRevealTargetLevel = nextLevel; // Set target for path reveal
        _pathRevealProgress = 0.0;
        // Keep _visuallyLockedLevel set! This forces the base path to remain grey/locked.
      });
      
      // Short delay to ensure UI updates to "empty path" state
      await Future.delayed(const Duration(milliseconds: 100));

      // Animate path reveal (drawing the line from completed to locked node)
      _pathRevealController.reset();
      await _pathRevealController.forward();
      
      // PHASE 2: Path reveal complete - now trigger lock break animation
      // Set _newlyUnlockedLevel to trigger the unlock animation in the widget
      await Future.delayed(const Duration(milliseconds: 300)); // Pause to let user register the full path
      
      setState(() {
        _newlyUnlockedLevel = nextLevel; // This triggers the lock break animation in NodeWidget
        _pathRevealTargetLevel = null; // Clear path reveal target
        _pathRevealProgress = 1.0; // Ensure progress is maxed
        // NOTE: We keep _visuallyLockedLevel set for a moment longer so the painter 
        // doesn't snap to "fully unlocked" before the node animation runs?
        // Actually, _JourneyPathPainter logic needs to handle this.
      });
      
      // PHASE 3: Wait for lock break animation to complete
      // The unlock animation duration is 2500ms (from _unlockController)
      await Future.delayed(const Duration(milliseconds: 3200)); // Slightly longer than animation
      
      // Clear after all animations complete
      if (mounted) {
        setState(() {
          _newlyUnlockedLevel = null;
          _pathRevealProgress = 1.0;
          _visuallyLockedLevel = null; // UNLOCK INTERACTION NOW
        });
      }
    } else {
      // If we are not animating (e.g. revisiting), ensure it's unlocked
      if (mounted) {
        setState(() {
          _visuallyLockedLevel = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: Text(strings.journeyTitle),
        backgroundColor: AppTheme.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackButton(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _loadError
              ? _buildErrorState()
              : _buildSagaMap(),
    );
  }

  /// Handle back button - navigate to HomeScreen
  void _handleBackButton(BuildContext context) {
    // Always navigate to HomeScreen (main menu)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  /// Build loading state with timeout handling
  Widget _buildLoadingState() {
    final strings = ref.watch(appStringsProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            strings.loading,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.inkLight,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state with retry button
  Widget _buildErrorState() {
    final strings = ref.watch(appStringsProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorRed,
          ),
          const SizedBox(height: 16),
          Text(
            strings.loadingError,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.inkDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.pleaseRetry,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.inkLight,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadProgress,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sunOrange,
              foregroundColor: Colors.white,
            ),
            child: Text(strings.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildSagaMap() {
    // CRITICAL: Always show Chapter 1, even if progress is null
    // Calculate max chapter to show: always start from Chapter 1
    int effectiveMaxChapter = 1;
    if (_maxUnlockedLevel != null) {
      effectiveMaxChapter = (_maxUnlockedLevel!.chapter + 2).clamp(1, LevelManager.getMaxChaptersForUI());
    } else if (_currentProgress != null) {
      effectiveMaxChapter = (_currentProgress!.chapter + 2).clamp(1, LevelManager.getMaxChaptersForUI());
    } else {
      // No progress yet - show at least Chapter 1
      effectiveMaxChapter = 1;
    }
    
    final totalLevels = _getTotalLevelCount(effectiveMaxChapter);
    
    // Calculate node layouts (deterministic positioning)
    final nodeLayouts = _computeNodeLayouts(totalLevels, effectiveMaxChapter);
    final totalMapHeight = _calculateTotalMapHeight(totalLevels, effectiveMaxChapter);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      decoration: BoxDecoration(
        // Candy Crush style gradient background (base layer)
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8F5E9), // Light green
            const Color(0xFFC8E6C9), // Medium green
            const Color(0xFFA5D6A7), // Darker green
            const Color(0xFF81C784), // Even darker
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Parallax Layer 1: Clouds (far background, slow movement)
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              final offset = _scrollController.hasClients 
                  ? _scrollController.offset * 0.1 
                  : 0.0;
              return _buildParallaxLayer(
                offset: offset,
                child: _buildCloudsLayer(),
              );
            },
          ),
          // Parallax Layer 2: Hills (mid background, medium movement)
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              final offset = _scrollController.hasClients 
                  ? _scrollController.offset * 0.3 
                  : 0.0;
              return _buildParallaxLayer(
                offset: offset,
                child: _buildHillsLayer(),
              );
            },
          ),
          // Main content: Path + Nodes 
          // CRITICAL FIX: Use SingleChildScrollView + Stack instead of SliverList
          // This prevents the CustomPaint from being recycled/disposed during scroll
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16), // Padding matches previous SliverPadding
            child: SizedBox(
              height: totalMapHeight,
              child: Stack(
                children: [
                  // Layer 1: The Path (Full height, drawn once)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _JourneyPathPainter(
                        nodeLayouts: nodeLayouts,
                        maxUnlockedId: _maxUnlockedLevel != null
                            ? LevelManager.getLevelId(_maxUnlockedLevel!.chapter, _maxUnlockedLevel!.level)
                            : 0,
                        completedLevels: _completedLevels,
                        mapHeight: totalMapHeight,
                        screenWidth: screenWidth,
                        pathRevealTargetLevel: _pathRevealTargetLevel,
                        newlyUnlockedLevel: _newlyUnlockedLevel,
                        pathRevealProgress: _pathRevealProgress,
                        visuallyLockedLevel: _visuallyLockedLevel,
                      ),
                    ),
                  ),
                  // Layer 2: The Nodes (rendered as a Column)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(totalLevels, (index) {
                      final level = _getLevelFromIndex(index, effectiveMaxChapter);
                      if (level == null) return const SizedBox.shrink();
                      
                      // Check if this is the first level of a chapter (show chapter header)
                      final isFirstInChapter = level.level == 1;
                      // Check if this is the very first item (Chapter 1, Level 1)
                      final isFirstItem = index == 0 && level.chapter == 1 && level.level == 1;
                      
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isFirstInChapter) _buildChapterHeader(level.chapter, isFirstItem: isFirstItem),
                          SizedBox(
                            height: 120, // Match node height
                            child: Center(
                              child: _buildLevelNode(level, index),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compute node layouts with deterministic positioning
  /// Accounts for chapter headers and node spacing
  /// CRITICAL: This must match the actual widget layout in ListView
  List<_NodeLayout> _computeNodeLayouts(int totalLevels, int maxChapter) {
    final layouts = <_NodeLayout>[];
    const double nodeHeight = 120.0; // Match SizedBox height
    // Chapter header: margin bottom: 16, padding vertical: 12*2 = 24, content ~60px = ~100px total (no top margin for first)
    // First chapter header: 0 top margin + 16 bottom margin + 24 padding + 60 content = 100px
    // Subsequent chapter headers: 24 top margin + 16 bottom margin + 24 padding + 60 content = 124px
    const double chapterHeaderHeightFirst = 100.0; // First chapter header (no top margin)
    const double chapterHeaderHeightSubsequent = 124.0; // Subsequent chapter headers (with top margin)
    const double topPadding = 0.0; // No top padding - Chapter 1 starts at top
    const double horizontalPadding = 16.0; // ListView padding horizontal
    final screenWidth = MediaQuery.of(context).size.width;
    
    double currentY = topPadding; // Start from top (no padding)
    int currentIndex = 0;
    
    for (int ch = 1; ch <= maxChapter; ch++) {
      final levelsInChapter = LevelManager.getLevelsPerChapter(ch);
      
      // Add chapter header height for first level of chapter
      if (ch == 1) {
        currentY += chapterHeaderHeightFirst; // First chapter: no top margin
      } else if (currentIndex > 0) {
        // For subsequent chapters, add header height before first level
        currentY += chapterHeaderHeightSubsequent; // Subsequent chapters: with top margin
      }
      
      for (int level = 1; level <= levelsInChapter; level++) {
        if (currentIndex >= totalLevels) break;
        
        // Node center Y position (within the SizedBox)
        final nodeCenterY = currentY + (nodeHeight / 2);
        
        // Zigzag X offset (match _buildLevelNode logic exactly)
        final zigzagOffset = (currentIndex % 6 < 3) ? -40.0 : 40.0;
        // Center X is screen center minus horizontal padding (to account for ListView padding)
        final centerX = (screenWidth / 2) - horizontalPadding;
        final nodeCenterX = centerX + zigzagOffset;
        
        final levelModel = LevelModel(chapter: ch, level: level);
        final levelId = LevelManager.getLevelId(ch, level);
        final isCompleted = _completedLevels.contains('${ch}_$level');
        // CRITICAL FIX: isCurrent should only be true if this is the current progress AND not completed
        final isCurrent = !isCompleted && _currentProgress != null &&
            _currentProgress!.chapter == ch &&
            _currentProgress!.level == level;
        final maxUnlockedId = _maxUnlockedLevel != null
            ? LevelManager.getLevelId(_maxUnlockedLevel!.chapter, _maxUnlockedLevel!.level)
            : 0;
        final isLocked = levelId > maxUnlockedId && !isCompleted;
        
        layouts.add(_NodeLayout(
          level: levelModel,
          index: currentIndex,
          center: Offset(nodeCenterX, nodeCenterY),
          isLocked: isLocked,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
        ));
        
        currentY += nodeHeight;
        currentIndex++;
      }
    }
    
    return layouts;
  }

  /// Calculate total map height including all nodes and chapter headers
  double _calculateTotalMapHeight(int totalLevels, int maxChapter) {
    const double nodeHeight = 120.0;
    const double chapterHeaderHeightFirst = 100.0; // First chapter header (no top margin)
    const double chapterHeaderHeightSubsequent = 124.0; // Subsequent chapter headers (with top margin)
    const double topPadding = 0.0; // No top padding - Chapter 1 starts at top
    const double bottomPadding = 24.0;
    
    double height = topPadding + bottomPadding;
    
    int currentIndex = 0;
    for (int ch = 1; ch <= maxChapter; ch++) {
      final levelsInChapter = LevelManager.getLevelsPerChapter(ch);
      
      // Add chapter header for first level of chapter
      if (ch == 1) {
        height += chapterHeaderHeightFirst; // First chapter: no top margin
      } else if (currentIndex > 0) {
        height += chapterHeaderHeightSubsequent; // Subsequent chapters: with top margin
      }
      
      for (int level = 1; level <= levelsInChapter; level++) {
        if (currentIndex >= totalLevels) break;
        height += nodeHeight;
        currentIndex++;
      }
    }
    
    return height;
  }

  /// Build parallax layer wrapper
  Widget _buildParallaxLayer({required double offset, required Widget child}) {
    return Transform.translate(
      offset: Offset(0, offset),
      child: child,
    );
  }

  /// Build decorative clouds layer (parallax background)
  Widget _buildCloudsLayer() {
    return CustomPaint(
      painter: _CloudsPainter(),
      size: Size.infinite,
    );
  }

  /// Build decorative hills layer (parallax midground)
  Widget _buildHillsLayer() {
    return CustomPaint(
      painter: _HillsPainter(),
      size: Size.infinite,
    );
  }

  int _getTotalLevelCount(int maxChapter) {
    int count = 0;
    for (int ch = 1; ch <= maxChapter; ch++) {
      count += LevelManager.getLevelsPerChapter(ch);
    }
    return count;
  }

  /// Build chapter header with difficulty label
  Widget _buildChapterHeader(int chapter, {bool isFirstItem = false}) {
    final strings = ref.read(appStringsProvider);
    final (difficultyLabel, description) = _getChapterDifficulty(chapter, strings);
    
    return Container(
      margin: EdgeInsets.only(
        bottom: 16, 
        top: isFirstItem ? 0 : 24, // No top margin for first chapter header
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inkLight.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${strings.chapter} $chapter',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.inkDark,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(chapter).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  difficultyLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getDifficultyColor(chapter),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.inkLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Get chapter difficulty label and description
  /// NEW STRUCTURE: Chapter 1=Beginner, 2=Intermediate, 3=Advanced, 4=Expert
  (String, String) _getChapterDifficulty(int chapter, AppStrings strings) {
    if (chapter == 1) {
      return (strings.chapterDifficultyBeginner, strings.chapterDifficultyDescription1);
    } else if (chapter == 2) {
      return (strings.chapterDifficultyIntermediate, strings.chapterDifficultyDescription2);
    } else if (chapter == 3) {
      return (strings.chapterDifficultyAdvanced, strings.chapterDifficultyDescription3);
    } else if (chapter == 4) {
      return (strings.chapterDifficultyExpert, strings.chapterDifficultyDescription4);
    } else {
      // Chapter 5+ (procedural continuation)
      return (strings.chapterDifficultyExpert, strings.chapterDifficultyDescription4);
    }
  }

  /// Get color for difficulty level
  /// NEW STRUCTURE: Chapter 1=Green, 2=Blue, 3=Orange, 4+=Red
  Color _getDifficultyColor(int chapter) {
    if (chapter == 1) {
      return Colors.green;
    } else if (chapter == 2) {
      return Colors.blue;
    } else if (chapter == 3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  LevelModel? _getLevelFromIndex(int index, int maxChapter) {
    int currentIndex = 0;
    for (int ch = 1; ch <= maxChapter; ch++) {
      final levelsInChapter = LevelManager.getLevelsPerChapter(ch);
      if (index < currentIndex + levelsInChapter) {
        final levelInChapter = index - currentIndex + 1;
        return LevelModel(chapter: ch, level: levelInChapter);
      }
      currentIndex += levelsInChapter;
    }
    return null;
  }

  Widget _buildLevelNode(LevelModel level, int index) {
    final levelId = LevelManager.getLevelId(level.chapter, level.level);
    final maxUnlockedId = _maxUnlockedLevel != null
        ? LevelManager.getLevelId(_maxUnlockedLevel!.chapter, _maxUnlockedLevel!.level)
        : 0;
    
    final isCompleted = _completedLevels.contains('${level.chapter}_${level.level}');
    
    // CRITICAL FIX: isCurrent should only be true if this is the current progress AND not completed
    // If a level is completed, it should show as completed (orange), not current (blue)
    final isCurrent = !isCompleted && _currentProgress != null &&
        _currentProgress!.chapter == level.chapter &&
        _currentProgress!.level == level.level;
    
    // Locked if level ID is greater than max unlocked
    final isLocked = levelId > maxUnlockedId && !isCompleted;

    // Zigzag positioning: alternate left/right every few levels (match path)
    final zigzagOffset = (index % 6 < 3) ? -40.0 : 40.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.center,
        child: Transform.translate(
          offset: Offset(zigzagOffset, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Level node (Stepping Stone) - path is drawn by CustomPainter
              GestureDetector(
                onTap: isLocked
                    ? () {
                        // Show toast for locked levels
                        final strings = ref.read(appStringsProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(strings.completeLevelFirst),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.inkDark.withOpacity(0.9),
                          ),
                        );
                      }
                    : () => _startLevel(level),
                child: _LevelNodeWidget(
                  level: level,
                  isCurrent: isCurrent,
                  isCompleted: isCompleted,
                  isLocked: isLocked,
                  isNewlyUnlocked: _newlyUnlockedLevel != null &&
                      _newlyUnlockedLevel!.chapter == level.chapter &&
                      _newlyUnlockedLevel!.level == level.level,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _startLevel(LevelModel level) async {
    final gameNotifier = ref.read(gameStateNotifierProvider.notifier);

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await gameNotifier.startLevel(level);

      // Save progress
      await ProgressService.saveProgress(level);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const GameScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final strings = ref.read(appStringsProvider);
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.errorStartingLevel}: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}

/// Level Node Widget - Circular button for each level
class _LevelNodeWidget extends StatefulWidget {
  final LevelModel level;
  final bool isCurrent;
  final bool isCompleted;
  final bool isLocked;
  final bool isNewlyUnlocked;

  const _LevelNodeWidget({
    required this.level,
    required this.isCurrent,
    required this.isCompleted,
    required this.isLocked,
    this.isNewlyUnlocked = false,
  });

  @override
  State<_LevelNodeWidget> createState() => _LevelNodeWidgetState();
}

class _LevelNodeWidgetState extends State<_LevelNodeWidget>
with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _unlockController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _lockFadeAnimation; // For lock icon fade out

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _unlockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // Slightly longer for better effect
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _unlockController,
        curve: Curves.elasticOut,
      ),
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _unlockController,
        curve: Curves.easeOut,
      ),
    );
    
    // Lock fade out: fade from 1.0 to 0.0 in first 60% of animation
    _lockFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _unlockController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut), // Fade out in first 60%
      ),
    );
    
    if (widget.isCurrent) {
      _pulseController.repeat(reverse: true);
    }
    
    if (widget.isNewlyUnlocked) {
      _unlockController.forward();
    }
  }

  @override
  void didUpdateWidget(_LevelNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNewlyUnlocked && !oldWidget.isNewlyUnlocked) {
      _unlockController.reset();
      _unlockController.forward();
    }
    if (widget.isCurrent && !oldWidget.isCurrent) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrent && oldWidget.isCurrent) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _unlockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isCurrent ? 80.0 : 64.0; // Current level is larger
    final gridSize = LevelManager.getGridSizeForChapter(widget.level.chapter, widget.level.level);

    Widget content;
    Color backgroundColor;
    Color borderColor;

    if (widget.isLocked) {
      backgroundColor = AppTheme.inkLight.withOpacity(0.15);
      borderColor = AppTheme.inkLight.withOpacity(0.4);
      content = Icon(
        Icons.lock,
        color: AppTheme.inkLight.withOpacity(0.5),
        size: 28,
      );
    } else if (widget.isNewlyUnlocked) {
      // ANIMATION STATE: Transition from Locked to Unlocked
      backgroundColor = Colors.white;
      borderColor = AppTheme.inkLight;
      
      // Stack both icons for cross-fade
      content = Stack(
        alignment: Alignment.center,
        children: [
          // Fading IN: Level Number
          AnimatedBuilder(
            animation: _lockFadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: 1.0 - _lockFadeAnimation.value, // Inverse of lock fade
                child: Text(
                  '${widget.level.level}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkDark,
                  ),
                ),
              );
            },
          ),
          // Fading OUT: Lock Icon
          AnimatedBuilder(
            animation: _lockFadeAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (1.0 - _lockFadeAnimation.value) * 0.5, // Expand as it breaks
                child: Opacity(
                  opacity: _lockFadeAnimation.value,
                  child: Icon(
                    Icons.lock_open, // Switch to open lock for effect? Or keep lock?
                    color: AppTheme.sunOrange.withOpacity(0.8), // Turn orange as it breaks
                    size: 28,
                  ),
                ),
              );
            },
          ),
        ],
      );
    } else if (widget.isCompleted) {
      backgroundColor = AppTheme.sunOrange.withOpacity(0.2);
      borderColor = AppTheme.sunOrange;
      content = const Icon(
        Icons.check_circle,
        color: AppTheme.sunOrange,
        size: 32,
      );
    } else if (widget.isCurrent) {
      backgroundColor = Colors.white; // FIX: User requested white background
      borderColor = AppTheme.moonBlue;
      content = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.moonBlue.withOpacity(
                0.1 + (_pulseController.value * 0.2), // Subtle pulse
              ),
            ),
            child: Center(
              child: Text(
                '${widget.level.level}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.moonBlue,
                ),
              ),
            ),
          );
        },
      );
    } else {
      backgroundColor = Colors.white;
      borderColor = AppTheme.inkLight;
      content = Text(
        '${widget.level.level}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.inkDark,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _unlockController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isNewlyUnlocked ? _scaleAnimation.value : 1.0,
          child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            // Stepping stone appearance
            shape: BoxShape.circle,
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
              width: widget.isCurrent ? 4 : 2.5,
            ),
            boxShadow: [
              // Subtle shadow for depth (stepping stone effect)
              BoxShadow(
                color: AppTheme.inkDark.withOpacity(0.1),
                blurRadius: widget.isCurrent ? 12 : 6,
                spreadRadius: widget.isCurrent ? 3 : 1,
                offset: const Offset(0, 2),
              ),
              if (widget.isCurrent)
                BoxShadow(
                  color: AppTheme.moonBlue.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
                    // Unlock glow effect
                    if (widget.isNewlyUnlocked)
                      BoxShadow(
                        color: AppTheme.sunOrange.withOpacity(0.6 * _glowAnimation.value),
                        blurRadius: 20 * _glowAnimation.value,
                        spreadRadius: 5 * _glowAnimation.value,
                      ),
            ],
          ),
          child: Center(child: content),
        ),
        const SizedBox(height: 2),
        // Grid size indicator (smaller to prevent overflow)
        Text(
          '${gridSize}x$gridSize',
          style: TextStyle(
            fontSize: 9,
            color: AppTheme.inkLight,
          ),
        ),
      ],
          ),
        );
      },
    );
  }
}

/// Node Layout - Deterministic positioning for path drawing
class _NodeLayout {
  final LevelModel level;
  final int index;
  final Offset center;
  final bool isLocked;
  final bool isCompleted;
  final bool isCurrent;

  _NodeLayout({
    required this.level,
    required this.index,
    required this.center,
    required this.isLocked,
    required this.isCompleted,
    required this.isCurrent,
  });
}

/// Custom Painter for Journey Path - Candy Crush style
/// Now uses deterministic node layouts for accurate positioning
class _JourneyPathPainter extends CustomPainter {
  final List<_NodeLayout> nodeLayouts;
  final int maxUnlockedId;
  final Set<String> completedLevels;
  final double mapHeight;
  final double screenWidth;
  final LevelModel? pathRevealTargetLevel; // Level to which path is being revealed (before unlock)
  final LevelModel? newlyUnlockedLevel; // Level that is being unlocked (after path reveal)
  final double pathRevealProgress; // 0.0 to 1.0
  final LevelModel? visuallyLockedLevel; // Level forced to be visually locked

  _JourneyPathPainter({
    required this.nodeLayouts,
    required this.maxUnlockedId,
    required this.completedLevels,
    required this.mapHeight,
    required this.screenWidth,
    this.pathRevealTargetLevel,
    this.newlyUnlockedLevel,
    this.pathRevealProgress = 1.0,
    this.visuallyLockedLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeLayouts.isEmpty) return;

    // Paint for the background track (locked path)
    final lockedPathPaint = Paint()
      ..color = AppTheme.inkLight.withOpacity(0.2) // Light grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Paint for the active track (unlocked path)
    final unlockedPathPaint = Paint()
      ..color = AppTheme.sunOrange // Burning Orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw path segments between consecutive nodes
    for (int i = 1; i < nodeLayouts.length; i++) {
      final prevNode = nodeLayouts[i - 1];
      final currentNode = nodeLayouts[i];
      
      // Determine unlock status
      final currentLevelId = LevelManager.getLevelId(currentNode.level.chapter, currentNode.level.level);
      
      bool isUnlocked = currentLevelId <= maxUnlockedId || 
          completedLevels.contains('${currentNode.level.chapter}_${currentNode.level.level}');

      // CRITICAL: If visually locked (waiting for animation), force locked status
      if (visuallyLockedLevel != null && 
          currentNode.level.chapter == visuallyLockedLevel!.chapter &&
          currentNode.level.level == visuallyLockedLevel!.level) {
        isUnlocked = false;
      }
      
      // Check if this segment should be animated
      final isPathRevealSegment = pathRevealTargetLevel != null &&
          currentNode.level.chapter == pathRevealTargetLevel!.chapter &&
          currentNode.level.level == pathRevealTargetLevel!.level;
      final isNewlyUnlockedSegment = newlyUnlockedLevel != null &&
          currentNode.level.chapter == newlyUnlockedLevel!.chapter &&
          currentNode.level.level == newlyUnlockedLevel!.level;
      final shouldAnimatePath = isPathRevealSegment || isNewlyUnlockedSegment;
      
      // Build the curve
      final path = Path();
      path.moveTo(prevNode.center.dx, prevNode.center.dy);
      
      final controlPoint1 = Offset(
        prevNode.center.dx + (currentNode.center.dx - prevNode.center.dx) * 0.3,
        prevNode.center.dy + (currentNode.center.dy - prevNode.center.dy) * 0.3,
      );
      final controlPoint2 = Offset(
        prevNode.center.dx + (currentNode.center.dx - prevNode.center.dx) * 0.7,
        prevNode.center.dy + (currentNode.center.dy - prevNode.center.dy) * 0.7,
      );
      
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        currentNode.center.dx, currentNode.center.dy,
      );

      // STEP 1: Always draw the background (locked) path
      canvas.drawPath(path, lockedPathPaint);
      
      // STEP 2: Draw the unlocked (orange) path on top
      if (shouldAnimatePath && pathRevealProgress < 1.0) {
        // ANIMATION: Draw partial orange line
        final metrics = path.computeMetrics().first;
        final totalLength = metrics.length;
        final revealLength = totalLength * pathRevealProgress;
        
        final revealedPath = metrics.extractPath(0.0, revealLength);
        canvas.drawPath(revealedPath, unlockedPathPaint);
      } else if (isUnlocked && !shouldAnimatePath) {
        // STATIC UNLOCKED: Draw full orange line
        canvas.drawPath(path, unlockedPathPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyPathPainter oldDelegate) {
    // Only repaint if node layouts, unlock status, completion status, or path reveal changed
    // NOT on scroll (path moves with content naturally)
    return oldDelegate.nodeLayouts.length != nodeLayouts.length ||
        oldDelegate.maxUnlockedId != maxUnlockedId ||
        oldDelegate.completedLevels != completedLevels ||
        oldDelegate.mapHeight != mapHeight ||
        oldDelegate.pathRevealTargetLevel != pathRevealTargetLevel ||
        oldDelegate.newlyUnlockedLevel != newlyUnlockedLevel ||
        oldDelegate.visuallyLockedLevel != visuallyLockedLevel ||
        (oldDelegate.pathRevealProgress - pathRevealProgress).abs() > 0.01;
  }
}

/// Clouds Painter for parallax background layer
class _CloudsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // Draw simple cloud shapes
    for (int i = 0; i < 5; i++) {
      final x = (size.width / 5) * i + 50;
      final y = (size.height / 6) * (i % 3) + 100;
      
      // Simple cloud shape (ellipse)
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 120,
          height: 60,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CloudsPainter oldDelegate) => false;
}

/// Hills Painter for parallax midground layer
class _HillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9CCC65).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Draw wavy hills
    for (int i = 0; i < 3; i++) {
      final baseY = size.height * 0.7 + (i * 150);
      path.reset();
      path.moveTo(0, size.height);
      
      // Wavy hill
      for (double x = 0; x <= size.width; x += 20) {
        final y = baseY + 30 * (1 + math.sin(x / size.width * 2 * math.pi));
        path.lineTo(x, y);
      }
      
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HillsPainter oldDelegate) => false;
}

