import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_strings.dart';

/// How to Play Screen - Explains the game rules
class HowToPlayScreen extends ConsumerWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: Text(strings.howToPlay),
        backgroundColor: AppTheme.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game Title
              Center(
                child: Column(
                  children: [
                    Text(
                      'Tango Logic',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.inkDark,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.appDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.inkLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Rule 1: Balance
              _buildRuleCard(
                context,
                strings,
                icon: Icons.balance,
                iconColor: AppTheme.sunOrange,
                title: strings.ruleBalanceTitle,
                description: strings.ruleBalanceDescription,
              ),
              const SizedBox(height: 20),
              
              // Rule 2: No Three Consecutive
              _buildRuleCard(
                context,
                strings,
                icon: Icons.block,
                iconColor: AppTheme.moonBlue,
                title: strings.ruleNoThreeTitle,
                description: strings.ruleNoThreeDescription,
              ),
              const SizedBox(height: 20),
              
              // Rule 3: Unique Rows/Columns
              _buildRuleCard(
                context,
                strings,
                icon: Icons.compare_arrows,
                iconColor: AppTheme.sunOrange,
                title: strings.ruleUniqueTitle,
                description: strings.ruleUniqueDescription,
              ),
              const SizedBox(height: 20),
              
              // How to Play Section
              _buildSectionTitle(context, strings.howToPlaySection),
              const SizedBox(height: 16),
              
              _buildStepCard(
                context,
                strings,
                step: '1',
                title: strings.step1Title,
                description: strings.step1Description,
              ),
              const SizedBox(height: 12),
              
              _buildStepCard(
                context,
                strings,
                step: '2',
                title: strings.step2Title,
                description: strings.step2Description,
              ),
              const SizedBox(height: 12),
              
              _buildStepCard(
                context,
                strings,
                step: '3',
                title: strings.step3Title,
                description: strings.step3Description,
              ),
              const SizedBox(height: 12),
              
              _buildStepCard(
                context,
                strings,
                step: '4',
                title: strings.step4Title,
                description: strings.step4Description,
              ),
              const SizedBox(height: 40),
              
              // Advanced Logic Section
              _buildSectionTitle(context, strings.advancedLogicTitle),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.moonBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.moonBlue.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.advancedLogicDescription,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.inkDark,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildAdvancedTip(context, strings, strings.advancedLogicTip1),
                    const SizedBox(height: 12),
                    _buildAdvancedTip(context, strings, strings.advancedLogicTip2),
                    const SizedBox(height: 12),
                    _buildAdvancedTip(context, strings, strings.advancedLogicTip3),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedTip(BuildContext context, AppStrings strings, String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.moonBlue,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tip,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.inkDark,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(
    BuildContext context,
    AppStrings strings, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inkLight.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.inkDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.inkLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    AppStrings strings, {
    required String step,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.inkLight.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.sunOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.inkLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppTheme.inkDark,
        letterSpacing: 1,
      ),
    );
  }
}

