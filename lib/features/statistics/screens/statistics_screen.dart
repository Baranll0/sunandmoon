import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';

/// Statistics Screen
/// TODO: Implement statistics UI
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: Text(strings.statisticsComingSoon.split(' - ')[0]), // "Statistics Screen"
        backgroundColor: AppTheme.backgroundCream,
      ),
      body: Center(
        child: Text(
          strings.statisticsComingSoon,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.inkLight,
          ),
        ),
      ),
    );
  }
}

