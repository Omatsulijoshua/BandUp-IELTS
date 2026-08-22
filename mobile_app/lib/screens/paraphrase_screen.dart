import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'subscription_screen.dart';

class ParaphraseScreen extends ConsumerStatefulWidget {
  const ParaphraseScreen({super.key});

  @override
  ConsumerState<ParaphraseScreen> createState() => _ParaphraseScreenState();
}

class _ParaphraseScreenState extends ConsumerState<ParaphraseScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _sentenceController = TextEditingController();
  bool _submitting = false;
  List<dynamic>? _versions;
  int _freeTriesRemaining = 3;

  bool get _isParaphraseEnabled {
    return _sentenceController.text.trim().isNotEmpty && !_submitting;
  }

  Future<void> _paraphrase() async {
    if (!_isParaphraseEnabled) return;

    final user = ref.read(authProvider).user;
    final List subs = user?['subscriptions'] as List? ?? [];
    final hasActiveSub = subs.any((sub) => sub['status'] == 'ACTIVE');

    if (!hasActiveSub) {
      if (_freeTriesRemaining <= 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0B1E36),
            title: const Text('Free Limit Reached', style: TextStyle(color: Colors.white)),
            content: const Text('You have used all 3 free paraphrases. Upgrade to Premium for unlimited access!', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
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
      _versions = null;
    });

    try {
      final response = await _apiService.request(
        path: '/content/paraphrase',
        method: 'POST',
        body: jsonEncode({
          'text': _sentenceController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _versions = data['versions'] as List?;
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
        SnackBar(content: Text('Failed to paraphrase text: $e')),
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
  void dispose() {
    _sentenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final List subs = user?['subscriptions'] as List? ?? [];
    final hasActiveSub = subs.any((sub) => sub['status'] == 'ACTIVE');

    return Scaffold(
      backgroundColor: const Color(0xFF050E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFC62828), size: 16),
          label: const Text(
            'Back',
            style: TextStyle(color: Color(0xFFC62828), fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        title: const Text(
          'Paraphrase Tool',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Alert Banner Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF0284C7), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enter a sentence and get 3 different paraphrased versions. Great for IELTS Writing & Speaking.',
                      style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Your Sentence Label
            const Text(
              'Your Sentence',
              style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // White textarea card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _sentenceController,
                maxLines: 4,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                onChanged: (val) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  hintText: 'Type or paste a sentence to paraphrase...',
                  hintStyle: TextStyle(color: Colors.black26),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Paraphrase Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isParaphraseEnabled ? _paraphrase : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isParaphraseEnabled ? const Color(0xFFC62828) : const Color(0xFFE2E8F0),
                  foregroundColor: _isParaphraseEnabled ? Colors.white : Colors.black38,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: Colors.black38,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  Icons.sync,
                  size: 18,
                  color: _isParaphraseEnabled ? Colors.white : Colors.black26,
                ),
                label: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Paraphrase',
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
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            const SizedBox(height: 30),

            // Paraphrase Versions Result
            if (_versions != null && _versions!.isNotEmpty) ...[
              const Text(
                'Paraphrased Versions',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...List.generate(_versions!.length, (index) {
                final String versionText = _versions![index] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1E36),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E3E6E)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Option number badge
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFC62828),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Version text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                versionText,
                                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => _copyToClipboard(versionText),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy, color: Color(0xFFD4AF37), size: 13),
                                    SizedBox(width: 4),
                                    Text(
                                      'Copy text',
                                      style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
