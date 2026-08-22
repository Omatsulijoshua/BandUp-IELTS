import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'subscription_screen.dart';

class WritingSamplesScreen extends ConsumerStatefulWidget {
  const WritingSamplesScreen({super.key});

  @override
  ConsumerState<WritingSamplesScreen> createState() => _WritingSamplesScreenState();
}

class _WritingSamplesScreenState extends ConsumerState<WritingSamplesScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _topicController = TextEditingController();
  String _selectedTaskType = 'TASK_1_ACADEMIC'; // 'TASK_1_ACADEMIC', 'TASK_1_GENERAL', or 'TASK_2'
  bool _submitting = false;
  String? _sampleAnswer;
  int _freeTriesRemaining = 3;
  String? _uploadedImageName;

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

  Future<void> _generateSample() async {
    if (!_isGenerateEnabled) return;

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
            content: const Text('You have used all 3 free writing sample generations. Upgrade to Premium for unlimited access!', style: TextStyle(color: Colors.white70)),
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
      _sampleAnswer = null;
    });

    try {
      final response = await _apiService.request(
        path: '/content/writing/generate-sample',
        method: 'POST',
        body: jsonEncode({
          'topic': _topicController.text.trim(),
          'taskType': _selectedTaskType,
          'imageUrl': _uploadedImageName != null ? 'https://example.com/charts/$_uploadedImageName' : null,
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

  void _simulateImageUpload() {
    setState(() {
      _uploadedImageName = 'household_energy_use.png';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chart image uploaded successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeUploadedImage() {
    setState(() {
      _uploadedImageName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final List subs = user?['subscriptions'] as List? ?? [];
    final hasActiveSub = subs.any((sub) => sub['status'] == 'ACTIVE');

    final Color bgColor = const Color(0xFFF4F6FB);
    final Color cardColor = Colors.white;

    String bannerText = '';
    String placeholderText = '';
    if (_selectedTaskType == 'TASK_1_ACADEMIC') {
      bannerText = 'Task 1 Academic: Describe visual data (graphs, charts, tables, diagrams). Minimum 150 words in 20 minutes.';
      placeholderText = 'e.g. The bar chart shows the number of students enrolled in three different courses...';
    } else if (_selectedTaskType == 'TASK_1_GENERAL') {
      bannerText = 'Task 1 General: Write a letter (formal, semi-formal, or informal). Minimum 150 words in 20 minutes.';
      placeholderText = 'e.g. Write a letter to your landlord about a problem with your apartment...';
    } else {
      bannerText = 'Task 2: Write an essay (opinion, discussion, problem-solution, or advantages/disadvantages). Minimum 250 words in 40 minutes.';
      placeholderText = 'e.g. Some people believe that technology has made our lives more complicated. To what extent do you agree or disagree?';
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Writing Samples',
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Task Type section title
            const Text(
              'Select Task Type',
              style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Tab segmented container
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTaskTabButton('TASK_1_ACADEMIC', 'Task 1 (Academic)')),
                  Expanded(child: _buildTaskTabButton('TASK_1_GENERAL', 'Task 1 (General)')),
                  Expanded(child: _buildTaskTabButton('TASK_2', 'Task 2')),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tips/Guidelines Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE8D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: Colors.orange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bannerText,
                      style: const TextStyle(color: Color(0xFF7A4515), fontSize: 11, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Optional Graph/Chart Image upload row (Only for Task 1 Academic)
            if (_selectedTaskType == 'TASK_1_ACADEMIC') ...[
              const Text(
                'Graph/Chart Image (Optional)',
                style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_uploadedImageName == null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _simulateImageUpload,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF5E4E4)),
                      backgroundColor: const Color(0xFFFDF4F4),
                      foregroundColor: const Color(0xFFC62828),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text(
                      'Upload Graph or Chart',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _uploadedImageName!,
                          style: const TextStyle(color: Color(0xFF065F46), fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, color: Colors.black54, size: 16),
                        onPressed: _removeUploadedImage,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],

            // Textarea input section
            const Text(
              'Enter the topic or prompt',
              style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _topicController,
                maxLines: 4,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                decoration: InputDecoration(
                  hintText: placeholderText,
                  hintStyle: const TextStyle(color: Colors.black26),
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
                onPressed: _isGenerateEnabled ? _generateSample : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isGenerateEnabled ? const Color(0xFFC62828) : const Color(0xFFE2E8F0),
                  foregroundColor: _isGenerateEnabled ? Colors.white : Colors.black38,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: Colors.black38,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _submitting
                    ? const SizedBox.shrink()
                    : Icon(Icons.auto_awesome, size: 16, color: _isGenerateEnabled ? Colors.white : Colors.black26),
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
                        'Generate Band 9 Sample',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            if (!hasActiveSub) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '$_freeTriesRemaining free uses remaining',
                  style: const TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
            const SizedBox(height: 30),

            // Result presentation
            if (_sampleAnswer != null) ...[
              const Text(
                'Model Answer (Band 9)',
                style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
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
                      style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => _copyToClipboard(_sampleAnswer!),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, color: Color(0xFFC62828), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Copy text',
                            style: TextStyle(color: Color(0xFFC62828), fontSize: 12, fontWeight: FontWeight.bold),
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

  Widget _buildTaskTabButton(String taskType, String label) {
    final bool isSelected = _selectedTaskType == taskType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTaskType = taskType;
          _sampleAnswer = null; // Clear answer when switching task types
        });
      },
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC62828) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
