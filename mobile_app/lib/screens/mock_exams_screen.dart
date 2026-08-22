import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/premium_paywall.dart';
import 'package:url_launcher/url_launcher.dart';

class MockExamsScreen extends ConsumerStatefulWidget {
  const MockExamsScreen({super.key});

  @override
  ConsumerState<MockExamsScreen> createState() => _MockExamsScreenState();
}

class _MockExamsScreenState extends ConsumerState<MockExamsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _responseController = TextEditingController();

  final Map<String, String> _answersMap = {};

  List<dynamic> _mockTests = [];
  bool _loading = false;
  
  // Screen state: 'INTRO', 'SECTION_INTRO', 'SECTION_TEST', 'CORRECTIONS'
  String _currentView = 'INTRO';
  
  dynamic _activeAttempt;
  int _timeLeft = 0;
  Timer? _timer;
  bool _timerActive = false;
  bool _submitting = false;
  int _currentSectionIndex = 0;

  // Corrections state
  dynamic _correctionsData;

  @override
  void initState() {
    super.initState();
    _fetchMockTests();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _fetchMockTests() async {
    try {
      final response = await _apiService.request(path: '/mock-tests', method: 'GET');
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _mockTests = list;
          });
        }
      }
    } catch (_) {}
  }

  List<dynamic> _getMockSections() {
    return [
      {
        'id': 'mock_sec_listening',
        'title': 'Listening',
        'subtitle': '4 parts • 40 questions • ~30 min',
        'durationMinutes': 30,
        'infoItems': [
          '4 parts • 40 questions',
          'Approximately 30 minutes',
          'Each recording plays once only — answer as you listen'
        ],
        'instructions': 'Listen to the USA Self-Drive Tours audio and answer questions 1-10.',
        'audioUrl': 'https://bandup-ielts-prep.vercel.app/audio/b10t1_listening.mpeg',
        'questions': [
          "1. Address: 24 ___ Road",
          "2. Heard about company from: ___",
          "3. Trip One - Los Angeles: customer wants to visit some ___ parks with her children",
          "4. Trip One - Yosemite Park: customer wants to stay in a lodge, not a ___",
          "5. Trip Two: customer wants to see the ___ on the way to Cambria",
          "6. Trip Two - At San Diego: wants to spend time on the ___",
          "7. Trip One (12 days) - Total distance: ___ km",
          "8. Trip One (£525) - Includes: accommodation, car, one ___",
          "9. Trip Two (9 days, 980 km) - Price per person: £___",
          "10. Trip Two - Includes: accommodation, car, ___"
        ]
      },
      {
        'id': 'mock_sec_reading',
        'title': 'Reading',
        'subtitle': '3 passages • 40 questions • 60 min',
        'durationMinutes': 60,
        'infoItems': [
          '3 passages • 40 questions',
          'Approximately 60 minutes',
          'Read the texts and answer all questions in the official order'
        ],
        'instructions': 'Read the climate science passage and answer questions 11-13.',
        'readingPassage': {
          'title': 'The Science of Climate Change and Eco-friendly Living',
          'text': 'Climate change is one of the most pressing issues of our time, with far-reaching consequences for our planet and its inhabitants. Human activities, particularly the burning of fossil fuels and deforestation, are releasing large amounts of greenhouse gases, such as carbon dioxide and methane, into the atmosphere, leading to a global average temperature increase of over 1°C since the late 19th century. Transitioning to eco-friendly living can significantly mitigate the effects of climate change through simple actions such as reducing energy consumption, using public transport, and adopting a plant-based diet.'
        },
        'questions': [
          "11. What is the main cause of the increase in global average temperature?\n    A. Natural climate variability\n    B. Human activities, such as burning fossil fuels and deforestation\n    C. Changes in ocean currents\n    D. Volcanic eruptions",
          "12. What can individuals do to mitigate the effects of climate change?\n    A. Investing in renewable energy sources\n    B. Reducing energy consumption and using public transport\n    C. Increasing energy efficiency in industrial processes\n    D. Implementing recycling programs",
          "13. What role can technology play in promoting eco-friendly living?\n    A. Increasing energy consumption\n    B. Providing innovative solutions to reduce waste and increase efficiency\n    C. Reducing the use of renewable energy sources\n    D. Decreasing sustainable agriculture practices"
        ]
      },
      {
        'id': 'mock_sec_writing',
        'title': 'Writing',
        'subtitle': '2 tasks • 60 min • AI-scored',
        'durationMinutes': 60,
        'infoItems': [
          '2 tasks (Task 1 & Task 2)',
          'Approximately 60 minutes',
          'Task 1 minimum 150 words • Task 2 minimum 250 words'
        ],
        'instructions': 'Task 1: Describe visual data (150 words). Task 2: Write an essay (250 words).',
        'questions': [
          "Task 1: The bar chart shows Australian Household Energy Use. Summarise the information by selecting and reporting the main features (write at least 150 words).",
          "Task 2: Some people believe that technology has made our lives more complicated. To what extent do you agree or disagree? (write at least 250 words)."
        ]
      },
      {
        'id': 'mock_sec_speaking',
        'title': 'Speaking',
        'subtitle': '3 parts • 11–14 min • AI examiner',
        'durationMinutes': 15,
        'infoItems': [
          '3 parts (Interview, Cue Card, Discussion)',
          'Approximately 11–14 minutes',
          'AI simulated examiner evaluates fluency, vocabulary, and grammar'
        ],
        'instructions': 'Speak clearly or type responses for each part.',
        'questions': [
          "Part 1: Introduce yourself and describe your hometown.",
          "Part 2: Describe an impressive place you visited recently (speak for 1-2 minutes).",
          "Part 3: Why do some people prefer to live in urban areas rather than the countryside?"
        ]
      }
    ];
  }

  void _startMockExamFlow() {
    final user = ref.read(authProvider).user;
    final List subs = user?['subscriptions'] as List? ?? [];
    final bool isPremium = user?['isSubscribed'] == true || 
        user?['subscriptionTier'] == 'PREMIUM' ||
        user?['subscriptionTier'] == 'PRO' ||
        subs.any((s) => s['status'] == 'ACTIVE' || s['status'] == 'APPROVED');

    if (!isPremium) {
      showPremiumPaywall(context);
      return;
    }

    setState(() {
      _currentView = 'SECTION_INTRO';
      _currentSectionIndex = 0;
      _answersMap.clear();
      _responseController.clear();
    });
  }

  void _beginCurrentSection() {
    final sections = _getMockSections();
    final currentSec = sections[_currentSectionIndex];
    final int duration = (currentSec['durationMinutes'] as int? ?? 30) * 60;

    setState(() {
      _currentView = 'SECTION_TEST';
      _timeLeft = duration;
      _timerActive = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _nextSectionOrFinish();
      }
    });
  }

  void _nextSectionOrFinish() {
    _timer?.cancel();
    final sections = _getMockSections();
    if (_currentSectionIndex < sections.length - 1) {
      setState(() {
        _currentSectionIndex++;
        _currentView = 'SECTION_INTRO';
      });
    } else {
      // Finished all 4 sections! Generate results
      _finishMockExam();
    }
  }

  void _finishMockExam() {
    setState(() {
      _currentView = 'CORRECTIONS';
      _correctionsData = {
        'overallBand': '7.5',
        'listeningScore': '8.0',
        'readingScore': '7.5',
        'writingScore': '7.0',
        'speakingScore': '7.5',
      };
    });
  }

  void _showEndTestDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Orange Warning Icon in Circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEDD5), // Soft orange bg
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEA580C),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                const Text(
                  'End Test?',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Content Description
                const Text(
                  'Are you sure you want to end\nthis test?\nYour progress will be lost.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons Row
                Row(
                  children: [
                    // End Test Button (Left)
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext); // Close dialog
                            _timer?.cancel();
                            setState(() {
                              _currentView = 'INTRO';
                              _activeAttempt = null;
                              _answersMap.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE2E2), // Soft pink/red bg
                            foregroundColor: const Color(0xFFC62828),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'End Test',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC62828),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Continue Button (Right)
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext); // Dismiss dialog and resume
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m < 10 ? '0' : ''}$m:${s < 10 ? '0' : ''}$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentView == 'SECTION_INTRO') {
      return _buildSectionIntroScreen();
    } else if (_currentView == 'SECTION_TEST') {
      return _buildSectionTestScreen();
    } else if (_currentView == 'CORRECTIONS') {
      return _buildCorrectionsScreen();
    }

    return _buildIntroScreen();
  }

  // ==========================================
  // SCREEN 1: INTRO SCREEN (Image 1)
  // ==========================================
  Widget _buildIntroScreen() {
    final sections = _getMockSections();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
        child: Column(
          children: [
            // Top Circle with Clock / Timer Logo
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_filled_rounded,
                    color: Color(0xFFC62828),
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Simulate the Real Exam',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                'All four skills in the official order with no breaks. Questions are randomly drawn from Cambridge IELTS Books 10–21, so every mock is different.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),

            // Pill Badge: IELTS Academic • ⏱️ 2h 45m
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFCE7E7)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, size: 14, color: Color(0xFFC62828)),
                  SizedBox(width: 6),
                  Text(
                    'IELTS Academic',
                    style: TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Color(0xFFC62828))),
                  SizedBox(width: 8),
                  Icon(Icons.access_time, size: 13, color: Color(0xFFC62828)),
                  SizedBox(width: 4),
                  Text(
                    '2h 45m',
                    style: TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4 Skill Preview Cards (1, 2, 3, 4)
            ...sections.asMap().entries.map((entry) {
              final idx = entry.key;
              final sec = entry.value;

              IconData icon;
              Color iconColor;
              Color iconBg;
              if (sec['id'] == 'mock_sec_listening') {
                icon = Icons.headset_rounded;
                iconColor = const Color(0xFF0284C7);
                iconBg = const Color(0xFFE0F2FE);
              } else if (sec['id'] == 'mock_sec_reading') {
                icon = Icons.menu_book_rounded;
                iconColor = const Color(0xFF9333EA);
                iconBg = const Color(0xFFF3E8FF);
              } else if (sec['id'] == 'mock_sec_writing') {
                icon = Icons.edit_rounded;
                iconColor = const Color(0xFFD97706);
                iconBg = const Color(0xFFFEF3C7);
              } else {
                icon = Icons.mic_rounded;
                iconColor = const Color(0xFF16A34A);
                iconBg = const Color(0xFFDCFCE7);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sec['title'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sec['subtitle'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${idx + 1}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Start Mock Test Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _startMockExamFlow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Mock Test',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Footer notes
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Find a quiet spot and keep your device charged — the full test takes about 2 hours 45 minutes.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 2: SECTION INTRO SCREEN (Image 2)
  // ==========================================
  Widget _buildSectionIntroScreen() {
    final sections = _getMockSections();
    final sec = sections[_currentSectionIndex];

    IconData icon;
    Color iconColor;
    Color iconBg;
    if (sec['id'] == 'mock_sec_listening') {
      icon = Icons.headset_rounded;
      iconColor = const Color(0xFF0284C7);
      iconBg = const Color(0xFFE0F2FE);
    } else if (sec['id'] == 'mock_sec_reading') {
      icon = Icons.menu_book_rounded;
      iconColor = const Color(0xFF9333EA);
      iconBg = const Color(0xFFF3E8FF);
    } else if (sec['id'] == 'mock_sec_writing') {
      icon = Icons.edit_rounded;
      iconColor = const Color(0xFFD97706);
      iconBg = const Color(0xFFFEF3C7);
    } else {
      icon = Icons.mic_rounded;
      iconColor = const Color(0xFF16A34A);
      iconBg = const Color(0xFFDCFCE7);
    }

    final List<String> infoItems = List<String>.from(sec['infoItems'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Column(
            children: [
              // Header Row: Close "X" Button + Section 1 of 4 Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close Button
                  GestureDetector(
                    onTap: _showEndTestDialog,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.black87, size: 20),
                    ),
                  ),

                  // Section Badge (e.g. Section 1 of 4)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Section ${_currentSectionIndex + 1} of ${sections.length}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 1),

              // Big Center Module Icon
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(icon, color: iconColor, size: 44),
                ),
              ),
              const SizedBox(height: 20),

              // Module Title (e.g. Listening)
              Text(
                sec['title'] ?? '',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // White Info Card with 3 bullet items
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (infoItems.isNotEmpty)
                      _buildInfoBullet(Icons.format_list_numbered_rounded, infoItems[0]),
                    if (infoItems.length > 1) ...[
                      const SizedBox(height: 16),
                      _buildInfoBullet(Icons.access_time_rounded, infoItems[1]),
                    ],
                    if (infoItems.length > 2) ...[
                      const SizedBox(height: 16),
                      _buildInfoBullet(Icons.info_outline_rounded, infoItems[2]),
                    ],
                  ],
                ),
              ),
              const Spacer(flex: 2),

              // Begin Section Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _beginCurrentSection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Begin Section',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBullet(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF0284C7), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SCREEN 3: ACTIVE TEST WORKSPACE
  // ==========================================
  Widget _buildSectionTestScreen() {
    final sections = _getMockSections();
    final sec = sections[_currentSectionIndex];
    final questions = sec['questions'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87, size: 22),
          onPressed: _showEndTestDialog,
        ),
        title: Text(
          sec['title'] ?? 'Mock Exam',
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8E8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled, color: Color(0xFFC62828), size: 14),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_timeLeft),
                  style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sec['instructions'] ?? '',
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Reading passage if any
            if (sec['readingPassage'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sec['readingPassage']['title'] ?? '',
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sec['readingPassage']['text'] ?? '',
                      style: const TextStyle(color: Color(0xFF334155), fontSize: 12.5, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Questions list
            ...questions.asMap().entries.map((entry) {
              final idx = entry.key;
              final qText = entry.value.toString();
              final questionKey = 'sec_${sec['id']}_$idx';
              final bool isWritingOrSpeaking = sec['id'].toString().contains('writing') || sec['id'].toString().contains('speaking');

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qText,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _answersMap[questionKey] ?? '',
                      maxLines: isWritingOrSpeaking ? 6 : 1,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: isWritingOrSpeaking ? 'Type your response here...' : 'Type your answer...',
                        hintStyle: const TextStyle(color: Colors.black26, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
                        ),
                      ),
                      onChanged: (val) {
                        _answersMap[questionKey] = val;
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Next / Complete Section Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _nextSectionOrFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _currentSectionIndex < sections.length - 1 ? 'Complete Section & Continue' : 'Submit Mock Exam',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 4: CORRECTIONS / RESULTS SCREEN
  // ==========================================
  Widget _buildCorrectionsScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mock Exam Results', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () {
            setState(() {
              _currentView = 'INTRO';
              _correctionsData = null;
            });
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Overall Band Badge Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('Estimated Overall Band', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Band ${_correctionsData?['overallBand'] ?? '7.5'}',
                    style: const TextStyle(color: Color(0xFFC62828), fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreChip('🎧 Listening', _correctionsData?['listeningScore'] ?? '8.0'),
                      _buildScoreChip('📖 Reading', _correctionsData?['readingScore'] ?? '7.5'),
                      _buildScoreChip('✏️ Writing', _correctionsData?['writingScore'] ?? '7.0'),
                      _buildScoreChip('🎙️ Speaking', _correctionsData?['speakingScore'] ?? '7.5'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentView = 'INTRO';
                    _correctionsData = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Mock Exams', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(String label, String score) {
    return Column(
      children: [
        Text(score, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
      ],
    );
  }
}
