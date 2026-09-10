import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'subscription_screen.dart';

class GrammarCheckerScreen extends ConsumerStatefulWidget {
  const GrammarCheckerScreen({super.key});

  @override
  ConsumerState<GrammarCheckerScreen> createState() => _GrammarCheckerScreenState();
}

class _GrammarCheckerScreenState extends ConsumerState<GrammarCheckerScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _textController = TextEditingController();
  bool _submitting = false;
  dynamic _result;
  int _freeTriesRemaining = 3;

  bool get _isCheckEnabled {
    return _textController.text.trim().isNotEmpty && !_submitting;
  }

  Future<void> _checkGrammar() async {
    if (!_isCheckEnabled) return;

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
            content: const Text('You have used all 3 free grammar checks. Upgrade to Premium for unlimited access!', style: TextStyle(color: AppColors.textSecondaryLight)),
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
      _result = null;
    });

    try {
      final response = await _apiService.request(
        path: '/content/grammar/check',
        method: 'POST',
        body: jsonEncode({
          'text': _textController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _result = jsonDecode(response.body);
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
        SnackBar(content: Text('Failed to check grammar: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final List subs = user?['subscriptions'] as List? ?? [];
    final hasActiveSub = subs.any((sub) => sub['status'] == 'ACTIVE');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary, size: 16),
          label: const Text(
            'Back',
            style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        title: const Text(
          'Grammar Checker',
          style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Your Text Label
            const Text(
              'Your Text',
              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // White textarea card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorderLight),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 6,
                style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 14),
                onChanged: (val) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  hintText: 'Type or paste text to check grammar...',
                  hintStyle: TextStyle(color: AppColors.textSecondaryLight),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Check Grammar Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isCheckEnabled ? _checkGrammar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCheckEnabled ? AppColors.accent : const Color(0xFFE2E8F0),
                  foregroundColor: _isCheckEnabled ? Colors.white : AppColors.textSecondaryLight,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: AppColors.textSecondaryLight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  Icons.verified,
                  size: 18,
                  color: _isCheckEnabled ? Colors.white : AppColors.textSecondaryLight,
                ),
                label: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Check Grammar',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Free uses indicator
            if (!hasActiveSub)
              Center(
                child: Text(
                  '$_freeTriesRemaining free uses remaining',
                  style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11),
                ),
              ),
            const SizedBox(height: 30),

            // Analysis Results Card
            if (_result != null) ...[
              _buildGrammarResultWidget(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrammarResultWidget() {
    final corrected = _result['correctedText'] ?? '';
    final corrections = _result['corrections'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Corrected Text Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Corrected Version',
                style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SelectableText(
                corrected,
                style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Mistakes list header
        Text(
          corrections.isEmpty ? 'No Grammar Errors Found!' : 'Identified Issues',
          style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (corrections.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Perfect grammar! No mistakes detected in your text.',
                    style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Corrections List
          Column(
            children: corrections.map<Widget>((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Original: "${c['original'] ?? ''}"',
                        style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11, decoration: TextDecoration.lineThrough),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Correction: "${c['correction'] ?? ''}"',
                        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      if (c['explanation'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Explanation: ${c['explanation']}',
                          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
