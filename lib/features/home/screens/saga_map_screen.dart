import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/services/level_manager.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../game/domain/models/level_model.dart';
import '../../game/presentation/controllers/game_controller.dart';
import '../../game/presentation/screens/game_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'home_screen.dart';

/// Journey Screen - Linear progression like Candy Crush
/// Renamed from SagaMapScreen to JourneyScreen
class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  LevelModel? _currentProgress;
  LevelModel? _maxUnlockedLevel;
  Set<String> _completedLevels = {};
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _loadError = false;
    });

    try {
      // Add timeout to prevent loading trap
      final progress = await ProgressService.getCurrentProgress()
          .timeout(const Duration(seconds: 5));
      final maxUnlocked = await ProgressService.getMaxUnlockedLevel()
          .timeout(const Duration(seconds: 5));
      final completed = await ProgressService.getCompletedLevels()
          .timeout(const Duration(seconds: 5));
      
      if (mounted) {
        setState(() {
          _currentProgress = progress;
          _maxUnlockedLevel = maxUnlocked;
          _completedLevels = completed.map((l) => '${l.chapter}_${l.level}').toSet();
          _isLoading = false;
        });
        
        // Scroll to max unlocked level (not current progress)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToLevel(_maxUnlockedLevel ?? progress);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = true;
        });
      }
    }
  }

  void _scrollToLevel(LevelModel level) {
    if (!_scrollController.hasClients) return;
    
    // Calculate approximate position (each level node is ~80px tall)
    final levelIndex = _getLevelIndex(level);
    final targetOffset = levelIndex * 80.0;
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  int _getLevelIndex(LevelModel level) {
    int index = 0;
    for (int ch = 1; ch < level.chapter; ch++) {
      index += LevelManager.getLevelsPerChapter(ch);
    }
    index += level.level - 1;
    return index;
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
    if (_currentProgress == null) return const SizedBox.shrink();
    
    // Generate levels up to max unlocked + 2 (show some ahead)
    final targetLevel = _maxUnlockedLevel ?? _currentProgress!;
    final maxChapter = (targetLevel.chapter + 2).clamp(1, LevelManager.getMaxChaptersForUI());
    
    return Container(
      decoration: BoxDecoration(
        // Paper texture background (subtle)
        color: AppTheme.backgroundCream,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundCream,
            AppTheme.backgroundCream.withOpacity(0.95),
          ],
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        reverse: false, // Top to bottom (but we'll style it as bottom to top visually)
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        itemCount: _getTotalLevelCount(maxChapter),
        itemBuilder: (context, index) {
          final level = _getLevelFromIndex(index);
          if (level == null) return const SizedBox.shrink();
          
          // Check if this is the first level of a chapter (show chapter header)
          final isFirstInChapter = level.level == 1;
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFirstInChapter) _buildChapterHeader(level.chapter),
              _buildLevelNode(level, index),
            ],
          );
        },
      ),
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
  Widget _buildChapterHeader(int chapter) {
    final strings = ref.read(appStringsProvider);
    final (difficultyLabel, description) = _getChapterDifficulty(chapter, strings);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 24),
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
  (String, String) _getChapterDifficulty(int chapter, AppStrings strings) {
    if (chapter <= 2) {
      return (strings.chapterDifficultyBeginner, strings.chapterDifficultyDescription1);
    } else if (chapter <= 5) {
      return (strings.chapterDifficultyIntermediate, strings.chapterDifficultyDescription2);
    } else if (chapter <= 10) {
      return (strings.chapterDifficultyAdvanced, strings.chapterDifficultyDescription3);
    } else {
      return (strings.chapterDifficultyExpert, strings.chapterDifficultyDescription4);
    }
  }

  /// Get color for difficulty level
  Color _getDifficultyColor(int chapter) {
    if (chapter <= 2) {
      return Colors.green;
    } else if (chapter <= 5) {
      return Colors.blue;
    } else if (chapter <= 10) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  LevelModel? _getLevelFromIndex(int index) {
    int currentIndex = 0;
    for (int ch = 1; ch <= LevelManager.getMaxChaptersForUI(); ch++) {
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
    
    final isCurrent = _currentProgress != null &&
        _currentProgress!.chapter == level.chapter &&
        _currentProgress!.level == level.level;
    
    final isCompleted = _completedLevels.contains('${level.chapter}_${level.level}');
    // Locked if level ID is greater than max unlocked
    final isLocked = levelId > maxUnlockedId && !isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Path line (vertical connector) - Ink stroke style
          if (index > 0)
            Container(
              width: 3,
              height: 50,
              decoration: BoxDecoration(
                color: isLocked 
                    ? AppTheme.inkLight.withOpacity(0.2)
                    : AppTheme.inkDark.withOpacity(0.4),
                // Dashed line effect (hand-drawn style)
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          // Level node (Stepping Stone)
          GestureDetector(
            onTap: isLocked ? null : () => _startLevel(level),
            child: _LevelNodeWidget(
              level: level,
              isCurrent: isCurrent,
              isCompleted: isCompleted,
              isLocked: isLocked,
            ),
          ),
        ],
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

  const _LevelNodeWidget({
    required this.level,
    required this.isCurrent,
    required this.isCompleted,
    required this.isLocked,
  });

  @override
  State<_LevelNodeWidget> createState() => _LevelNodeWidgetState();
}

class _LevelNodeWidgetState extends State<_LevelNodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isCurrent) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
    } else if (widget.isCompleted) {
      backgroundColor = AppTheme.sunOrange.withOpacity(0.2);
      borderColor = AppTheme.sunOrange;
      content = const Icon(
        Icons.check_circle,
        color: AppTheme.sunOrange,
        size: 32,
      );
    } else if (widget.isCurrent) {
      backgroundColor = AppTheme.moonBlue.withOpacity(0.3);
      borderColor = AppTheme.moonBlue;
      content = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.moonBlue.withOpacity(
                0.2 + (_pulseController.value * 0.3),
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

    return Column(
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
            ],
          ),
          child: Center(child: content),
        ),
        const SizedBox(height: 4),
        // Grid size indicator
        Text(
          '${gridSize}x$gridSize',
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.inkLight,
          ),
        ),
        // Chapter label (only show on first level of chapter)
        if (widget.level.level == 1)
          Consumer(
            builder: (context, ref, child) {
              final strings = ref.watch(appStringsProvider);
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${strings.chapter} ${widget.level.chapter}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.inkDark,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

