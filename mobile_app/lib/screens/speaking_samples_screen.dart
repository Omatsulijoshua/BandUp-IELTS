import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'subscription_screen.dart';

class SpeakingSamplesScreen extends ConsumerStatefulWidget {
  const SpeakingSamplesScreen({super.key});

  @override
  ConsumerState<SpeakingSamplesScreen> createState() => _SpeakingSamplesScreenState();
}

class _SpeakingSamplesScreenState extends ConsumerState<SpeakingSamplesScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _topicController = TextEditingController();
  int _selectedPart = 1; // 1, 2, or 3
  bool _submitting = false;
  String? _sampleAnswer;
  int _freeTriesRemaining = 3;

  @override
  void initState() {
    super.initState();
    _topicController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  bool get _isGenerateEnabled {
    return _topicController.text.trim().isNotEmpty && !_submitting;
  }

  Future<void> _generateAnswer() async {
    if (!_isGenerateEnabled) return;

    final user = ref.read(authProvider).user;
    final List subs = user?['subscriptions'] as List? ?? [];
    final hasActiveSub = subs.any((sub) => sub['status'] == 'ACTIVE');

    if (!hasActiveSub) {
      if (_freeTriesRemaining <= 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Free Limit Reached', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
            content: const Text('You have used all 3 free speaking sample generations. Upgrade to Premium for unlimited access!', style: TextStyle(color: AppColors.textSecondaryLight)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                },
                child: const Text('Upgrade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return;
      }
    }

    setState(() {
      _submitting = true;
      _sampleAnswer = null;
    });

    try {
      final response = await _apiService.request(
        path: '/content/speaking/generate-sample',
        method: 'POST',
        body: jsonEncode({
          'topic': _topicController.text.trim(),
          'part': _selectedPart,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _sampleAnswer = data['sampleAnswer'] ?? '';
          if (!hasActiveSub) {
            _freeTriesRemaining--;
          }
        });
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate sample: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final List subs = user?['subscriptions'] as List? ?? [];
    final hasActiveSub = subs.any((sub) => sub['status'] == 'ACTIVE');

    // Theme values
    final Color bgColor = AppColors.backgroundLight;
    final Color cardColor = Colors.white;

    String bannerText = '';
    String placeholderText = '';
    if (_selectedPart == 1) {
      bannerText = 'Part 1 answers should be 2-4 sentences. Keep it natural and direct.';
      placeholderText = 'e.g. Do you like reading books?';
    } else if (_selectedPart == 2) {
      bannerText = 'Part 2 requires a 1-2 minute monologue. Cover all bullet points on the cue card.';
      placeholderText = 'e.g. Describe a place you visited that impressed you';
    } else {
      bannerText = 'Part 3 answers should be detailed with examples and reasoning. Aim for 4-6 sentences.';
      placeholderText = 'e.g. Why do some people prefer to travel alone?';
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Speaking Samples',
          style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Part 1, Part 2, Part 3 tab bar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: _buildPartTabButton(1, 'Part 1')),
                  Expanded(child: _buildPartTabButton(2, 'Part 2')),
                  Expanded(child: _buildPartTabButton(3, 'Part 3')),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tip Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bannerText,
                      style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 11, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Question input section title
            const Text(
              'Enter your topic or question',
              style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Textarea input card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _topicController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 14),
                decoration: InputDecoration(
                  hintText: placeholderText,
                  hintStyle: const TextStyle(color: AppColors.textSecondaryLight),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isGenerateEnabled ? _generateAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isGenerateEnabled ? AppColors.accent : const Color(0xFFE2E8F0),
                  foregroundColor: _isGenerateEnabled ? Colors.white : AppColors.textSecondaryLight,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: AppColors.textSecondaryLight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _submitting
                    ? const SizedBox.shrink()
                    : Icon(Icons.auto_awesome, size: 16, color: _isGenerateEnabled ? Colors.white : AppColors.textSecondaryLight),
                label: _submitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Generating...',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : const Text(
                        'Generate Band 9 Answer',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            if (!hasActiveSub) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '$_freeTriesRemaining free uses remaining',
                  style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
            const SizedBox(height: 30),

            // Generated Answer Results
            if (_sampleAnswer != null) ...[
              const Text(
                'Model Answer (Band 9)',
                style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      _sampleAnswer!,
                      style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => _copyToClipboard(_sampleAnswer!),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, color: AppColors.primary, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Copy text',
                            style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPartTabButton(int part, String label) {
    final bool isSelected = _selectedPart == part;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPart = part;
          _sampleAnswer = null; // Clear answer when switching parts
        });
      },
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
