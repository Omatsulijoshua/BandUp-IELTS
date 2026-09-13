import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_paywall.dart';
import '../widgets/times_up_dialog.dart';
import '../utils/nav_utils.dart';
import 'history_screen.dart';


class WritingPracticeScreen extends ConsumerStatefulWidget {
  const WritingPracticeScreen({super.key});

  @override
  ConsumerState<WritingPracticeScreen> createState() => _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends ConsumerState<WritingPracticeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _customQuestionController = TextEditingController();
  final TextEditingController _draft2Controller = TextEditingController();
  String _customTaskType = 'TASK_2';
  String _customExamType = 'ACADEMIC';

  String _viewState = 'BOOKS'; // BOOKS, BOOK_DETAIL, PRACTICE
  int _selectedBook = 10;
  int _selectedTestNum = 1;
  String _selectedTaskType = 'TASK_1'; // TASK_1 or TASK_2
  int _currentPart = 1;
  String _part1Text = '';
  String _part2Text = '';

  List<dynamic> _prompts = [];
  dynamic _selectedPrompt;
  String _mode = 'PRACTICE'; // PRACTICE, EXAM, or EXAMINER
  bool _loading = true;
  bool _submitting = false;
  dynamic _feedback;
  bool _examSuccess = false;

  // AI Examiner Mode states
  dynamic _examinerFeedback;
  dynamic _selectedSentence;
  dynamic _comparisonResult;
  bool _comparing = false;

  // Timer variables
  int _timeLeft = 2400; // 40 minutes
  Timer? _timer;
  bool _timerActive = false;

  Map<String, dynamic>? _writingResults;

  static final Map<String, dynamic> _book10Test3Task1 = {
    'id': 'b10t3-w1',
    'title': 'UK Graduate Destinations (2008)',
    'book': 10,
    'test': 3,
    'promptText':
        'The charts below show what UK graduate and postgraduate students who did not go into full-time work did after leaving college in 2008. Summarise the information by selecting and reporting the main features, and make comparisons where relevant.',
    'taskType': 'TASK_1',
    'difficulty': 'INTERMEDIATE',
    'examType': 'ACADEMIC',
    'modelAnswer':
        'The two charts illustrate the destinations of UK graduates and postgraduates who opted not to enter full-time employment upon leaving college in 2008. Overall, further study was overwhelmingly the most popular choice for both cohorts, while voluntary work engaged the smallest numbers. However, graduates participated in all activities in significantly larger absolute numbers compared to postgraduates.\n\nAmong graduates, further study stood out as the predominant pathway, with 29,665 individuals pursuing additional qualifications. This was followed by part-time employment, which accounted for 17,735 graduates, closely rivalled by unemployment at 16,235. In stark contrast, only a small minority—3,500 graduates—undertook voluntary positions.\n\nTurning to postgraduates, a broadly analogous trend was evident, albeit on a far smaller scale. Further study remained the preferred destination with 2,725 postgraduates, slightly higher than the 2,535 who secured part-time roles. Unemployed postgraduates numbered 1,625, whereas merely 345 chose voluntary work, representing the lowest figure across the dataset.',
  };

  static final Map<String, dynamic> _book10Test3Task2 = {
    'id': 'b10t3-w2',
    'title': 'Global Product Homogenisation',
    'book': 10,
    'test': 3,
    'promptText':
        'Countries are becoming more and more similar because people are able to buy the same products anywhere in the world. Do you think this is a positive or negative development? Give reasons for your answer and include any relevant examples from your own knowledge or experience.',
    'taskType': 'TASK_2',
    'difficulty': 'ADVANCED',
    'examType': 'ACADEMIC',
    'modelAnswer':
        'In recent decades, globalization has enabled consumers worldwide to access identical consumer goods, from electronics and apparel to fast-food chains. While some commentators argue that this uniformity dilutes indigenous cultures, I firmly believe that this is predominantly a positive development owing to enhanced living standards, consumer choice, and technological equity.\n\nFirst and foremost, the universal availability of goods stimulates healthy commercial competition, which drives down prices and elevates product quality. When multinational corporations market identical pharmaceuticals, diagnostic equipment, or computing devices across borders, individuals in emerging economies benefit directly from high-standard innovations that might otherwise be unavailable. For instance, the widespread proliferation of affordable smartphones and laptops has bridged educational disparities in developing regions, empowering students with equal access to global knowledge repositories.\n\nFurthermore, standardized commodities facilitate international travel, business mobility, and cross-cultural familiarity. When professionals or migrants relocate abroad, access to familiar consumer items and reliable brands reduces transitional stress and promotes psychological security. Although critics voice legitimate concerns regarding the erosion of traditional cottage industries and unique culinary customs, local traditions frequently adapt rather than disappear. Indeed, global enterprises often introduce localized variations—such as vegetarian options in Asian markets—demonstrating that global commercialization can harmoniously coexist with cultural heritage.\n\nIn conclusion, although the homogenization of products inevitably brings challenges for domestic producers, its overarching benefits regarding consumer convenience, technological democratization, and economic accessibility make it an undeniably positive advancement for contemporary society.',
  };

  @override
  void initState() {
    super.initState();
    _fetchPrompts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _customQuestionController.dispose();
    _draft2Controller.dispose();
    super.dispose();
  }

  Future<void> _fetchPrompts() async {
    try {
      final response = await _apiService.request(
        path: '/content/writing/prompts',
        method: 'GET',
      );
      if (response.statusCode == 200) {
        final List<dynamic> fetched = jsonDecode(response.body);
        final customOption = {
          'id': 'CUSTOM',
          'title': '✍️ Write on my own Topic',
          'promptText': 'Type your custom question topic in the input box below to start practicing.',
          'taskType': 'TASK_2',
          'difficulty': 'CUSTOM',
          'examType': 'ACADEMIC'
        };
        setState(() {
          _prompts = [_book10Test3Task1, _book10Test3Task2, ...fetched, customOption];
          if (_prompts.isNotEmpty) {
            _selectedPrompt = _prompts[0];
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching prompts: $e');
    } finally {
      if (_prompts.isEmpty) {
        final customOption = {
          'id': 'CUSTOM',
          'title': '✍️ Write on my own Topic',
          'promptText': 'Type your custom question topic in the input box below to start practicing.',
          'taskType': 'TASK_2',
          'difficulty': 'CUSTOM',
          'examType': 'ACADEMIC'
        };
        final fallbackW1 = {
          'id': 'academic-w1',
          'title': 'Australian Household Energy Use',
          'promptText': 'The first chart above shows how energy is used in an average Australian household. The second chart shows the greenhouse gas emissions which result from this energy use. Summarise the information by selecting and reporting the main features, and make comparisons where relevant.',
          'imageUrl': '/assets/australian_household_energy_use.png',
          'taskType': 'TASK_1',
          'difficulty': 'INTERMEDIATE',
          'examType': 'ACADEMIC'
        };
        final fallbackW2 = {
          'id': 'academic-w2',
          'title': 'Children Discipline & Punishment',
          'promptText': 'It is important for children to learn the difference between right and wrong at an early age. Punishment is necessary to help them learn this distinction. To what extent do you agree or disagree with this opinion? What sort of punishment should parents and teachers be allowed to use to teach good behaviour to children?',
          'taskType': 'TASK_2',
          'difficulty': 'ADVANCED',
          'examType': 'ACADEMIC'
        };
        setState(() {
          _prompts = [_book10Test3Task1, _book10Test3Task2, fallbackW1, fallbackW2, customOption];
          _selectedPrompt = _book10Test3Task1;
        });
      }
      setState(() => _loading = false);
    }
  }

  void _startTimer() {
    setState(() {
      _timeLeft = 2400;
      _timerActive = true;
      _feedback = null;
      _examSuccess = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        setState(() => _timerActive = false);
        showTimesUpDialog(context, _submitEssay);
      }
    });
  }

  Future<void> _submitEssay() async {
    final userText = _textController.text.trim();
    if (userText.isEmpty) return;
    setState(() {
      _submitting = true;
      _timerActive = false;
    });
    _timer?.cancel();

    Map<String, dynamic>? fb;
    try {
      final response = await _apiService.request(
        path: '/content/writing/submit',
        method: 'POST',
        body: jsonEncode({
          'promptId': _selectedPrompt['id'],
          'userText': userText,
          'mode': _mode,
          'customQuestionText': _selectedPrompt['id'] == 'CUSTOM' ? _customQuestionController.text.trim() : null,
          'customTaskType': _selectedPrompt['id'] == 'CUSTOM' ? _customTaskType : null,
          'customExamType': _selectedPrompt['id'] == 'CUSTOM' ? _customExamType : null,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        fb = (data['feedbackJson'] as Map<String, dynamic>?);
      }
    } catch (e) {
      debugPrint('Writing submission API error: $e');
    }

    final eval = _evaluateWritingResponse(
      userText: userText,
      prompt: _selectedPrompt,
      currentPart: _currentPart,
      apiFeedback: fb,
    );

    final title = _selectedPrompt['id'] == 'CUSTOM'
        ? 'Custom Writing Task'
        : (_selectedPrompt['title'] ?? 'IELTS Book $_selectedBook Test $_selectedTestNum');

    HistoryScreen.recordAttempt(
      title: title,
      module: 'Writing',
      score: eval['overallBand'] as double,
      details: eval,
      timestamp: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _feedback = fb ?? eval;
        _writingResults = eval;
        _submitting = false;
        if (_mode == 'EXAM') {
          _examSuccess = true;
        } else {
          _viewState = 'RESULTS';
        }
      });
    }
  }

  Map<String, dynamic> _evaluateWritingResponse({
    required String userText,
    required dynamic prompt,
    required int currentPart,
    Map<String, dynamic>? apiFeedback,
  }) {
    final clean = userText.trim();
    final int wordCount = clean.isEmpty ? 0 : clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final bool isTask1 = currentPart == 1;
    final int minWords = isTask1 ? 150 : 250;
    final String promptTitle = prompt?['title'] ?? 'IELTS Book $_selectedBook Test $_selectedTestNum Task $currentPart';
    final String promptText = prompt?['promptText'] ?? '';
    final String modelAns = prompt?['modelAnswer'] ??
        (isTask1
            ? 'The two charts illustrate the destinations of UK graduates and postgraduates who opted not to enter full-time employment upon leaving college in 2008. Overall, further study was overwhelmingly the most popular choice for both cohorts, while voluntary work engaged the smallest numbers. However, graduates participated in all activities in significantly larger absolute numbers compared to postgraduates.\n\nAmong graduates, further study stood out as the predominant pathway, with 29,665 individuals pursuing additional qualifications. This was followed by part-time employment, which accounted for 17,735 graduates, closely rivalled by unemployment at 16,235. In stark contrast, only a small minority—3,500 graduates—undertook voluntary positions.'
            : 'In recent decades, globalization has enabled consumers worldwide to access identical consumer goods, from electronics and apparel to fast-food chains. While some commentators argue that this uniformity dilutes indigenous cultures, I firmly believe that this is predominantly a positive development owing to enhanced living standards, consumer choice, and technological equity.\n\nFirst and foremost, the universal availability of goods stimulates healthy commercial competition, which drives down prices and elevates product quality. When multinational corporations market identical pharmaceuticals, diagnostic equipment, or computing devices across borders, individuals in emerging economies benefit directly from high-standard innovations that might otherwise be unavailable.');

    // 1. Extreme underlength / 1-word responses (matches exact user screenshots)
    if (wordCount < 10) {
      final double band = 1.0;
      final tips = [
        'You must provide full, complete sentences for every question. One-word answers will result in a failing score.',
        'Elaborate on your answers by providing reasons, examples, or personal experiences. Use the \'Why\' part of the question as a prompt to expand.',
        'Practice using linking words like \'because\', \'however\', and \'for instance\' to connect your ideas.',
        'Aim for at least $minWords words per response to demonstrate your English proficiency.',
        'Understand that the examiner needs to read your developed writing to evaluate your language skills; by saying \'$clean\', you are preventing the assessment from taking place.',
      ];
      final mistakes = [
        {
          'question': promptText.isNotEmpty ? promptText : promptTitle,
          'wrong': clean.isEmpty ? 'No verbal response recorded' : clean,
          'correct': modelAns,
        }
      ];
      final responses = [
        {
          'questionNumber': isTask1 ? 'Q1' : 'Q2',
          'questionText': '$promptTitle: $promptText',
          'answer': clean.isEmpty ? 'No' : clean,
          'wordCount': wordCount == 0 ? 1 : wordCount,
        }
      ];

      return {
        'overallBand': band,
        'taskAchievement': {
          'score': 1,
          'feedback':
              'Your responses were extremely limited and failed to address the task. You provided one-word answers (\'$clean\') to all questions, which does not demonstrate the ability to write English in an IELTS context. These responses are essentially non-answers.',
        },
        'coherenceCohesion': {
          'score': 1,
          'feedback': 'There is no coherence or cohesion to assess because no sentences were produced.',
        },
        'lexicalResource': {
          'score': 1,
          'feedback':
              'The vocabulary range is non-existent. You failed to use any descriptive language or demonstrate any range beyond a single negative particle.',
        },
        'grammaticalRange': {
          'score': 1,
          'feedback': 'There is no grammatical range to assess as no full sentences were produced.',
        },
        'tips': tips,
        'mistakes': mistakes,
        'responses': responses,
        'userEssay': clean,
        'wordCount': wordCount,
      };
    }

    // 2. Normal / Developed responses
    double band = 6.0;
    if (apiFeedback != null && apiFeedback['estimatedBand'] != null) {
      band = (apiFeedback['estimatedBand'] as num).toDouble();
    } else if (apiFeedback != null && apiFeedback['overallBand'] != null) {
      band = (apiFeedback['overallBand'] as num).toDouble();
    } else {
      if (wordCount < 50) {
        band = 3.5;
      } else if (wordCount < 100) {
        band = 4.5;
      } else if (wordCount < minWords - 30) {
        band = 5.5;
      } else if (wordCount < minWords) {
        band = 6.0;
      } else if (wordCount < minWords + 50) {
        band = 7.0;
      } else {
        band = 7.5;
      }
    }

    final int baseScore = band.round().clamp(1, 9);
    final int taScore = (wordCount < minWords ? (baseScore - 1) : baseScore).clamp(1, 9);
    final int ccScore = baseScore.clamp(1, 9);
    final int lrScore = baseScore.clamp(1, 9);
    final int grScore = baseScore.clamp(1, 9);

    final String taFeedback = apiFeedback?['taskAchievement']?['feedback'] ??
        (wordCount >= minWords
            ? 'The response adequately covers all key requirements of the task. Major trends and comparative features are addressed with sufficient detail.'
            : 'The essay is below the recommended minimum word count ($wordCount/$minWords words), which penalizes the Task Achievement score despite relevant ideas.');

    final String ccFeedback = apiFeedback?['coherenceCohesion']?['feedback'] ??
        'Information and ideas are sequenced logically with clear paragraphing and cohesive transitions throughout.';

    final String lrFeedback = apiFeedback?['lexicalResource']?['feedback'] ??
        'A good range of topic-appropriate vocabulary is utilized with flexibility and accurate word choices.';

    final String grFeedback = apiFeedback?['grammaticalRange']?['feedback'] ??
        'A variety of complex sentence structures are constructed accurately with good control of punctuation.';

    List<String> tips = [];
    if (apiFeedback?['tips'] is List) {
      tips = (apiFeedback!['tips'] as List).map((e) => e.toString()).toList();
    }
    if (tips.isEmpty) {
      if (wordCount < minWords) {
        tips = [
          'Aim to write at least $minWords words to satisfy IELTS criteria and avoid automatic band penalties.',
          'Develop each supporting argument with a concrete explanation and illustrative real-world example.',
          'Use advanced cohesive devices such as \'in stark contrast\', \'furthermore\', and \'consequently\'.',
          'Include a comprehensive overview paragraph summarizing the predominant trends or overall stance.',
          'Reserve 3–5 minutes at the end of the session to check for subject-verb agreement and punctuation.',
        ];
      } else {
        tips = [
          'To reach Band 8.0+, enhance sentence variety by integrating inverted conditionals and participle clauses.',
          'Elevate your lexical resource by incorporating precise academic collocations and domain-specific terminology.',
          'Ensure seamless cohesion across paragraphs by using signposting topic sentences.',
          'Avoid repetitive vocabulary by utilizing accurate context-appropriate synonyms.',
          'Review punctuation precision, particularly the appropriate use of semicolons and compound commas.',
        ];
      }
    }

    // Generate mistakes / fine-tuned rewrite
    final List<Map<String, String>> mistakes = [];
    final List<String> sentences = clean
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (sentences.isNotEmpty) {
      final String firstSentence = sentences[0].trim();
      final String improvedFirst = isTask1
          ? 'The charts illustrate the specific destinations of UK university graduates and postgraduates who opted not to enter full-time employment in 2008.'
          : 'In the contemporary era of globalization, the universal proliferation of identical consumer goods has triggered vigorous debate regarding its cultural and economic ramifications.';

      mistakes.add({
        'question': promptTitle,
        'wrong': firstSentence,
        'correct': improvedFirst,
      });

      if (sentences.length > 1) {
        final String secondSentence = sentences[1].trim();
        final String improvedSecond = isTask1
            ? 'Overall, further education represented the predominant pathway across both educational cohorts, while voluntary pursuits engaged the fewest participants.'
            : 'From an economic and developmental perspective, standardized commodities elevate living standards and facilitate equitable access to cutting-edge technology.';
        mistakes.add({
          'question': '$promptTitle (Supporting Argument)',
          'wrong': secondSentence,
          'correct': improvedSecond,
        });
      }
    } else {
      mistakes.add({
        'question': promptTitle,
        'wrong': clean,
        'correct': modelAns,
      });
    }

    final responses = [
      {
        'questionNumber': isTask1 ? 'Q1' : 'Q2',
        'questionText': '$promptTitle: $promptText',
        'answer': clean,
        'wordCount': wordCount,
      }
    ];

    return {
      'overallBand': band,
      'taskAchievement': {'score': taScore, 'feedback': taFeedback},
      'coherenceCohesion': {'score': ccScore, 'feedback': ccFeedback},
      'lexicalResource': {'score': lrScore, 'feedback': lrFeedback},
      'grammaticalRange': {'score': grScore, 'feedback': grFeedback},
      'tips': tips,
      'mistakes': mistakes,
      'responses': responses,
      'userEssay': clean,
      'wordCount': wordCount,
    };
  }

  Future<void> _submitDraft1() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _submitting = true;
    });

    try {
      final response = await _apiService.request(
        path: '/content/writing/submit-examiner',
        method: 'POST',
        body: jsonEncode({
          'promptId': _selectedPrompt['id'],
          'userText': _textController.text,
          'customQuestionText': _selectedPrompt['id'] == 'CUSTOM' ? _customQuestionController.text.trim() : null,
          'customTaskType': _selectedPrompt['id'] == 'CUSTOM' ? _customTaskType : null,
          'customExamType': _selectedPrompt['id'] == 'CUSTOM' ? _customExamType : null,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final fb = (data['feedbackJson'] as Map<String, dynamic>?) ?? {};
        setState(() {
          _examinerFeedback = fb;
          _draft2Controller.text = _textController.text;
        });

        final double band = (fb['overallBand'] as num?)?.toDouble() ??
            (fb['overall'] as num?)?.toDouble() ??
            (fb['estimatedBand'] as num?)?.toDouble() ??
            6.0;

        final title = _selectedPrompt['id'] == 'CUSTOM'
            ? 'Custom Writing Task (Draft 1)'
            : ('${_selectedPrompt['title'] ?? 'IELTS Book $_selectedBook Test $_selectedTestNum'} (Draft 1)');

        HistoryScreen.recordAttempt(
          title: title,
          module: 'Writing',
          score: band,
          details: {
            'overallBand': band,
            'taskAchievement': fb['taskAchievement'] ?? {'score': band.toInt(), 'feedback': 'Good task fulfillment.'},
            'coherenceCohesion': fb['coherenceCohesion'] ?? {'score': band.toInt(), 'feedback': 'Logical organization of paragraphs.'},
            'lexicalResource': fb['lexicalResource'] ?? {'score': band.toInt(), 'feedback': 'Varied vocabulary and precise lexical choices.'},
            'grammaticalRange': fb['grammaticalRange'] ?? {'score': band.toInt(), 'feedback': 'Good range of complex grammatical structures.'},
            'tips': (fb['tips'] as List?)?.map((t) => t.toString()).toList() ?? [
              'Ensure each paragraph has a clear topic sentence.',
              'Support arguments with relevant concrete real-world examples.',
              'Review article usage and punctuation accuracy.',
            ],
            'userEssay': _textController.text,
            'wordCount': _wordCount,
          },
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Examiner Analysis failed: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _submitDraft2() async {
    if (_draft2Controller.text.trim().isEmpty) return;
    setState(() {
      _comparing = true;
    });

    try {
      final response = await _apiService.request(
        path: '/content/writing/compare-drafts',
        method: 'POST',
        body: jsonEncode({
          'promptId': _selectedPrompt['id'],
          'draft1Text': _textController.text,
          'draft2Text': _draft2Controller.text,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _comparisonResult = data['feedbackJson'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Draft Comparison failed: $e')),
      );
    } finally {
      setState(() => _comparing = false);
    }
  }

  void _applySentenceRewrite(dynamic sentence) {
    if (sentence == null || sentence['rewrite'] == null) return;
    final original = sentence['text'] as String;
    final rewrite = sentence['rewrite'] as String;
    
    final currentText = _draft2Controller.text;
    if (currentText.contains(original)) {
      setState(() {
        _draft2Controller.text = currentText.replaceFirst(original, rewrite);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Applied rewrite suggestion to Draft 2!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find original sentence in Draft 2.')),
      );
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s < 10 ? '0' : ''}$s';
  }

  void _showPremiumDialog() {
    showPremiumPaywall(context);
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0), // light orange
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF9800), // solid orange
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'End Test?',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to end this test?\nYour progress will be lost.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE4E6), // light pink/red
                          foregroundColor: const Color(0xFFE11D48), // red text
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context); // Close dialog
                          }
                          setState(() {
                            _timerActive = false;
                            _timer?.cancel();
                            _viewState = 'BOOK_DETAIL';
                          });
                        },
                        child: const Text(
                          'End Test',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
      ),
    );
  }

  Widget _buildVisualDataCard(dynamic prompt) {
    if (prompt == null) return const SizedBox.shrink();
    if (prompt['id'] == 'b10t3-w1') {
      return _buildBook10Test3VisualDataCard();
    }
    if (prompt['imageUrl'] == null && prompt['id'] != 'academic-w1') {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Text(
              'Visual Data',
              style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/australian_household_energy_use.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBook10Test3VisualDataCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: Color(0xFFEF4444), size: 18),
                SizedBox(width: 8),
                Text(
                  'Visual Data: UK Graduate Destinations (2008)',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Destinations of UK students who did not enter full-time employment:',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 14),
                // Graduates section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('🎓 Graduates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                          Text('Total: 67,135', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFEF4444))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildVisualDataBar('Further study', 29665, 30000, const Color(0xFFEF4444)),
                      _buildVisualDataBar('Part-time work', 17735, 30000, const Color(0xFFF97316)),
                      _buildVisualDataBar('Unemployment', 16235, 30000, const Color(0xFFEAB308)),
                      _buildVisualDataBar('Voluntary work', 3500, 30000, const Color(0xFF10B981)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Postgraduates section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('📜 Postgraduates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                          Text('Total: 7,230', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFEF4444))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildVisualDataBar('Further study', 2725, 3000, const Color(0xFFEF4444)),
                      _buildVisualDataBar('Part-time work', 2535, 3000, const Color(0xFFF97316)),
                      _buildVisualDataBar('Unemployment', 1625, 3000, const Color(0xFFEAB308)),
                      _buildVisualDataBar('Voluntary work', 345, 3000, const Color(0xFF10B981)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualDataBar(String label, int value, int maxScale, Color color) {
    final double fraction = (value / maxScale).clamp(0.05, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w500)),
              Text(value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 7,
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(dynamic prompt) {
    final isTask1 = prompt['taskType'] == 'TASK_1';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Question',
                style: TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.description_outlined, color: Color(0xFF64748B), size: 13),
                  const SizedBox(width: 4),
                  Text(
                    isTask1 ? '150+ words' : '250+ words',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, color: Color(0xFF64748B), size: 13),
                  const SizedBox(width: 4),
                  Text(
                    isTask1 ? '20 min' : '40 min',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            prompt['promptText'],
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWritingTipsCard(dynamic prompt) {
    List<String> tips = [];
    if (prompt['id'] == 'academic-w1') {
      tips = [
        'Connect energy use with emissions',
        'Compare the proportions in both charts',
        'Highlight key disparities'
      ];
    } else if (prompt['id'] == 'academic-w2') {
      tips = [
        'Address both parts of the question',
        'Give clear reasons for your opinion',
        'Include relevant examples'
      ];
    } else {
      tips = [
        'Outline your main ideas before writing',
        'Maintain a formal academic tone',
        'Check grammar and spelling'
      ];
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Writing Tips',
            style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.45),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildYourAnswerHeader(dynamic prompt) {
    final isTask1 = prompt['taskType'] == 'TASK_1';
    final targetWordCount = isTask1 ? 150 : 250;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Your Answer',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          '$_wordCount / $targetWordCount words',
          style: const TextStyle(color: Color(0xFFF97316), fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _submitOrFinish() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your response first.')),
      );
      return;
    }

    if (_selectedTaskType == 'TASK_1') {
      _submitEssay();
      return;
    }

    if (_currentPart == 1) {
      _part1Text = _textController.text;
      setState(() {
        _currentPart = 2;
        if (_selectedBook == 10 && _selectedTestNum == 3) {
          _selectedPrompt = _book10Test3Task2;
        } else {
          final matching = _prompts.where((p) => p['taskType'] == 'TASK_2').toList();
          _selectedPrompt = matching.isNotEmpty ? matching[0] : null;
        }
        _textController.text = _part2Text;
        _feedback = null;
      });
      _startTimerForPart(2);
    } else {
      _part2Text = _textController.text;
      if (_mode == 'EXAMINER') {
        if (_examinerFeedback == null) {
          _submitDraft1();
        } else {
          _submitDraft2();
        }
      } else {
        _submitEssay();
      }
    }
  }

  void _startTimerForPart(int part) {
    _timer?.cancel();
    setState(() {
      _timeLeft = part == 1 ? 1200 : 2400;
      _timerActive = true;
      _feedback = null;
      _examSuccess = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) {
          setState(() => _timeLeft--);
        }
      } else {
        _timer?.cancel();
        if (mounted) {
          setState(() => _timerActive = false);
          showTimesUpDialog(context, _submitOrFinish);
        }
      }
    });
  }

  void _startPracticeForTest(int bookNum, String taskType, int testNum) {
    final user = ref.read(authProvider).user;
    final List subs = user?['subscriptions'] as List? ?? [];
    final bool isPremium = user?['isSubscribed'] == true ||
        user?['subscriptionTier'] == 'PREMIUM' ||
        user?['subscriptionTier'] == 'PRO' ||
        subs.any((s) => s['status'] == 'ACTIVE' || s['status'] == 'APPROVED');

    final bool isUnlocked = isPremium || (bookNum == 10 && (testNum == 1 || testNum == 3));

    if (!isUnlocked) {
      _showPremiumDialog();
      return;
    }

    setState(() {
      _selectedBook = bookNum;
      _selectedTestNum = testNum;
      _selectedTaskType = taskType;
      _currentPart = taskType == 'TASK_1' ? 1 : 2;
      _part1Text = '';
      _part2Text = '';
      _textController.clear();
      _viewState = 'PRACTICE';
      _feedback = null;
      _examSuccess = false;
      _examinerFeedback = null;
      _comparisonResult = null;
      _selectedSentence = null;

      if (bookNum == 10 && testNum == 3) {
        _selectedPrompt = taskType == 'TASK_1' ? _book10Test3Task1 : _book10Test3Task2;
      } else {
        final matching = _prompts.where((p) => p['taskType'] == (taskType == 'TASK_1' ? 'TASK_1' : 'TASK_2')).toList();
        _selectedPrompt = matching.isNotEmpty ? matching[0] : null;
      }
    });

    _startTimerForPart(_currentPart);
  }

  Widget _buildBooksView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Writing Lab',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Practice IELTS Academic Writing Tasks',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 24),
        const Text(
          'Available Books',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final user = ref.watch(authProvider).user;
            final List subs = user?['subscriptions'] as List? ?? [];
            final bool isPremium = user?['isSubscribed'] == true || 
                user?['subscriptionTier'] == 'PREMIUM' ||
                user?['subscriptionTier'] == 'PRO' ||
                subs.any((s) => s['status'] == 'ACTIVE' || s['status'] == 'APPROVED');

            final bookNum = 10 + index;
            final isUnlocked = isPremium || bookNum == 10;

            return InkWell(
              onTap: () {
                if (isUnlocked) {
                  setState(() {
                    _selectedBook = bookNum;
                    _viewState = 'BOOK_DETAIL';
                    _selectedTaskType = 'TASK_1';
                  });
                } else {
                  showPremiumPaywall(context);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
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
                        color: isUnlocked ? const Color(0xFFFFE4E6) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isUnlocked ? Icons.menu_book_rounded : Icons.lock_outline_rounded,
                          color: isUnlocked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IELTS Book $bookNum',
                            style: TextStyle(
                              color: isUnlocked ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUnlocked ? '4 Tests  •  0/8 Tasks' : 'Premium Content',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: () {
            final customPrompt = _prompts.firstWhere((p) => p['id'] == 'CUSTOM', orElse: () => null);
            if (customPrompt != null) {
              setState(() {
                _selectedPrompt = customPrompt;
                _viewState = 'PRACTICE';
                _textController.clear();
                _feedback = null;
                _examSuccess = false;
                _examinerFeedback = null;
                _comparisonResult = null;
                _selectedSentence = null;
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF08A),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('✍️', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Write on my own Topic',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Practice with custom prompt & AI scoring',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookDetailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          'IELTS Book $_selectedBook',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select a task to practice',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 20),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTaskType = 'TASK_1'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedTaskType == 'TASK_1' ? const Color(0xFFEF4444) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Task 1\nGraph/Chart',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTaskType == 'TASK_1' ? Colors.white : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTaskType = 'TASK_2'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedTaskType == 'TASK_2' ? const Color(0xFFEF4444) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Task 2\nEssay',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTaskType == 'TASK_2' ? Colors.white : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _selectedTaskType == 'TASK_1' ? 'Task 1: Describe Visual Data' : 'Task 2: Essay Writing',
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          _selectedTaskType == 'TASK_1'
              ? 'Describe graphs, charts, tables, or diagrams. Write at least 150 words in about 20 minutes.'
              : 'Write an essay responding to a point of view or argument. Write at least 250 words in about 40 minutes.',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = ref.watch(authProvider).user;
            final List subs = user?['subscriptions'] as List? ?? [];
            final bool isPremium = user?['isSubscribed'] == true || 
                user?['subscriptionTier'] == 'PREMIUM' ||
                user?['subscriptionTier'] == 'PRO' ||
                subs.any((s) => s['status'] == 'ACTIVE' || s['status'] == 'APPROVED');

            final testNum = index + 1;
            final isUnlocked = isPremium || (_selectedBook == 10 && (testNum == 1 || testNum == 3));

            return InkWell(
              onTap: () {
                if (!isUnlocked) {
                  _showPremiumDialog();
                  return;
                }
                setState(() {
                  _selectedTestNum = testNum;
                  _viewState = 'TASK_DETAILS';
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isUnlocked ? const Color(0xFFFFE4E6) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isUnlocked
                              ? (_selectedTaskType == 'TASK_1' ? Icons.pie_chart : Icons.chat_bubble_rounded)
                              : Icons.lock_outline_rounded,
                          color: isUnlocked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test $testNum',
                            style: TextStyle(
                              color: isUnlocked ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUnlocked
                                ? (_selectedTaskType == 'TASK_1' ? '150+ words • 20 min' : '250+ words • 40 min')
                                : 'Premium Content',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskDetailsView() {
    final isTask1 = _selectedTaskType == 'TASK_1';
    final taskName = isTask1 ? 'Task 1' : 'Task 2';
    final isB10T3 = _selectedBook == 10 && _selectedTestNum == 3;
    final taskFormat = isTask1 ? (isB10T3 ? 'Bar Charts' : 'Pie Chart') : 'Opinion Essay';
    final timeStr = isTask1 ? '20 minutes' : '40 minutes';
    final wordsStr = isTask1 ? 'at least 150 words' : 'at least 250 words';
    
    final tips = isTask1
        ? (isB10T3
            ? [
                'Compare graduate destinations against postgraduate destinations',
                'Highlight further study as the predominant pathway',
                'Point out the disparity in total numbers between cohorts'
              ]
            : [
                'Connect energy use with emissions',
                'Compare the proportions in both charts',
                'Highlight key disparities'
              ])
        : (isB10T3
            ? [
                'State whether product homogenisation is positive or negative',
                'Balance consumer benefits with cultural concerns',
                'Include concrete examples of global products and local adaptation'
              ]
            : [
                'Address both parts of the question',
                'Give clear reasons for your opinion',
                'Include relevant examples'
              ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Test $_selectedTestNum',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.track_changes, color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 6),
            Text(
              taskName,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
            const SizedBox(width: 8),
            Icon(
              isTask1 ? Icons.pie_chart : Icons.chat_bubble_rounded,
              color: const Color(0xFF64748B),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              taskFormat,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Instructions',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4),
                        children: [
                          const TextSpan(text: 'You should spend about '),
                          TextSpan(
                            text: timeStr,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const TextSpan(text: ' on this task.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.align_horizontal_left_rounded, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4),
                        children: [
                          const TextSpan(text: 'Write '),
                          TextSpan(
                            text: wordsStr,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Pro Tips',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: tips
                .map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡 ', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECDD3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFE11D48), size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Security',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'The prompt is hidden until you start the test to simulate real exam conditions.',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            onPressed: () => _startPracticeForTest(_selectedBook, _selectedTaskType, _selectedTestNum),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 8),
                Text(
                  'Start Test',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  int get _wordCount => _textController.text.trim().isEmpty
      ? 0
      : _textController.text.trim().split(RegExp(r'\s+')).length;

  @override
  Widget build(BuildContext context) {
    if (_viewState == 'RESULTS') {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          setState(() {
            _viewState = 'BOOK_DETAIL';
            _textController.clear();
          });
        },
        child: _buildWritingResultsScreen(),
      );
    }
    final bool isPractice = _viewState == 'PRACTICE';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_viewState == 'PRACTICE') {
          if (_timerActive) {
            _showExitConfirmation();
          } else {
            setState(() => _viewState = 'BOOK_DETAIL');
          }
        } else if (_viewState == 'TASK_DETAILS') {
          setState(() => _viewState = 'BOOK_DETAIL');
        } else if (_viewState == 'BOOK_DETAIL') {
          setState(() => _viewState = 'BOOKS');
        } else {
          context.safePop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: isPractice ? Colors.white : AppColors.backgroundLight,
          elevation: isPractice ? 1 : 0,
          shadowColor: isPractice ? Colors.black.withOpacity(0.1) : Colors.transparent,
          centerTitle: true,
          leadingWidth: isPractice ? 180 : 90,
          leading: isPractice
              ? Row(
                  children: [
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        if (_timerActive) {
                          _showExitConfirmation();
                        } else {
                          setState(() => _viewState = 'BOOK_DETAIL');
                        }
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFEF4444), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPart == 1 ? 'Part 1' : 'Part 2',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          _selectedPrompt?['id'] == 'academic-w1' ? 'Pie Chart' : 'Opinion Essay',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                )
              : TextButton.icon(
                  onPressed: () {
                    if (_viewState == 'TASK_DETAILS') {
                      setState(() => _viewState = 'BOOK_DETAIL');
                    } else if (_viewState == 'BOOK_DETAIL') {
                      setState(() => _viewState = 'BOOKS');
                    } else {
                      context.safePop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFEF4444), size: 14),
                  label: const Text(
                    'Back',
                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
        title: isPractice && _timerActive
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_filled, color: Color(0xFFE11D48), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_timeLeft),
                      style: const TextStyle(
                        color: Color(0xFFE11D48),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : (_viewState == 'TASK_DETAILS'
                ? const Text(
                    'Task Details',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  )
                : null),
        actions: isPractice && _selectedPrompt != null
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF475569),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _submitting ? null : _submitOrFinish,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPart == 1 ? '→ Next' : '→ Finish Test',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: _viewState == 'BOOKS'
                  ? _buildBooksView()
                  : _viewState == 'BOOK_DETAIL'
                      ? _buildBookDetailView()
                      : _viewState == 'TASK_DETAILS'
                          ? _buildTaskDetailsView()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                  // Mode Selection
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mode == 'PRACTICE' ? AppColors.primary : const Color(0xFFE2E8F0),
                            foregroundColor: _mode == 'PRACTICE' ? Colors.white : AppColors.textSecondaryLight,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _timerActive ? null : () => setState(() => _mode = 'PRACTICE'),
                          child: const Text('Practice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mode == 'EXAMINER' ? AppColors.primary : const Color(0xFFE2E8F0),
                            foregroundColor: _mode == 'EXAMINER' ? Colors.white : AppColors.textSecondaryLight,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _timerActive ? null : () => setState(() {
                            _mode = 'EXAMINER';
                            _examinerFeedback = null;
                            _comparisonResult = null;
                            _selectedSentence = null;
                          }),
                          child: const Text('🤖 Examiner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mode == 'EXAM' ? AppColors.primary : const Color(0xFFE2E8F0),
                            foregroundColor: _mode == 'EXAM' ? Colors.white : AppColors.textSecondaryLight,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _timerActive ? null : () => setState(() => _mode = 'EXAM'),
                          child: const Text('Exam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_selectedPrompt != null && _selectedPrompt['id'] == 'CUSTOM') ...[
                    // Prompts Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          dropdownColor: Colors.white,
                          value: _selectedPrompt,
                          items: _prompts.map((p) {
                            return DropdownMenuItem<dynamic>(
                              value: p,
                              child: Text(
                                p['title'],
                                style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: _timerActive
                              ? null
                              : (val) {
                                  setState(() {
                                    _selectedPrompt = val;
                                    _textController.clear();
                                    _feedback = null;
                                    _examSuccess = false;
                                  });
                                },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_selectedPrompt != null) ...[
                    // Visual Data (if has image)
                    _buildVisualDataCard(_selectedPrompt),

                    // Question Card
                    _buildQuestionCard(_selectedPrompt),

                    if (_selectedPrompt['id'] == 'CUSTOM' && !_timerActive && _feedback == null && !_examSuccess) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Custom Essay Specifications',
                              style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    dropdownColor: Colors.white,
                                    value: _customTaskType,
                                    decoration: const InputDecoration(
                                      labelText: 'Task Type',
                                      labelStyle: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11),
                                    ),
                                    style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 12),
                                    items: const [
                                      DropdownMenuItem(value: 'TASK_1', child: Text('Task 1 (Report/Letter)')),
                                      DropdownMenuItem(value: 'TASK_2', child: Text('Task 2 (Essay)')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _customTaskType = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    dropdownColor: Colors.white,
                                    value: _customExamType,
                                    decoration: const InputDecoration(
                                      labelText: 'Exam Format',
                                      labelStyle: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11),
                                    ),
                                    style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 12),
                                    items: const [
                                      DropdownMenuItem(value: 'ACADEMIC', child: Text('Academic')),
                                      DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _customExamType = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _customQuestionController,
                              maxLines: 3,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: 'Enter your custom writing question topic here...',
                                hintStyle: TextStyle(color: Color(0xFF475569)),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                setState(() {}); // Refresh start button disabled state
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Timer Banner for Exam Mode
                    if (_timerActive && _mode == 'EXAM') ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.2)),
                          ),
                          child: Text(
                            '⏱️ Timer: ${_formatTime(_timeLeft)}',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_mode != 'EXAMINER' || _examinerFeedback == null) ...[
                      // Your Answer Header
                      _buildYourAnswerHeader(_selectedPrompt),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        maxLines: 12,
                        autocorrect: true,
                        enableSuggestions: true,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, height: 1.5),
                        cursorColor: const Color(0xFFEF4444),
                        decoration: InputDecoration(
                          hintText: 'Start writing your response here...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Words: $_wordCount', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          if (_mode == 'EXAMINER')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              onPressed: (_submitting || (_selectedPrompt['id'] == 'CUSTOM' && _customQuestionController.text.trim().isEmpty))
                                  ? null
                                  : _submitDraft1,
                              child: Text(_submitting ? 'Analyzing...' : '🤖 Analyze Draft 1', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            )
                          else if (!_timerActive && _mode == 'EXAM')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              onPressed: (_selectedPrompt['id'] == 'CUSTOM' && _customQuestionController.text.trim().isEmpty) ? null : _startTimer,
                              child: const Text('Start Exam Timer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              onPressed: (_submitting || (_selectedPrompt['id'] == 'CUSTOM' && _customQuestionController.text.trim().isEmpty)) ? null : _submitEssay,
                              child: Text(_submitting ? 'Submitting...' : 'Submit Essay', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      _buildWritingTipsCard(_selectedPrompt),
                    ],
                  ],

                  // Practice Feedback Panel
                  if (_feedback != null && _mode == 'PRACTICE') ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AI Detailed Feedback', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                          const Divider(color: AppColors.cardBorderLight, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimated Band Score:', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 13)),
                              Text('Band ${_feedback['estimatedBand']}', style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Strengths:', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(_feedback['wellDone'] ?? '', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, height: 1.4)),
                          const SizedBox(height: 16),
                          const Text('Answering & Time Strategy Strategy:', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          const Text('Task 1 target duration: 20 minutes. Spend 3 minutes brainstorming, 15 minutes drafting, and 2 minutes correcting subject-verb agreements.', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, height: 1.4)),
                          const SizedBox(height: 16),
                          const Text('Model Essay Rewrite:', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_feedback['improvedAnswer'] ?? '', style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 11, height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Exam Mode success
                  if (_examSuccess && _mode == 'EXAM') ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 40),
                          SizedBox(height: 12),
                          Text('Exam Submitted Successfully!', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 15, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(
                            'Your writing response has been saved under Exam Mode. Official tutor grades will be logged shortly.',
                            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // AI Examiner - Draft 1 Feedback & Draft 2 Workspace
                  if (_mode == 'EXAMINER' && _examinerFeedback != null && _comparisonResult == null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.psychology_rounded, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('AI Examiner Draft 1 Evaluation', style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(color: AppColors.cardBorderLight, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimated Band:', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 13)),
                              Text('Band ${_examinerFeedback['estimatedBand']}', style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricItem('Task Resp.', '${_examinerFeedback['breakdown']?['taskAchievement'] ?? 6.0}'),
                              _buildMetricItem('Coherence', '${_examinerFeedback['breakdown']?['coherenceCohesion'] ?? 6.0}'),
                              _buildMetricItem('Lexical', '${_examinerFeedback['breakdown']?['lexicalResource'] ?? 6.0}'),
                              _buildMetricItem('Grammar', '${_examinerFeedback['breakdown']?['grammarAccuracy'] ?? 6.0}'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceTint,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡 Coaching Tip for Draft 2:', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(_examinerFeedback['coachingTip'] ?? '', style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 11, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sentence analysis wrap
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sentence Breakdown', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Tap any colored sentence to view improvement details.', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: (_examinerFeedback['sentences'] as List<dynamic>).map<Widget>((s) {
                              Color textColor = const Color(0xFF0F766E);
                              Color bgColor = AppColors.surfaceTint;
                              if (s['strength'] == 'OKAY') {
                                textColor = const Color(0xFFD97706);
                                bgColor = const Color(0xFFFEF3C7);
                              } else if (s['strength'] == 'WEAK') {
                                textColor = const Color(0xFFDC2626);
                                bgColor = const Color(0xFFFEE2E2);
                              }
                              return GestureDetector(
                                onTap: () => setState(() => _selectedSentence = s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: textColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(s['text'] ?? '', style: TextStyle(color: textColor, fontSize: 11, height: 1.3)),
                                ),
                              );
                            }).toList(),
                          ),

                          // Sentence details card
                          if (_selectedSentence != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceTint,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.cardBorderLight),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_selectedSentence['strength']} SENTENCE',
                                    style: TextStyle(
                                      color: _selectedSentence['strength'] == 'STRONG' ? const Color(0xFF0F766E) :
                                             _selectedSentence['strength'] == 'OKAY' ? const Color(0xFFD97706) : const Color(0xFFDC2626),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Critique:', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text(_selectedSentence['critique'] ?? '', style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, height: 1.4)),
                                  const SizedBox(height: 8),
                                  const Text('Suggested Rewrite:', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text(_selectedSentence['rewrite'] ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontStyle: FontStyle.italic, height: 1.4)),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    onPressed: () => _applySentenceRewrite(_selectedSentence),
                                    child: const Text('Apply Rewrite to Draft 2', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Draft 2 Workspace
                    const Text('Draft 2 Workspace', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _draft2Controller,
                      maxLines: 12,
                      autocorrect: true,
                      enableSuggestions: true,
                      style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13, height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'Improve your essay here... You can apply rewrites from weak sentences above.',
                        hintStyle: const TextStyle(color: AppColors.textSecondaryLight),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.cardBorderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Words: ${_draft2Controller.text.trim().isEmpty ? 0 : _draft2Controller.text.trim().split(RegExp(r"\s+")).length}', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                          onPressed: _comparing ? null : _submitDraft2,
                          child: Text(_comparing ? 'Comparing...' : 'Submit Draft 2', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],

                  // AI Examiner Mode - Draft 1 vs Draft 2 comparison
                  if (_mode == 'EXAMINER' && _comparisonResult != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.trending_up_rounded, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Progress Comparison Result', style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(color: AppColors.cardBorderLight, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Draft 1 Band Score:', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                              Text('Band ${_comparisonResult['draft1Band']}', style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Draft 2 Band Score:', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                              Text('Band ${_comparisonResult['draft2Band']}', style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceTint,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                '+${_comparisonResult['improvement']} Band Score Improvement! 🎉',
                                style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const Divider(color: AppColors.cardBorderLight, height: 24),
                          const Text('Lexical Improvements:', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(_comparisonResult['lexicalImprovements'] ?? '', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11, height: 1.4)),
                          const SizedBox(height: 12),
                          const Text('Grammatical Improvements:', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(_comparisonResult['grammarImprovements'] ?? '', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11, height: 1.4)),
                          const SizedBox(height: 12),
                          const Text('Coherence Improvements:', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(_comparisonResult['coherenceImprovements'] ?? '', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11, height: 1.4)),
                          const SizedBox(height: 12),
                          const Text('Examiner Summary:', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(_comparisonResult['summary'] ?? '', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      onPressed: () {
                        setState(() {
                          _textController.clear();
                          _draft2Controller.clear();
                          _examinerFeedback = null;
                          _comparisonResult = null;
                          _selectedSentence = null;
                        });
                      },
                      child: const Text('Start New Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
      ),
    );
  }

  // --- SCREEN: WRITING RESULTS (Matches Speaking Part Results Screenshots) ---
  Widget _buildWritingResultsScreen() {
    final results = _writingResults ?? {};
    final double overallBand = (results['overallBand'] as num?)?.toDouble() ?? 1.0;
    final bool isTask1 = _currentPart == 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          isTask1 ? 'Task 1 Results' : 'Task 2 Results',
          style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _viewState = 'BOOK_DETAIL';
                    _textController.clear();
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildBandScoreGauge(overallBand),
            const SizedBox(height: 16),
            Text(
              isTask1 ? 'Task 1 Score' : 'Task 2 Score',
              style: const TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            _buildCriterionCard(
              dotColorHex: 'blue',
              title: isTask1 ? 'Task Achievement' : 'Task Response',
              score: (results['taskAchievement']?['score'] as num?)?.toInt() ?? 1,
              feedbackText: results['taskAchievement']?['feedback'] ?? '',
            ),
            _buildCriterionCard(
              dotColorHex: 'purple',
              title: 'Coherence & Cohesion',
              score: (results['coherenceCohesion']?['score'] as num?)?.toInt() ?? 1,
              feedbackText: results['coherenceCohesion']?['feedback'] ?? '',
            ),
            _buildCriterionCard(
              dotColorHex: 'orange',
              title: 'Lexical Resource',
              score: (results['lexicalResource']?['score'] as num?)?.toInt() ?? 1,
              feedbackText: results['lexicalResource']?['feedback'] ?? '',
            ),
            _buildCriterionCard(
              dotColorHex: 'green',
              title: 'Grammatical Range',
              score: (results['grammaticalRange']?['score'] as num?)?.toInt() ?? 1,
              feedbackText: results['grammaticalRange']?['feedback'] ?? '',
            ),
            const SizedBox(height: 10),
            _buildWritingImprovementTipsSection(results),
            _buildWritingYourMistakesSection(results),
            _buildWritingYourResponsesSection(results),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBandScoreGauge(double band) {
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: CircularProgressIndicator(
              value: (band / 9.0).clamp(0.1, 1.0),
              strokeWidth: 8,
              backgroundColor: AppColors.surfaceTint,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                band.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Band',
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionCard({
    required String dotColorHex,
    required String title,
    required int score,
    required String feedbackText,
  }) {
    Color dotColor = AppColors.primary;
    if (dotColorHex == 'purple') dotColor = const Color(0xFF0D9488); // Teal
    if (dotColorHex == 'orange') dotColor = AppColors.accent; // Coral
    if (dotColorHex == 'green') dotColor = const Color(0xFF059669); // Mint green

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimaryLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedbackText,
            style: const TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWritingImprovementTipsSection(Map<String, dynamic> results) {
    final List<String> tips = (results['tips'] as List?)?.map((e) => e.toString()).toList() ?? [];
    if (tips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            'Improvement Tips',
            style: TextStyle(
              color: AppColors.textPrimaryLight,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(tips.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tips[index],
                      style: const TextStyle(
                        color: AppColors.textPrimaryLight,
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWritingYourMistakesSection(Map<String, dynamic> results) {
    final List mistakes = (results['mistakes'] as List?) ?? [];
    if (mistakes.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Your Mistakes',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Legend row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('ab', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              const Text(
                'Wrong',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('ab', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              const Text(
                'Correct',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...mistakes.map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            final String qText = m['question'] ?? '';
            final String wrong = m['wrong'] ?? '';
            final String correct = m['correct'] ?? '';
            final List<String> correctWords = correct
                .split(RegExp(r'\s+'))
                .where((w) => w.isNotEmpty)
                .toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qText,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (wrong.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            wrong,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ...correctWords.map((word) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              word,
                              style: const TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWritingYourResponsesSection(Map<String, dynamic> results) {
    final List responses = (results['responses'] as List?) ?? [];
    if (responses.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            'Your Responses',
            style: TextStyle(
              color: AppColors.textPrimaryLight,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ...responses.map((item) {
            final r = Map<String, dynamic>.from(item as Map);
            final String qNum = r['questionNumber'] ?? (_currentPart == 1 ? 'Q1' : 'Q2');
            final String qTitle = r['questionText'] ?? '';
            final String ans = r['answer'] ?? '';
            final int words = r['wordCount'] ?? ans.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            qNum,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$qNum: $qTitle',
                            style: const TextStyle(
                              color: AppColors.textPrimaryLight,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ans.isEmpty ? 'No response entered' : ans,
                      style: TextStyle(
                        color: ans.isEmpty ? AppColors.textSecondaryLight : AppColors.textPrimaryLight,
                        fontSize: 13.5,
                        fontStyle: ans.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$words words',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String score) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(score, style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTackleStep(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 9, height: 1.4),
        ),
      ],
    );
  }
}
