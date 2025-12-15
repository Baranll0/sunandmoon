import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/services/mechanic_registry.dart';
import '../../../../core/data/level_loader.dart';
import '../../../../core/domain/mechanic_flag.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../game/presentation/controllers/game_controller.dart';
import '../../game/domain/models/level_model.dart';
import '../../game/presentation/screens/game_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'saga_map_screen.dart' show JourneyScreen;
import 'how_to_play_screen.dart';

/// Home/Main Menu Screen
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  LevelModel? _currentProgress;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await ProgressService.getCurrentProgress();
    if (mounted) {
      setState(() {
        _currentProgress = progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom - 48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Title
              Text(
                strings.appName,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.inkDark,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.appSubtitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.inkLight,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.appDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.inkLight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 64),
              // Icons representing Sun and Moon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.backgroundCream,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.inkLight.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wb_sunny,
                      size: 64,
                      color: AppTheme.sunOrange,
                    ),
                    const SizedBox(width: 32),
                    Icon(
                      Icons.nightlight_round,
                      size: 64,
                      color: AppTheme.moonBlue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
              // Start Journey Button (Main entry point)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const JourneyScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sunOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        strings.startJourney,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // How to Play Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HowToPlayScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.inkDark,
                    side: BorderSide(color: AppTheme.inkLight, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.help_outline, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        strings.howToPlay,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Settings Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.inkDark,
                    side: BorderSide(color: AppTheme.inkLight, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.settings, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        strings.settings,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continueGame(BuildContext context, WidgetRef ref) async {
    if (_currentProgress == null) return;

    final gameNotifier = ref.read(gameStateNotifierProvider.notifier);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await gameNotifier.startLevel(_currentProgress!);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const GameScreen(),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error starting game: $e');
      debugPrint('Stack trace: $stackTrace');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        final strings = ref.read(appStringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.errorStartingGame}: $e'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showLevelSelection(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _LevelSelectionDialog(
        currentProgress: _currentProgress,
        onLevelSelected: (level) async {
          Navigator.of(context).pop();
          await _startLevel(context, ref, level);
        },
      ),
    );
  }

  Future<void> _startLevel(
    BuildContext context,
    WidgetRef ref,
    LevelModel level,
  ) async {
    final gameNotifier = ref.read(gameStateNotifierProvider.notifier);

    // Show loading
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

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const GameScreen(),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error starting game: $e');
      debugPrint('Stack trace: $stackTrace');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        final strings = ref.read(appStringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.errorStartingGame}: $e'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

/// Level Selection Dialog
class _LevelSelectionDialog extends ConsumerStatefulWidget {
  final LevelModel? currentProgress;
  final Function(LevelModel) onLevelSelected;

  const _LevelSelectionDialog({
    required this.currentProgress,
    required this.onLevelSelected,
  });

  @override
  ConsumerState<_LevelSelectionDialog> createState() => _LevelSelectionDialogState();
}

class _LevelSelectionDialogState extends ConsumerState<_LevelSelectionDialog> {
  int _selectedChapter = 1;
  int _selectedLevel = 1;
  List<MechanicFlag> _mechanics = [];
  Map<String, dynamic> _params = {};

  @override
  void initState() {
    super.initState();
    if (widget.currentProgress != null) {
      _selectedChapter = widget.currentProgress!.chapter;
      _selectedLevel = widget.currentProgress!.level;
    }
    _loadMechanics();
  }

  Future<void> _loadMechanics() async {
    // Try to load from LevelLoader first
    try {
      final loadedLevel = await LevelLoader.loadLevel(_selectedChapter, _selectedLevel, throwOnError: false);
      if (loadedLevel != null) {
        setState(() {
          _mechanics = loadedLevel.mechanics;
          _params = loadedLevel.params;
        });
        return;
      }
    } catch (e) {
      // Fall through to registry
    }
    
    // Fallback: Use MechanicRegistry
    final mechanics = MechanicRegistry.getMechanicsForLevel(_selectedChapter, _selectedLevel);
    final params = MechanicRegistry.getParamsForLevel(_selectedChapter, _selectedLevel, mechanics);
    setState(() {
      _mechanics = mechanics;
      _params = params;
    });
  }

  @override
  void didUpdateWidget(_LevelSelectionDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentProgress?.chapter != _selectedChapter ||
        oldWidget.currentProgress?.level != _selectedLevel) {
      _loadMechanics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxLevels = LevelConfig.getLevelsPerChapter(_selectedChapter);
    final gridSize = LevelConfig.getGridSizeForChapter(_selectedChapter);

    final strings = ref.watch(appStringsProvider);
    
    return AlertDialog(
      title: Text(strings.selectLevel),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chapter Selection
            Text(
              strings.chapter,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _selectedChapter > 1
                      ? () {
                          setState(() {
                            _selectedChapter--;
                            _selectedLevel = 1;
                          });
                          _loadMechanics();
                        }
                      : null,
                ),
                Expanded(
                  child: Text(
                    '${strings.chapter} $_selectedChapter',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedChapter < LevelConfig.getTotalChapters()
                      ? () {
                          setState(() {
                            _selectedChapter++;
                            _selectedLevel = 1;
                          });
                          _loadMechanics();
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Level Selection
            Text(
              strings.level,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _selectedLevel > 1
                      ? () {
                          setState(() {
                            _selectedLevel--;
                          });
                          _loadMechanics();
                        }
                      : null,
                ),
                Expanded(
                  child: Text(
                    '${strings.level} $_selectedLevel',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedLevel < maxLevels
                      ? () {
                          setState(() {
                            _selectedLevel++;
                          });
                          _loadMechanics();
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Grid Size Info
            Text(
              '${strings.gridSize}: ${gridSize}x$gridSize',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.inkLight,
                  ),
            ),
            // Mechanics Badges
            if (_mechanics.isNotEmpty && _mechanics.any((m) => m != MechanicFlag.classic)) ...[
              const SizedBox(height: 16),
              Text(
                'Mechanics',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _mechanics
                    .where((m) => m != MechanicFlag.classic)
                    .map((mechanic) => _MechanicBadge(
                          mechanic: mechanic,
                          params: _params,
                          strings: strings,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onLevelSelected(
              LevelModel(chapter: _selectedChapter, level: _selectedLevel),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.sunOrange,
            foregroundColor: Colors.white,
          ),
          child: Text(strings.start),
        ),
      ],
    );
  }
}

/// Mechanic Badge Widget
class _MechanicBadge extends StatelessWidget {
  final MechanicFlag mechanic;
  final Map<String, dynamic> params;
  final AppStrings strings;

  const _MechanicBadge({
    required this.mechanic,
    required this.params,
    required this.strings,
  });

  IconData _getIcon() {
    final iconName = MechanicRegistry.getIcon(mechanic);
    switch (iconName) {
      case 'grid':
        return Icons.grid_view;
      case 'lock':
        return Icons.lock;
      case 'pattern':
        return Icons.auto_awesome;
      case 'visibility_off':
        return Icons.visibility_off;
      case 'timer':
        return Icons.timer;
      case 'error':
        return Icons.error_outline;
      case 'edit':
        return Icons.edit;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'star':
        return Icons.star;
      default:
        return Icons.info_outline;
    }
  }

  String _getParamText() {
    if (mechanic == MechanicFlag.moveLimit) {
      final maxMoves = params['maxMoves'] as int?;
      if (maxMoves != null) {
        return '$maxMoves moves';
      }
    } else if (mechanic == MechanicFlag.mistakeLimit) {
      final maxMistakes = params['maxMistakes'] as int?;
      if (maxMistakes != null) {
        return '$maxMistakes mistakes';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final title = MechanicRegistry.getTitle(mechanic, strings);
    final description = MechanicRegistry.getDescription(mechanic, strings);
    final paramText = _getParamText();

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(_getIcon(), color: AppTheme.sunOrange),
                const SizedBox(width: 8),
                Expanded(child: Text(title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                if (paramText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    paramText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.inkDark,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.gotIt),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.sunOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.sunOrange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(),
              size: 16,
              color: AppTheme.sunOrange,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.inkDark,
              ),
            ),
            if (paramText.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                '($paramText)',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.inkLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
