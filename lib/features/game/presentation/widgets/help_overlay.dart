import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/firebase_service.dart';

class HelpOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const HelpOverlay({super.key, required this.onClose});

  @override
  ConsumerState<HelpOverlay> createState() => _HelpOverlayState();
}

class _HelpOverlayState extends ConsumerState<HelpOverlay> with SingleTickerProviderStateMixin {
  bool _isExpandedHowToPlay = false;
  bool _isExpandedReport = false;
  
  // Form controllers
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedReportType = 'bug'; // bug, feedback, other
  bool _isSubmitting = false;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _close() {
    _controller.reverse().then((_) => widget.onClose());
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (FirebaseService.isInitialized) {
        await FirebaseFirestore.instance.collection('reports').add({
          'type': _selectedReportType,
          'email': _emailController.text,
          'description': _descriptionController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'platform': Theme.of(context).platform.toString(),
        });
      } else {
        // Offline/Mock mode
        await Future.delayed(const Duration(seconds: 1));
        debugPrint('[Report] Firebase inactive. Simulating submission.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teşekkürler! Geri bildiriminiz alındı.'),
            backgroundColor: AppTheme.sunOrange,
          ),
        );
        _descriptionController.clear();
        setState(() => _isExpandedReport = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Stack(
      children: [
        // Dimmed background
        GestureDetector(
          onTap: _close,
          child: Container(
            color: Colors.black54,
          ),
        ),
        // Overlay Content
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                // Decoration is handled by Material
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.help,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.inkDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _close,
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(),

                  // Content Scroll
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Section 1: How to Play
                          _buildAccordionItem(
                            title: strings.howToPlay,
                            icon: Icons.school,
                            isExpanded: _isExpandedHowToPlay,
                            onTap: () => setState(() {
                              _isExpandedHowToPlay = !_isExpandedHowToPlay;
                              if (_isExpandedHowToPlay) _isExpandedReport = false;
                            }),
                            child: _buildHowToPlayContent(strings),
                          ),

                          const SizedBox(height: 16),

                          // Section 2: Report Bug
                          _buildAccordionItem(
                            title: strings.reportBug,
                            icon: Icons.bug_report,
                            isExpanded: _isExpandedReport,
                            onTap: () => setState(() {
                              _isExpandedReport = !_isExpandedReport;
                              if (_isExpandedReport) _isExpandedHowToPlay = false;
                            }),
                            child: _buildReportForm(strings),
                          ),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildAccordionItem({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? AppTheme.sunOrange : Colors.grey[200]!,
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          if (isExpanded)
            BoxShadow(
              color: AppTheme.sunOrange.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: isExpanded ? Radius.zero : const Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isExpanded ? AppTheme.sunOrange : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isExpanded ? Colors.white : AppTheme.inkDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isExpanded ? AppTheme.sunOrange : AppTheme.inkDark,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isExpanded ? AppTheme.sunOrange : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50], // Light background for content
                child: child,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHowToPlayContent(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRuleItem('1. ${strings.rule1}'),
        _buildRuleItem('2. ${strings.rule2}'),
        _buildRuleItem('3. ${strings.rule3}'),
        const SizedBox(height: 16),
        const Text(
          'Grid Sizes:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _buildGridInfo('4x4', 'Beginner friendly. Quick games to learn the mechanics.'),
        _buildGridInfo('6x6', 'Standard difficulty. Balanced challenge for daily play.'),
        _buildGridInfo('8x8', 'Expert mode. Complex patterns requiring deep logic.'),
      ],
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, color: AppTheme.sunOrange),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridInfo(String size, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.inkDark,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              size,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportForm(AppStrings strings) {
    // Map internal values to display labels
    final Map<String, String> reportTypes = {
      'bug': strings.reportBug, // "Hata Bildir"
      'complaint': 'Complaint', // "Şikayet" - need to add to AppStrings potentially, hardcoded for now or use generic
      'suggestion': 'Suggestion', // "Öneri"
      'other': 'Other', // "Diğer"
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedReportType,
          decoration: const InputDecoration(
            labelText: 'Kategori',
            border: OutlineInputBorder(),
          ),
          items: reportTypes.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text(e.value),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedReportType = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email (İsteğe Bağlı)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Açıklama',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sunOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Gönder', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
