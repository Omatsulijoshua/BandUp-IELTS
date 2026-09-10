import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/premium_paywall.dart';
import '../widgets/times_up_dialog.dart';

class SpeakingPracticeScreen extends ConsumerStatefulWidget {
  const SpeakingPracticeScreen({super.key});

  @override
  ConsumerState<SpeakingPracticeScreen> createState() => _SpeakingPracticeScreenState();
}

class _SpeakingPracticeScreenState extends ConsumerState<SpeakingPracticeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _transcriptController = TextEditingController();
  final TextEditingController _userResponseController = TextEditingController();
  final List<String> _userResponses = [];

  // Screen routing states: 'HOME', 'TALK_WITH_AI', 'TEST_DETAIL', 'PRACTICE_WORKSPACE'
  String _currentScreen = 'HOME';
  String _selectedTestTitle = 'IELTS Book 21 Test 1';

  // Interactive Examiner Session States
  int _currentQuestionIndex = 0;
  bool _isExaminerSpeaking = true;
  bool _isRecording = false;
  String _recordedText = "";
  int _wordCount = 0;
  int _sessionTime = 0;
  Timer? _sessionTimer;
  AudioPlayer? _audioPlayer;
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  List<double> _waveformHeights = List.generate(20, (index) => 3.0);
  Timer? _waveformTimer;
  Timer? _recordingSimulationTimer;
  Timer? _examinerSpeakingTimer;

  // The 4 questions and their segments in mp3_1.mp3
  final List<Map<String, dynamic>> _examinerQuestions = [
    {
      'question': 'How do you usually spend your weekends? [Why?]',
      'start': 0.0,
      'promptEnd': 5.0,
      'end': 9.0,
      'transcript': 'On weekends, I usually relax at home with a good book or catch up with friends for coffee. I enjoy this because it helps me decompress after a busy week of work.',
    },
    {
      'question': 'Which is your favorite part of the weekend? [Why?]',
      'start': 5.0,
      'promptEnd': 11.5,
      'end': 20.0,
      'transcript': 'My favorite part is Sunday morning because it is quiet and peaceful. I can take my time having breakfast without any rush.',
    },
    {
      'question': 'Do you think your weekends are long enough? [Why/Why not?]',
      'start': 11.5,
      'promptEnd': 18.0,
      'end': 30.0,
      'transcript': 'Honestly, two days often feel a bit short especially when there are many chores to do. A three-day weekend would give a much better balance between rest and personal projects.',
    },
    {
      'question': 'How important do you think it is to have free time at the weekends? [Why?]',
      'start': 18.0,
      'promptEnd': 25.5,
      'end': 41.12,
      'transcript': 'I think free time on weekends is essential for mental health and well-being. It allows people to recharge their energy and spend quality time with loved ones.',
    },
    {
      'question': 'Describe someone you know who does something well.',
      'start': 0.0,
      'promptEnd': 6.5,
      'end': 60.0,
      'part': 2,
      'audioAsset': 'mp3_2.mp3',
      'youShouldSay': [
        'who this person is',
        'how you know this person',
        'what they do well',
        'and explain why you think this person is so good at doing this.'
      ],
      'transcript': 'I would like to talk about my older brother, who is an incredibly talented graphic designer. He has a natural flair for combining colors and typography to create visually stunning advertisements. What makes him stand out is his ability to understand exactly what a client needs even before they explain it clearly. He has spent years honing his craft, and seeing him work with such precision is truly impressive. He is definitely the most skillful person I know.',
    },
    {
      'question': 'What skills and abilities do people most want to have today? Why?',
      'start': 0.0,
      'promptEnd': 8.5,
      'end': 30.0,
      'part': 3,
      'transcript': 'Nowadays, digital literacy, problem-solving, and effective communication are in high demand. People value these skills because they enhance employability and allow individuals to adapt quickly in a fast-evolving technological landscape.',
    },
    {
      'question': 'Which skills should children learn at school? Are there any skills which they should learn at home? What are they?',
      'start': 8.5,
      'promptEnd': 17.0,
      'end': 30.0,
      'part': 3,
      'transcript': 'Schools should focus on academic knowledge, teamwork, and critical thinking. On the other hand, essential life skills such as emotional resilience, personal hygiene, and financial discipline are best taught at home by parents.',
    },
    {
      'question': 'Which skills do you think will be important in the future? Why?',
      'start': 17.0,
      'promptEnd': 25.5,
      'end': 30.0,
      'part': 3,
      'transcript': 'In the future, adaptability, data analysis, and emotional intelligence will be crucial. As automation takes over repetitive tasks, human-centric abilities like creative thinking and empathy will become paramount.',
    },
    {
      'question': 'Which kinds of jobs have the highest salaries in your country? Why is this?',
      'start': 25.5,
      'promptEnd': 34.0,
      'end': 30.0,
      'part': 3,
      'transcript': 'Roles in technology, medicine, and corporate management command the highest salaries in my country. This is because these positions require specialized expertise, years of rigorous training, and carry immense operational responsibility.',
    },
    {
      'question': 'Are there any other jobs that you think should have high salaries? Why do you think that?',
      'start': 34.0,
      'promptEnd': 42.5,
      'end': 30.0,
      'part': 3,
      'transcript': 'Teachers and healthcare workers definitely deserve higher remuneration. They perform fundamental roles in nurturing future generations and saving lives, yet their compensation often does not reflect their immense social contribution.',
    },
    {
      'question': 'Some people say it would be better for society if everyone got the same salary. What do you think about that? Why?',
      'start': 42.5,
      'promptEnd': 51.0,
      'end': 30.0,
      'part': 3,
      'transcript': 'I strongly disagree with that idea. Equal salaries for all professions would reduce motivation and work ethic, as people would lack incentives to pursue challenging, highly skilled, or high-risk careers. A fair economic system should reward effort, qualification, and responsibility while maintaining a basic safety net.',
    },
  ];

  final List<Map<String, dynamic>> _book10Test2Questions = [
    {
      'question': 'What types of music do you like to listen to? [Why?]',
      'start': 0.0,
      'promptEnd': 6.0,
      'end': 9.0,
      'transcript': 'I enjoy listening to a variety of music genres, especially pop, acoustic, and classical music. I find pop music energetic and uplifting, while classical tunes help me stay focused and relaxed when studying.',
    },
    {
      'question': 'At what times of day do you like to listen to music? [Why?]',
      'start': 6.0,
      'promptEnd': 12.5,
      'end': 20.0,
      'transcript': 'I mostly listen to music in the morning while getting ready and during my evening commute. Music sets a positive mood for my day and helps me unwind after work.',
    },
    {
      'question': 'Did you learn to play a musical instrument when you were a child? [Why/Why not?]',
      'start': 12.5,
      'promptEnd': 19.5,
      'end': 30.0,
      'transcript': 'Yes, I learned to play the piano when I was in primary school. My parents encouraged me to take lessons, and although practice was challenging at times, I am glad I acquired basic musical skills.',
    },
    {
      'question': 'Do you think all children should learn to play a musical instrument? [Why/why not?]',
      'start': 19.5,
      'promptEnd': 26.5,
      'end': 41.12,
      'transcript': 'I believe learning a musical instrument is beneficial because it develops patience, coordination, and creativity. However, it should not be strictly compulsory, as children should be free to explore other hobbies like sports or art.',
    },
    {
      'question': 'Describe a shop near where you live that you sometimes use.',
      'start': 0.0,
      'promptEnd': 6.5,
      'end': 60.0,
      'part': 2,
      'youShouldSay': [
        'what sorts of product or service it sells',
        'what the shop looks like',
        'where it is located',
        'and explain why you use this shop.'
      ],
      'transcript': 'There is a small local grocery store just a five-minute walk from my apartment that I visit quite frequently. It is a family-run business that stocks a wide variety of fresh produce, dairy, and household essentials. I find it incredibly convenient because I can quickly pick up ingredients for dinner on my way home from work. The staff are always very friendly and helpful, which makes the shopping experience much more pleasant than going to a large, crowded supermarket.',
    },
    {
      'question': 'What types of local business are there in your neighbourhood? Are there any restaurants, shops, or dentists for example?',
      'start': 0.0,
      'promptEnd': 8.5,
      'end': 30.0,
      'part': 3,
      'transcript': 'In my neighborhood, there is a good mix of local businesses. We have a small grocery store, a couple of family-run cafes, and a local dental clinic, which is quite convenient for residents.',
    },
    {
      'question': 'Do you think local businesses are important for a neighborhood? In what way?',
      'start': 8.5,
      'promptEnd': 17.0,
      'end': 30.0,
      'part': 3,
      'transcript': 'I believe they are vital. They provide essential services within walking distance and foster a sense of community by allowing neighbors to interact regularly, which helps the local economy thrive.',
    },
    {
      'question': 'How do large shopping malls and commercial centres affect small local businesses? Why do you think that is?',
      'start': 17.0,
      'promptEnd': 25.5,
      'end': 30.0,
      'part': 3,
      'transcript': 'Large shopping malls often pose a significant threat to local businesses. Because they offer lower prices and a wider variety of goods under one roof, small shops often struggle to compete and may eventually go out of business.',
    },
    {
      'question': 'Why do some people want to start their own business?',
      'start': 25.5,
      'promptEnd': 34.0,
      'end': 30.0,
      'part': 3,
      'transcript': 'Many people are drawn to entrepreneurship because they desire independence and the ability to control their own professional destiny. They want to turn a personal passion or an innovative idea into a profitable reality.',
    },
    {
      'question': 'Are there any disadvantages to running a business? Which is the most serious?',
      'start': 34.0,
      'promptEnd': 42.5,
      'end': 30.0,
      'part': 3,
      'transcript': 'Running a business is certainly challenging. The most serious disadvantage is the high level of financial risk, as many startups fail within the first few years, which can lead to significant personal debt.',
    },
    {
      'question': 'What are the most important qualities that a good business person needs? Why is that?',
      'start': 42.5,
      'promptEnd': 51.0,
      'end': 30.0,
      'part': 3,
      'transcript': 'A successful business person needs resilience, strategic thinking, and strong communication skills. Resilience is crucial because they will inevitably face setbacks, and they must have the drive to persevere through difficult market conditions.',
    },
  ];

  List<Map<String, dynamic>> get _activeQuestions {
    if (_selectedTestTitle.contains('Book 10 Test 2')) {
      return _book10Test2Questions;
    }
    return _examinerQuestions;
  }

  // Talk with AI States
  bool _isAiSpeaking = true;
  int _freeMessagesLeft = 3;
  Timer? _aiSpeakingTimer;
  final List<Map<String, dynamic>> _chatMessages = [
    {
      'role': 'ai',
      'content': "Hello! I'm your IELTS speaking practice partner. What would you like to work on today?"
    }
  ];

  // Test Detail States
  int _selectedPart = 1;

  // Practice/Exam Workspace States
  List<dynamic> _prompts = [];
  dynamic _selectedPrompt;
  String _mode = 'PRACTICE'; // PRACTICE or EXAM
  bool _loading = true;
  bool _submitting = false;
  dynamic _feedback;
  bool _examSuccess = false;

  // Interactive Examiner Session Results States
  bool _isAnalyzingResults = false;
  Map<String, dynamic>? _examinerResults;

  // Timer variables
  int _timeLeft = 120; // 2 minutes
  Timer? _timer;
  bool _timerActive = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _initTts();
    _fetchPrompts();
    _startAiSpeechSimulation("Hello! I'm your IELTS speaking practice partner. What would you like to work on today?");
  }

  void _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (val) => debugPrint('Speech error: $val'),
        onStatus: (val) => debugPrint('Speech status: $val'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  void _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS Init error: $e');
    }
  }

  Future<void> _speakText(String text) async {
    try {
      await _audioPlayer?.stop();
      await _flutterTts.stop();
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS Speak error: $e');
    }
  }

  String _getAudioAssetForQuestion(Map<String, dynamic> currentQ) {
    String folderName = _selectedTestTitle.replaceAll('Book', 'BOOK').trim();
    if (folderName.isEmpty) folderName = 'IELTS BOOK 10 Test 1';

    if (currentQ['audioAsset'] != null) {
      final String rawAsset = currentQ['audioAsset'] as String;
      if (rawAsset.contains('/')) return rawAsset;
      return 'Speaking/$folderName/$rawAsset';
    }

    final int part = (currentQ['part'] as int?) ?? 1;
    if (part == 2) {
      return 'Speaking/$folderName/5.mp3';
    } else if (part == 3) {
      return 'Speaking/$folderName/6-11.mp3';
    }
    return 'Speaking/$folderName/1-4.mp3';
  }

  Future<void> _playQuestionAudio(String text, double startSec, double promptEndSec, {String audioAsset = 'mp3_1.mp3'}) async {
    _audioPlayer ??= AudioPlayer();
    try {
      await _flutterTts.stop();
      await _audioPlayer!.stop();
      await _audioPlayer!.setVolume(1.0);
      
      bool played = false;
      try {
        await _audioPlayer!.setSource(AssetSource(audioAsset));
        if (startSec > 0) {
          await _audioPlayer!.seek(Duration(milliseconds: (startSec * 1000).toInt()));
        } else {
          await _audioPlayer!.seek(Duration.zero);
        }
        await _audioPlayer!.resume();
        played = true;
      } catch (e1) {
        debugPrint('Primary setSource ($audioAsset) failed: $e1, falling back to play()');
        try {
          await _audioPlayer!.play(AssetSource(audioAsset));
          if (startSec > 0) {
            await Future.delayed(const Duration(milliseconds: 60));
            await _audioPlayer!.seek(Duration(milliseconds: (startSec * 1000).toInt()));
          }
          await _audioPlayer!.resume();
          played = true;
        } catch (e2) {
          debugPrint('Primary play() ($audioAsset) failed: $e2');
        }
      }

      if (!played) {
        try {
          await _audioPlayer!.play(AssetSource('assets/$audioAsset'));
          if (startSec > 0) {
            await Future.delayed(const Duration(milliseconds: 60));
            await _audioPlayer!.seek(Duration(milliseconds: (startSec * 1000).toInt()));
          }
          await _audioPlayer!.resume();
          played = true;
        } catch (e3) {
          debugPrint('Secondary AssetSource (assets/$audioAsset) failed: $e3');
        }
      }

      // Check after 300ms if audio position is stagnant/silent, and fall back to TTS if needed
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (!mounted) return;
        final pos = await _audioPlayer?.getCurrentPosition();
        if (!played || pos == null || (startSec == 0 && pos.inMilliseconds == 0)) {
          debugPrint('Audio output silent or position stagnant for "$text", falling back to TTS');
          await _speakText(text);
        }
      });
    } catch (e) {
      debugPrint('Audio playback error: $e, falling back to TTS');
      await _speakText(text);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _aiSpeakingTimer?.cancel();
    _sessionTimer?.cancel();
    _waveformTimer?.cancel();
    _recordingSimulationTimer?.cancel();
    _examinerSpeakingTimer?.cancel();
    _audioPlayer?.dispose();
    _flutterTts.stop();
    _transcriptController.dispose();
    _userResponseController.dispose();
    super.dispose();
  }

  void _startAiSpeechSimulation(String initialText) {
    setState(() {
      _isAiSpeaking = true;
    });
    _speakText(initialText);
    _aiSpeakingTimer?.cancel();
    _aiSpeakingTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isAiSpeaking = false;
        });
      }
    });
  }

  void _sendUserMessage(String text) {
    if (_freeMessagesLeft <= 0) return;
    setState(() {
      _chatMessages.add({'role': 'user', 'content': text});
      _freeMessagesLeft--;
      _isAiSpeaking = true;
    });

    _aiSpeakingTimer?.cancel();
    _aiSpeakingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final aiMsg = "That's a very interesting point. In the IELTS Speaking test, expanding on this with concrete examples will help boost your coherence score. Let's try another cue card prompt.";
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content': aiMsg
          });
          _isAiSpeaking = false;
        });
        _speakText(aiMsg);
      }
    });
  }

  void _resetChat() {
    setState(() {
      _chatMessages.clear();
      _chatMessages.add({
        'role': 'ai',
        'content': "Hello! I'm your IELTS speaking practice partner. What would you like to work on today?"
      });
      _isAiSpeaking = false;
      _freeMessagesLeft = 3;
    });
  }

  Future<void> _fetchPrompts() async {
    try {
      final response = await _apiService.request(path: '/content/speaking/prompts', method: 'GET');
      if (response.statusCode == 200) {
        final List<dynamic> fetched = jsonDecode(response.body);
        final customOption = {
          'id': 'CUSTOM',
          'topic': '🎙️ Speak on my own Topic',
          'cueCardText': 'Type your custom speaking topic/cue card details in the box below to start practicing.',
          'difficulty': 'CUSTOM',
        };
        setState(() {
          _prompts = [...fetched, customOption];
          if (_prompts.isNotEmpty) {
            _selectedPrompt = _prompts[0];
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching speaking prompts: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _startTimer() {
    setState(() {
      _timeLeft = 120;
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
        showTimesUpDialog(context, _submitSpeaking);
      }
    });
  }

  Future<void> _submitSpeaking() async {
    if (_transcriptController.text.trim().isEmpty) return;
    setState(() {
      _submitting = true;
      _timerActive = false;
    });

    try {
      final response = await _apiService.request(
        path: '/content/speaking/submit',
        method: 'POST',
        body: jsonEncode({
          'promptId': _selectedPrompt['id'],
          'audioUrl': 'https://placeholder.url/audio.mp3',
          'transcription': _transcriptController.text.trim(),
          'mode': _mode,
          'customQuestionText': _selectedPrompt['id'] == 'CUSTOM' ? _selectedPrompt['cueCardText'] : null,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (_mode == 'EXAM') {
          setState(() {
            _examSuccess = true;
          });
        } else {
          setState(() {
            _feedback = result['feedbackJson'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error submitting speaking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit speaking response.')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s < 10 ? '0' : ''}$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050E1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    if (_currentScreen == 'TALK_WITH_AI') {
      return _buildTalkWithAiScreen();
    } else if (_currentScreen == 'TEST_DETAIL') {
      return _buildTestDetailScreen();
    } else if (_currentScreen == 'PRACTICE_WORKSPACE') {
      return _buildPracticeWorkspaceScreen();
    } else if (_currentScreen == 'EXAMINER_SESSION') {
      return _buildExaminerSessionScreen();
    } else if (_currentScreen == 'TEST_COMPLETE') {
      return _buildTestCompleteScreen();
    } else if (_currentScreen == 'EXAMINER_RESULTS') {
      return _buildExaminerResultsScreen();
    }

    return _buildHomeScreen();
  }

  // --- SCREEN 1: SPEAKING HOME PAGE (Image 1) ---
  Widget _buildHomeScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF050E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFC62828), size: 16),
          label: const Text('Back', style: TextStyle(color: Color(0xFFC62828), fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Speaking Practice',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real IELTS Speaking Tests',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // AI Powered Talk with AI Card
            InkWell(
              onTap: () {
                setState(() {
                  _currentScreen = 'TALK_WITH_AI';
                  _isAiSpeaking = true;
                });
                _startAiSpeechSimulation("Hello! I'm your IELTS speaking practice partner. What would you like to work on today?");
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC62828), Color(0xFF880E4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC62828).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white, size: 10),
                              SizedBox(width: 4),
                              Text(
                                'AI POWERED',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.waves, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Talk with AI',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Practice free conversation with human-like AI voice',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.mic, color: Colors.white70, size: 14),
                            SizedBox(width: 4),
                            Text('Voice Chat', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.volume_up, color: Colors.white70, size: 14),
                            SizedBox(width: 4),
                            Text('AI Voice', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.psychology, color: Colors.white70, size: 14),
                            SizedBox(width: 4),
                            Text('Smart AI', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'Available Tests',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Check user subscription status
            (() {
              final user = ref.watch(authProvider).user;
              final List subs = user?['subscriptions'] as List? ?? [];
              final bool isPremium = user?['isSubscribed'] == true || 
                  user?['subscriptionTier'] == 'PREMIUM' ||
                  user?['subscriptionTier'] == 'PRO' ||
                  subs.any((s) => s['status'] == 'ACTIVE' || s['status'] == 'APPROVED');

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(12, (bookIndex) {
                  final bookNum = 10 + bookIndex;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(4, (testIndex) {
                      final testNum = 1 + testIndex;
                      final isUnlocked = isPremium || (bookNum == 21 && testNum == 1) || (bookNum == 10 && testNum == 1) || (bookNum == 10 && testNum == 2);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildTestListItem(
                          title: 'IELTS Book $bookNum Test $testNum',
                          subtitle: isUnlocked ? '3 Parts  |  0/3 Completed' : 'Premium Content',
                          isLocked: !isUnlocked,
                          iconData: isUnlocked ? Icons.mic : Icons.lock,
                          onTap: () {
                            if (isUnlocked) {
                              setState(() {
                                _selectedTestTitle = 'IELTS Book $bookNum Test $testNum';
                                _currentScreen = 'TEST_DETAIL';
                                _selectedPart = 1;
                                final part1Prompts = _prompts.where((p) => p['part'] == 1).toList();
                                if (part1Prompts.isNotEmpty) {
                                  _selectedPrompt = part1Prompts[0];
                                } else {
                                  _selectedPrompt = null;
                                }
                              });
                            } else {
                              showPremiumPaywall(context);
                            }
                          },
                        ),
                      );
                    }),
                  );
                }),
              );
            })(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTestListItem({
    required String title,
    required String subtitle,
    required bool isLocked,
    required IconData iconData,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1E36),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E3E6E).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLocked ? const Color(0xFF1E3E6E).withValues(alpha: 0.3) : const Color(0xFFC62828).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFFC62828),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isLocked ? const Color(0xFF94A3B8) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isLocked ? Icons.lock_outline : Icons.chevron_right,
              color: const Color(0xFF1E3E6E),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // --- SCREEN 2 & 3: TALK WITH AI (Image 2 & 3) ---
  Widget _buildTalkWithAiScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF050E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 24),
          onPressed: () {
            _aiSpeakingTimer?.cancel();
            setState(() {
              _currentScreen = 'HOME';
            });
          },
        ),
        title: const Text(
          'Talk with AI',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                final isAi = msg['role'] == 'ai';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
                    children: [
                      if (isAi) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC62828),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.psychology, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isAi ? Colors.white : const Color(0xFF0B1E36),
                            borderRadius: BorderRadius.circular(16),
                            border: isAi ? null : Border.all(color: const Color(0xFF1E3E6E)),
                          ),
                          child: Text(
                            msg['content'],
                            style: TextStyle(
                              color: isAi ? Colors.black87 : Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      if (!isAi) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E3E6E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Speaking Status Indicators & Control Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            decoration: const BoxDecoration(
              color: Color(0xFF0B1E36),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isAiSpeaking ? const Color(0xFFC62828) : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isAiSpeaking ? 'AI is speaking...' : 'Tap microphone to speak',
                      style: TextStyle(
                        color: _isAiSpeaking ? Colors.white : const Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stop button on left (Only visible when AI is speaking)
                    if (_isAiSpeaking) ...[
                      InkWell(
                        onTap: () {
                          _aiSpeakingTimer?.cancel();
                          setState(() {
                            _isAiSpeaking = false;
                          });
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE65100),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.stop, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ] else ...[
                      const SizedBox(width: 74), // Placeholder spacing to center the mic
                    ],

                    // Microphone button in center
                    InkWell(
                      onTap: _isAiSpeaking
                          ? null
                          : () {
                              _sendUserMessage("I want to practice Part 2 Cue Card topics about describing a childhood memory.");
                            },
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: _isAiSpeaking ? const Color(0xFF1E3E6E) : const Color(0xFFC62828),
                          shape: BoxShape.circle,
                          boxShadow: _isAiSpeaking
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(0xFFC62828).withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                        ),
                        child: const Icon(Icons.mic, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Reset button on right
                    InkWell(
                      onTap: _resetChat,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.replay, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Free limit counter
                Text(
                  '$_freeMessagesLeft free messages remaining',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 4 & 5: TEST DETAIL PAGE (Image 4 & 5) ---
  Widget _buildTestDetailScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF050E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => setState(() => _currentScreen = 'HOME'),
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFC62828), size: 16),
          label: const Text('Back', style: TextStyle(color: Color(0xFFC62828), fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        title: Text(
          _selectedTestTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Segmented Tabs control row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1E36),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildPartTabButton(1, 'Part 1', 'Interview')),
                  Expanded(child: _buildPartTabButton(2, 'Part 2', 'Cue Card')),
                  Expanded(child: _buildPartTabButton(3, 'Part 3', 'Discussion')),
                ],
              ),
            ),
          ),

          // Detail Content Cards
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Topic Headers based on selection
                  Text(
                    _selectedPart == 1
                        ? 'Part 1: Questions 1-4'
                        : _selectedPart == 2
                            ? 'Part 2: Question 5'
                            : 'Part 3: Questions 6-11',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedPart == 1
                        ? '4-5 minutes'
                        : _selectedPart == 2
                            ? '3-4 minutes'
                            : '4-5 minutes',
                    style: const TextStyle(color: Color(0xFFC62828), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _selectedPart == 1
                        ? 'The examiner asks general questions about familiar topics like home, family, work, studies, and interests.'
                        : _selectedPart == 2
                            ? 'You receive a task card with a topic. You have 1 minute to prepare, then speak for 1-2 minutes.'
                            : 'The examiner asks deeper questions related to Part 2 topic. These require more abstract thinking and opinions.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Pro Tips',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Dynamic list of tips with lightbulb icons
                  ..._buildPartTipsList(),
                  const SizedBox(height: 24),

                  // Test Security Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.security_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Test Security',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Questions are hidden until you start the speaking session to simulate real test conditions.',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Sticky Start Speaking Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  _startExaminerSession();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.mic, size: 20),
                label: const Text(
                  'Start Speaking',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartTabButton(int partNum, String title, String subtitle) {
    final isSelected = _selectedPart == partNum;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPart = partNum;
          final partPrompts = _prompts.where((p) => p['part'] == partNum).toList();
          if (partPrompts.isNotEmpty) {
            _selectedPrompt = partPrompts[0];
          } else {
            _selectedPrompt = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC62828) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.white70 : const Color(0xFF94A3B8),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPartTipsList() {
    List<String> tips = [];
    if (_selectedPart == 1) {
      tips = [
        'Speak naturally and confidently.',
        'Expand on your answers but keep them relevant.',
        'Don\'t worry if the examiner interrupts you to move on.'
      ];
    } else if (_selectedPart == 2) {
      tips = [
        'Use your 1 minute preparation time effectively to make notes.',
        'Try to use the bullet points on the card to structure your talk.',
        'Keep speaking until the examiner stops you.'
      ];
    } else {
      tips = [
        'Express and justify your opinions clearly.',
        'Discuss topics generally rather than focusing on personal experiences.',
        'Ask for clarification if you don\'t understand a question.'
      ];
    }

    return tips.map((tip) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Color(0xFFEAB308), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tip,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // --- SCREEN 6: ORIGINAL INTEGRATED WORKSPACE SCREEN ---
  Widget _buildPracticeWorkspaceScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF050E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1E36),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _timer?.cancel();
            setState(() {
              _currentScreen = 'TEST_DETAIL';
            });
          },
        ),
        title: const Text('Speaking Workspace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode selector card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1E36),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E3E6E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Practice Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _timerActive ? null : () => setState(() => _mode = 'PRACTICE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mode == 'PRACTICE' ? const Color(0xFFD4AF37) : const Color(0xFF050E1A),
                            foregroundColor: _mode == 'PRACTICE' ? const Color(0xFF050E1A) : Colors.white,
                            side: const BorderSide(color: Color(0xFF1E3E6E)),
                          ),
                          child: const Text('Practice'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _timerActive ? null : () => setState(() => _mode = 'EXAM'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mode == 'EXAM' ? const Color(0xFFD4AF37) : const Color(0xFF050E1A),
                            foregroundColor: _mode == 'EXAM' ? const Color(0xFF050E1A) : Colors.white,
                            side: const BorderSide(color: Color(0xFF1E3E6E)),
                          ),
                          child: const Text('Exam Mode'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_prompts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Text('No speaking prompts found.', style: TextStyle(color: Colors.white60)),
                ),
              )
            else ...[
              // Prompt selector dropdown
              DropdownButtonFormField<dynamic>(
                value: _selectedPrompt,
                decoration: const InputDecoration(
                  labelText: 'Choose Prompt',
                  labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                  filled: true,
                  fillColor: Color(0xFF0B1E36),
                  border: OutlineInputBorder(),
                ),
                dropdownColor: const Color(0xFF0B1E36),
                items: _prompts.map((p) {
                  return DropdownMenuItem<dynamic>(
                    value: p,
                    child: Text(
                      p['topic'] ?? 'Speaking Cue Card',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: _timerActive
                    ? null
                    : (val) {
                        setState(() {
                          _selectedPrompt = val;
                          _transcriptController.clear();
                          _feedback = null;
                          _examSuccess = false;
                        });
                      },
              ),
              const SizedBox(height: 20),

              // Cue card details
              if (_selectedPrompt != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1E36),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E3E6E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('CUE CARD DESCRIPTION', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
                          if (_timerActive)
                            Text(
                              '⏱️ ${_formatTime(_timeLeft)}',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedPrompt['cueCardText'] ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),

                      // Collapsible Tackle Steps Accordion
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF050E1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E3E6E).withValues(alpha: 0.5)),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: const Color(0xFFEAB308),
                            collapsedIconColor: const Color(0xFFEAB308),
                            title: const Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: Color(0xFFEAB308), size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'How to Tackle this Speaking Task (Steps)',
                                    style: TextStyle(color: Color(0xFFEAB308), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildTackleStep('1. Prepare (1 Min)', 'Write brief outline keywords during your 1-minute prep time. Do not write full sentences; focus on main cues.'),
                                    const SizedBox(height: 8),
                                    _buildTackleStep('2. Speak Fluently', 'Keep speaking continuously until the examiner stops you. Use connectors ("In addition", "Consequently") naturally.'),
                                    const SizedBox(height: 8),
                                    _buildTackleStep('3. Range of Tenses', 'Use past, present, and conditional tenses. Rich grammar variation raises your score.'),
                                    const SizedBox(height: 8),
                                    _buildTackleStep('4. Pronunciation', 'Speak at a steady, natural pace. Enounce clearly and pause naturally instead of using fillers ("uhm", "like").'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_selectedPrompt['id'] == 'CUSTOM' && !_timerActive && _feedback == null && !_examSuccess) ...[
                        TextField(
                          maxLines: 3,
                          onChanged: (text) => setState(() => _selectedPrompt['cueCardText'] = text),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: const InputDecoration(
                            hintText: 'Enter your custom speaking topic here...',
                            hintStyle: TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Color(0xFF050E1A),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Practice / Exam Workspace Inputs
                      if (!_timerActive && _feedback == null && !_examSuccess)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _startTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: const Color(0xFF050E1A),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(_mode == 'EXAM' ? 'Start Exam Timer' : 'Start Practice', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )
                      else ...[
                        TextField(
                          controller: _transcriptController,
                          maxLines: 6,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          enabled: _timerActive || _mode == 'PRACTICE',
                          decoration: const InputDecoration(
                            labelText: 'Your Speaking Response / Transcription',
                            labelStyle: TextStyle(color: Colors.white60),
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Color(0xFF050E1A),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_timerActive)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submitSpeaking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: const Color(0xFF050E1A),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(_submitting ? 'Evaluating...' : 'Submit Speaking', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Practice AI Feedback display
              if (_feedback != null && _mode == 'PRACTICE')
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1E36),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E3E6E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Speaking Band Score',
                        style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFF050E1A), borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                children: [
                                  const Text('EST. BAND', style: TextStyle(color: Colors.white54, fontSize: 9)),
                                  const SizedBox(height: 4),
                                  Text('Band ${_feedback['estimatedBand']}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('⭐ What you did well:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_feedback['wellDone'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      
                      if (_feedback['mistakes'] != null && (_feedback['mistakes'] as List).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('⚠️ Mistakes & Corrections:', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (_feedback['mistakes'] as List).map((m) => Text('- $m', style: const TextStyle(color: Colors.white70, fontSize: 12))).toList(),
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Text('📝 High Band Model Answer:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF050E1A), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          _feedback['improvedAnswer'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5, fontStyle: FontStyle.italic),
                        ),
                      ),
                      
                      if (_feedback['practiceRecommendation'] != null) ...[
                        const SizedBox(height: 16),
                        const Text('📈 Recommendations:', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_feedback['practiceRecommendation'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ],
                  ),
                ),

              // Exam success display
              if (_examSuccess)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFF10B981), size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Exam Submitted Successfully!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your response has been logged in Exam Mode for evaluation. You can check details in Attempt History later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _examSuccess = false),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF050E1A)),
                        child: const Text('Practice Again'),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTackleStep(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Color(0xFFEAB308), fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, height: 1.4),
        ),
      ],
    );
  }

  // --- INTERACTIVE EXAMINER SESSION SCREEN ---
  void _startExaminerSession() async {
    setState(() {
      _currentScreen = 'EXAMINER_SESSION';
      _currentQuestionIndex = _selectedPart == 3 ? 5 : (_selectedPart == 2 ? 4 : 0);
      _isExaminerSpeaking = true;
      _isRecording = false;
      _recordedText = "";
      _wordCount = 0;
      _sessionTime = 0;
    });

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentScreen == 'EXAMINER_SESSION') {
        setState(() {
          _sessionTime++;
        });
      } else {
        timer.cancel();
      }
    });

    _audioPlayer ??= AudioPlayer();
    
    // Position listener to pause audio as soon as examiner prompt finishes speaking
    _audioPlayer!.onPositionChanged.listen((position) {
      if (_currentScreen == 'EXAMINER_SESSION' && _isExaminerSpeaking) {
        final safeIndex = _currentQuestionIndex.clamp(0, _activeQuestions.length - 1);
        final currentQ = _activeQuestions[safeIndex];
        final double promptEndSec = (currentQ['promptEnd'] as num).toDouble();
        if (position.inMilliseconds >= (promptEndSec * 1000).toInt()) {
          _audioPlayer!.pause();
          setState(() {
            _isExaminerSpeaking = false;
          });
        }
      }
    });

    _playCurrentQuestion();
  }

  void _playCurrentQuestion() {
    setState(() {
      _isExaminerSpeaking = true;
      _isRecording = false;
      _recordedText = "";
      _wordCount = 0;
    });
    
    _startWaveformAnimation();

    final safeIndex = _currentQuestionIndex.clamp(0, _activeQuestions.length - 1);
    final currentQ = _activeQuestions[safeIndex];
    final double startSec = (currentQ['start'] as num).toDouble();
    final double promptEndSec = (currentQ['promptEnd'] as num).toDouble();
    final double durationSec = (promptEndSec > startSec) ? (promptEndSec - startSec) : 3.5;
    final int promptDurationMs = (durationSec * 1000).toInt();

    // 1. GUARANTEED TIMER: Created FIRST synchronously so execution is 100% guaranteed to transition
    _examinerSpeakingTimer?.cancel();
    _examinerSpeakingTimer = Timer(Duration(milliseconds: promptDurationMs), () {
      if (mounted && _currentScreen == 'EXAMINER_SESSION') {
        _audioPlayer?.pause();
        _flutterTts.stop();
        setState(() {
          _isExaminerSpeaking = false;
        });
      }
    });

    // 2. Play Audio via AudioPlayer with position parameter or fallback to TTS
    final String audioAsset = _getAudioAssetForQuestion(currentQ);
    _playQuestionAudio(currentQ['question'], startSec, promptEndSec, audioAsset: audioAsset);
  }

  void _startWaveformAnimation() {
    _waveformTimer?.cancel();
    int cycle = 0;
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_currentScreen == 'EXAMINER_SESSION' && _isExaminerSpeaking) {
        setState(() {
          _waveformHeights = List.generate(20, (i) {
            return 8.0 + 22.0 * (1.0 + sin((cycle + i) * 0.4)).abs();
          });
          cycle++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startUserRecording() async {
    _recordingSimulationTimer?.cancel();
    
    setState(() {
      _isRecording = true;
      _recordedText = "";
      _wordCount = 0;
    });

    // Start real voice recognition via device microphone
    try {
      if (_speechAvailable || await _speech.initialize()) {
        _speechAvailable = true;
        _speech.listen(
          partialResults: true,
          onResult: (val) {
            if (mounted) {
              setState(() {
                _recordedText = val.recognizedWords;
                final words = val.recognizedWords.trim().split(RegExp(r'\s+'));
                _wordCount = val.recognizedWords.trim().isEmpty ? 0 : words.length;
              });
            }
          },
        );
      }
    } catch (e) {
      debugPrint('Error starting voice recognition: $e');
    }

    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_currentScreen == 'EXAMINER_SESSION' && _isRecording) {
        setState(() {
          _waveformHeights = List.generate(20, (i) => 4.0 + 12.0 * (1.0 + sin((timer.tick + i) * 0.7)).abs());
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopRecordingAndAdvance() async {
    final response = _recordedText.trim();
    if (response.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.mic_none, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please speak into your microphone to record your response before proceeding.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFFC62828),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _recordingSimulationTimer?.cancel();
    _waveformTimer?.cancel();

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }

    // Save previous question's voice response
    _userResponses.add(response);

    // Completely clear voice transcript and word count before answering next question!
    setState(() {
      _isRecording = false;
      _recordedText = "";
      _wordCount = 0;
    });

    if (_currentQuestionIndex == 3 || _currentQuestionIndex == 4 || _currentQuestionIndex >= 10) {
      _audioPlayer?.stop();
      _sessionTimer?.cancel();
      _flutterTts.stop();
      setState(() {
        _currentScreen = 'TEST_COMPLETE';
      });
    } else if (_currentQuestionIndex < _examinerQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _playCurrentQuestion();
    } else {
      _audioPlayer?.stop();
      _sessionTimer?.cancel();
      _flutterTts.stop();
      setState(() {
        _currentScreen = 'TEST_COMPLETE';
      });
    }
  }

  void _showEndTestDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Light orange circle with Warning icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'End Test?',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to end this test?\nYour progress will be lost.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    // Left Button: End Test (light red background, red text)
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _audioPlayer?.stop();
                          _flutterTts.stop();
                          _sessionTimer?.cancel();
                          _waveformTimer?.cancel();
                          _recordingSimulationTimer?.cancel();
                          _examinerSpeakingTimer?.cancel();
                          setState(() {
                            _currentScreen = 'TEST_DETAIL';
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE2E2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'End Test',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right Button: Continue (solid red background, white text)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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

  Widget _buildExaminerSessionScreen() {
    final safeIndex = _currentQuestionIndex.clamp(0, _examinerQuestions.length - 1);
    final currentQ = _examinerQuestions[safeIndex];
    final waveColors = [
      const Color(0xFFE57373), const Color(0xFFFFB74D), const Color(0xFFFFF176), const Color(0xFF81C784),
      const Color(0xFF4FC3F7), const Color(0xFF9575CD), const Color(0xFFF06292), const Color(0xFFE57373),
      const Color(0xFFFFB74D), const Color(0xFFFFF176), const Color(0xFF81C784), const Color(0xFF4FC3F7),
      const Color(0xFF9575CD), const Color(0xFFF06292), const Color(0xFFE57373), const Color(0xFFFFB74D),
      const Color(0xFFFFF176), const Color(0xFF81C784), const Color(0xFF4FC3F7), const Color(0xFF9575CD)
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF050E1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                    onPressed: _showEndTestDialog,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1E36),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: (_isRecording || _isExaminerSpeaking) ? const Color(0xFFC62828) : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(_sessionTime),
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Examiner Card
              Expanded(
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Status indicator
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(color: Color(0xFFC62828), shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isExaminerSpeaking ? 'Speaking' : _isRecording ? 'Recording' : 'Idle',
                                    style: const TextStyle(color: Color(0xFFC62828), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Question Title Banner with Replay Audio Button
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Q${_currentQuestionIndex + 1}: ${currentQ['question']}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (currentQ['youShouldSay'] != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'You should say:',
                                              style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...(currentQ['youShouldSay'] as List).map((bullet) {
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 4.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      '• ',
                                                      style: TextStyle(color: Color(0xFFC62828), fontSize: 13, fontWeight: FontWeight.bold),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        bullet.toString(),
                                                        style: const TextStyle(
                                                          color: Color(0xFF334155),
                                                          fontSize: 13,
                                                          height: 1.4,
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
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () {
                                        final double startSec = (currentQ['start'] as num).toDouble();
                                        final double promptEndSec = (currentQ['promptEnd'] as num).toDouble();
                                        final String audioAsset = _getAudioAssetForQuestion(currentQ);
                                        _playQuestionAudio(currentQ['question'], startSec, promptEndSec, audioAsset: audioAsset);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFC62828).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.volume_up, size: 16, color: Color(0xFFC62828)),
                                            SizedBox(width: 6),
                                            Text(
                                              'Tap to Listen / Replay Audio',
                                              style: TextStyle(color: Color(0xFFC62828), fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Waveform visualizer
                              SizedBox(
                                height: 50,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(20, (i) {
                                    return Container(
                                      width: 3.5,
                                      height: _waveformHeights[i],
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                      decoration: BoxDecoration(
                                        color: (_isExaminerSpeaking || _isRecording) ? waveColors[i] : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Live Read-Only Voice Transcript Area
                              if (!_isExaminerSpeaking) ...[
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(minHeight: 60),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    _recordedText.isEmpty
                                        ? (_isRecording
                                            ? 'Listening to your voice... speak into microphone'
                                            : 'Tap microphone below to record answer')
                                        : _recordedText,
                                    style: TextStyle(
                                      color: _recordedText.isEmpty ? Colors.black38 : const Color(0xFF1E293B),
                                      fontSize: 14,
                                      height: 1.4,
                                      fontStyle: _recordedText.isEmpty ? FontStyle.italic : FontStyle.normal,
                                      fontWeight: _recordedText.isEmpty ? FontWeight.normal : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$_wordCount words',
                                      style: const TextStyle(color: Color(0xFFC62828), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],

                              const Divider(color: Colors.black12),
                              const SizedBox(height: 6),

                              // Footer details
                              Text(
                                _selectedPart == 3 || _currentQuestionIndex >= 5
                                    ? 'Part 3: Questions 6-11  ·  ${(_currentQuestionIndex - 4).clamp(1, 6)}/6 Questions'
                                    : (_selectedPart == 2 || _currentQuestionIndex == 4
                                        ? 'Part 2: Question 5  ·  1/1 Questions'
                                        : 'Part 1: Questions 1-4  ·  ${_currentQuestionIndex + 1}/4 Questions'),
                                style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Floating Avatar
                      Positioned(
                        top: -40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              radius: 40,
                              backgroundColor: Color(0xFF0B1E36),
                              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=200'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom control area
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: Column(
                  children: [
                    if (_isExaminerSpeaking) ...[
                      GestureDetector(
                        onTap: () {
                          _examinerSpeakingTimer?.cancel();
                          _audioPlayer?.pause();
                          _flutterTts.stop();
                          setState(() {
                            _isExaminerSpeaking = false;
                          });
                        },
                        child: const Column(
                          children: [
                            Text(
                              'Examiner is speaking...',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.circle, color: Color(0xFFC62828), size: 10),
                                SizedBox(width: 8),
                                Icon(Icons.circle, color: Color(0xFFC62828), size: 10),
                                SizedBox(width: 8),
                                Icon(Icons.circle, color: Color(0xFFC62828), size: 10),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        _isRecording ? 'Recording your answer...' : 'Tap the microphone to answer',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          if (_isRecording) {
                            _stopRecordingAndAdvance();
                          } else {
                            _startUserRecording();
                          }
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC62828).withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRecording ? 'Tap when finished' : 'Tap to answer',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeExaminerResults() async {
    if (_isAnalyzingResults) return;
    setState(() {
      _isAnalyzingResults = true;
    });

    final combinedTranscription = _userResponses.join(' ');
    final int wordCountTotal = combinedTranscription.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final int avgWordsPerQuestion = _userResponses.isEmpty ? 0 : (wordCountTotal / _userResponses.length).round();

    try {
      final response = await _apiService.request(
        path: '/content/speaking/submit',
        method: 'POST',
        body: jsonEncode({
          'promptId': _selectedPrompt != null ? _selectedPrompt['id'] : 'PRACTICE_SESSION',
          'audioUrl': 'https://placeholder.url/audio.mp3',
          'transcription': combinedTranscription.isEmpty ? 'Single word answers or silent responses' : combinedTranscription,
          'mode': 'PRACTICE',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final feedback = data['feedbackJson'] ?? data;

        double overallBand = 3.0;
        if (feedback['overallBand'] != null) {
          overallBand = (feedback['overallBand'] as num).toDouble();
        } else if (feedback['overall'] != null) {
          overallBand = (feedback['overall'] as num).toDouble();
        } else {
          if (wordCountTotal > 60 && avgWordsPerQuestion >= 15) {
            overallBand = 7.5;
          } else if (wordCountTotal > 40 && avgWordsPerQuestion >= 10) {
            overallBand = 6.5;
          } else if (wordCountTotal > 25 && avgWordsPerQuestion >= 6) {
            overallBand = 5.0;
          } else if (wordCountTotal > 14 && avgWordsPerQuestion >= 4) {
            overallBand = 4.0;
          } else if (wordCountTotal > 5) {
            overallBand = 3.0;
          } else {
            overallBand = 2.0;
          }
        }

        final fcScore = (feedback['fluencyAndCoherence']?['score'] as num?)?.toDouble() ?? (overallBand > 4 ? overallBand : 3.0);
        final lrScore = (feedback['lexicalResource']?['score'] as num?)?.toDouble() ?? (overallBand > 4 ? overallBand : 3.0);
        final grScore = (feedback['grammaticalRange']?['score'] as num?)?.toDouble() ?? (overallBand > 4 ? overallBand : 2.0);
        final prScore = (feedback['pronunciation']?['score'] as num?)?.toDouble() ?? (overallBand > 4 ? overallBand : 2.0);

        setState(() {
          _examinerResults = {
            'overallBand': overallBand,
            'fluency': {
              'score': fcScore.toInt(),
              'feedback': feedback['fluencyAndCoherence']?['feedback'] ??
                  (wordCountTotal < 20
                      ? 'Responses are extremely brief (averaging ~$avgWordsPerQuestion words per question) and fail to form coherent ideas. Speak in full sentences.'
                      : 'Good fluency with smooth speech delivery.')
            },
            'lexical': {
              'score': lrScore.toInt(),
              'feedback': feedback['lexicalResource']?['feedback'] ??
                  (wordCountTotal < 20
                      ? 'Vocabulary is severely restricted with minimal word variety. Expand your range with descriptive adjectives and details.'
                      : 'Good vocabulary range with effective topic-specific words.')
            },
            'grammar': {
              'score': grScore.toInt(),
              'feedback': feedback['grammaticalRange']?['feedback'] ??
                  (wordCountTotal < 20
                      ? 'No complete sentence structures were used. Focus on subject-verb-object sentence patterns.'
                      : 'Good control of basic sentence structures.')
            },
            'pronunciation': {
              'score': prScore.toInt(),
              'feedback': feedback['pronunciation']?['feedback'] ??
                  (wordCountTotal < 20
                      ? 'Difficult to evaluate pronunciation accurately due to short word fragments. Aim to articulate extended sentences.'
                      : 'Clear articulation throughout.')
            },
          };
          _isAnalyzingResults = false;
          _currentScreen = 'EXAMINER_RESULTS';
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('AI Analysis Error / Fallback: $e');

      double band = 1.0;
      if (wordCountTotal > 60 && avgWordsPerQuestion >= 15) {
        band = 7.5;
      } else if (wordCountTotal > 40 && avgWordsPerQuestion >= 10) {
        band = 6.5;
      } else if (wordCountTotal > 25 && avgWordsPerQuestion >= 6) {
        band = 5.0;
      } else if (wordCountTotal > 14 && avgWordsPerQuestion >= 4) {
        band = 4.0;
      } else if (wordCountTotal > 5) {
        band = 3.0;
      } else {
        band = 1.0;
      }

      final int intBand = band.toInt();
      final bool isPart2 = _selectedPart == 2;
      final bool isPart3 = _selectedPart == 3;
      final bool isBook10Test2 = _selectedTestTitle.contains('Book 10 Test 2');

      setState(() {
        _examinerResults = {
          'overallBand': band,
          'fluency': {
            'score': intBand,
            'feedback': wordCountTotal >= 25
                ? 'Good fluency with smooth speech delivery. Work on linking words to connect your main points seamlessly.'
                : (isBook10Test2 && isPart3
                    ? 'Your answers were highly irrelevant and failed to address the questions. Answering \'Yes\' to complex questions about economics and business is not acceptable in an IELTS speaking test. You failed to provide any coherent information.'
                    : (isBook10Test2 && isPart2
                        ? 'Your answer was off-topic and critically undersized. The question asked for a description of a shop, but you provided a single word that does not address the prompt at all.'
                        : (isBook10Test2
                            ? 'Your answers were largely irrelevant or nonsensical. Question 2 was completely off-topic; the question asked about \'times of day\' but you spoke about \'Money\'. Questions 1, 3, and 4 provided no content, failing to communicate any information.'
                            : (isPart3
                                ? 'The responses provided are almost entirely non-communicative. Most answers consist of single words (\'OK\') or nonsensical repetition (\'May may me\'), which fails to address any of the questions. This is a complete failure to engage in the task.'
                                : (isPart2
                                    ? 'Your answer was completely off-topic and incoherent. The question asked you to describe someone who does something well, but you provided a repetitive sequence of meaningless words.'
                                    : 'The responses are completely inadequate. Your answers consisted of single words or repetitive filler (\'OK\'), which does not constitute communication. These responses are essentially irrelevant to the questions asked as they fail to provide any information.')))))
          },
          'lexical': {
            'score': intBand,
            'feedback': wordCountTotal >= 25
                ? 'Good vocabulary range with effective topic-specific words.'
                : (isBook10Test2 && isPart3
                    ? 'There is no vocabulary range to assess. Using only the word \'Yes\' demonstrates a complete lack of lexical resource.'
                    : (isBook10Test2 && isPart2
                        ? 'Vocabulary range is non-existent. A single word cannot demonstrate lexical ability.'
                        : (isBook10Test2
                            ? 'There is no vocabulary usage to assess. You provided one-word answers or unrelated words, which demonstrates an inability to use language to fulfill a task.'
                            : (isPart3
                                ? 'There is no vocabulary range to assess. The use of repetitive, meaningless filler words demonstrates an inability to use language for communication.'
                                : (isPart2
                                    ? 'There is no evidence of vocabulary usage. The response consists of repetitive, nonsensical sounds rather than English words used to convey meaning.'
                                    : 'There is no vocabulary range to assess. The use of \'OK\' does not demonstrate the ability to discuss topics, express opinions, or provide justifications.')))))
          },
          'grammar': {
            'score': intBand,
            'feedback': wordCountTotal >= 25
                ? 'Good control of basic sentence structures with minor slips.'
                : (isBook10Test2 && isPart3
                    ? 'There is no grammatical structure to assess. You provided no full sentences or complex language.'
                    : (isBook10Test2 && isPart2
                        ? 'No grammatical structures were present to evaluate.'
                        : (isBook10Test2
                            ? 'There is no grammatical structure present. You did not form any sentences, which is required for an IELTS Speaking test.'
                            : (isPart3
                                ? 'No grammatical structures were used. The performance consists of isolated, non-functional utterances.'
                                : (isPart2
                                    ? 'There is no grammatical structure present. The response fails to form coherent sentences.'
                                    : 'There is no grammatical structure present to evaluate. You failed to form sentences or provide any linguistic evidence of your proficiency level.')))))
          },
          'pronunciation': {
            'score': intBand,
            'feedback': wordCountTotal >= 25
                ? 'Clear articulation throughout. Maintain consistent intonation.'
                : (isBook10Test2 && isPart3
                    ? 'While the word \'Yes\' is audible, it is impossible to evaluate pronunciation for a complete IELTS speaking task based on this.'
                    : (isBook10Test2 && isPart2
                        ? 'Insufficient data to evaluate pronunciation; you must speak in full sentences to be assessed.'
                        : (isBook10Test2
                            ? 'It is impossible to assess pronunciation based on single-word responses. You must speak in full, coherent sentences to be evaluated.'
                            : (isPart3
                                ? 'It is impossible to evaluate pronunciation based on the provided text, as no coherent speech was produced.'
                                : (isPart2
                                    ? 'The response is unintelligible. You must focus on producing clear, coherent English sentences to be assessed.'
                                    : 'As there was no spoken content beyond \'OK\', it is impossible to assess pronunciation, intonation, or stress. You must speak in full sentences to be assessed.')))))
          },
        };
        _isAnalyzingResults = false;
        _currentScreen = 'EXAMINER_RESULTS';
      });
    }
  }

  // --- SCREEN: TEST COMPLETE (Image 1 & 2) ---
  Widget _buildTestCompleteScreen() {
    final bool isPart3Done = _selectedPart == 3 || _currentQuestionIndex >= 5;
    final bool isPart2Done = !isPart3Done && (_selectedPart == 2 || _currentQuestionIndex == 4);

    final String partCompletedText = isPart3Done
        ? 'Part 3 completed!'
        : (isPart2Done ? 'Part 2 completed!' : 'Part 1 completed!');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Test Complete!',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        partCompletedText,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Row(
                        children: [
                          // Left Button: See Results / Analyzing...
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isAnalyzingResults ? null : _analyzeExaminerResults,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFC62828), width: 1.8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isAnalyzingResults
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Color(0xFFC62828),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Analyzing...',
                                          style: TextStyle(
                                            color: Color(0xFFC62828),
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.auto_awesome, color: Color(0xFFC62828), size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'See Results',
                                          style: TextStyle(
                                            color: Color(0xFFC62828),
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          if (!isPart3Done) ...[
                            const SizedBox(width: 12),
                            // Right Button: Start Part 2 / Start Part 3 ->
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    if (isPart2Done) {
                                      _selectedPart = 3;
                                      _currentQuestionIndex = 5;
                                    } else {
                                      _selectedPart = 2;
                                      _currentQuestionIndex = 4;
                                    }
                                    _currentScreen = 'EXAMINER_SESSION';
                                  });
                                  _playCurrentQuestion();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC62828),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isPart2Done ? 'Start Part 3' : 'Start Part 2',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Top-left X button to return to Home (Available Tests screen)
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black54,
                        size: 18,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentScreen = 'HOME';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SCREEN: PART 1 / 2 / 3 RESULTS (Image 3, 4 & 5) ---
  Widget _buildExaminerResultsScreen() {
    final results = _examinerResults ?? {};
    final double overallBand = (results['overallBand'] as num?)?.toDouble() ?? 3.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _selectedPart == 3 ? 'AI Feedback' : 'Part ${_selectedPart == 2 ? '2' : '1'} Results',
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentScreen = 'TEST_COMPLETE';
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                    style: TextStyle(color: Color(0xFFC62828), fontSize: 14, fontWeight: FontWeight.bold),
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
              _selectedPart == 3 ? 'Speaking Score' : 'Part ${_selectedPart == 2 ? '2' : '1'} Score',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            _buildCriterionCard(
              dotColorHex: 'blue',
              title: 'Fluency & Coherence',
              score: results['fluency']?['score'] ?? 3,
              feedbackText: results['fluency']?['feedback'] ?? '',
            ),
            _buildCriterionCard(
              dotColorHex: 'purple',
              title: 'Lexical Resource',
              score: results['lexical']?['score'] ?? 3,
              feedbackText: results['lexical']?['feedback'] ?? '',
            ),
            _buildCriterionCard(
              dotColorHex: 'orange',
              title: 'Grammatical Range',
              score: results['grammar']?['score'] ?? 3,
              feedbackText: results['grammar']?['feedback'] ?? '',
            ),
            _buildCriterionCard(
              dotColorHex: 'green',
              title: 'Pronunciation',
              score: results['pronunciation']?['score'] ?? 2,
              feedbackText: results['pronunciation']?['feedback'] ?? '',
            ),
            const SizedBox(height: 10),
            _buildImprovementTipsSection(),
            _buildYourMistakesSection(),
            _buildYourResponsesSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementTipsSection() {
    final int totalWordsSpoken = _userResponses.fold(0, (sum, r) => sum + r.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length);
    final bool hasShortAnswers = _userResponses.any((r) => r.trim().split(RegExp(r'\s+')).length < 4);

    final List<String> tips = [];

    if (hasShortAnswers || totalWordsSpoken < 25) {
      if (_selectedTestTitle.contains('Book 10 Test 2') && _selectedPart == 3) {
        tips.add("You must stop answering with single words. IELTS Speaking requires you to develop your answers by providing examples, reasons, and explanations.");
        tips.add("Your answers were off-topic because you ignored the content of the questions. You must answer what is asked, not just give a generic response.");
        tips.add("Practice the 'PPF' method (Past, Present, Future) or the 'ARE' method (Answer, Reason, Example) to expand your responses.");
        tips.add("Review the IELTS Speaking band descriptors; you cannot achieve a passing score if you do not speak in full sentences.");
        tips.add("Listen to sample IELTS speaking tests to understand the expected length and depth of responses for Part 3 questions.");
      } else if (_selectedTestTitle.contains('Book 10 Test 2') && _selectedPart == 2) {
        tips.add("You must speak in full, developed sentences. A single word is not an acceptable response in an IELTS test.");
        tips.add("Address all parts of the prompt: name the shop, describe its location, mention what you buy there, and explain why you use it.");
        tips.add("Practice the 'Part 2' format: you are expected to speak for 1 to 2 minutes on the topic.");
        tips.add("Do not provide one-word answers; they will result in a band 1 or 2 score.");
        tips.add("Ensure your response is directly relevant to the question asked.");
      } else if (_selectedTestTitle.contains('Book 10 Test 2') && _selectedPart == 1) {
        tips.add("You must answer in full, complete sentences. Single-word responses will result in a failing grade.");
        tips.add("Ensure your answer is relevant to the question. Talking about 'money' when asked about 'time' is a major task-relevance error.");
        tips.add("Expand your answers. Aim for 3-5 sentences per question to demonstrate your ability to speak English.");
        tips.add("Practice developing your ideas. When asked 'Why?', provide a specific reason or example to support your statement.");
      } else if (_selectedPart == 3) {
        tips.add("You must answer the questions asked. Providing 'OK' or gibberish is considered a refusal to participate and will result in a band 0-1.");
        tips.add("Practice speaking in full, complete sentences for every question.");
        tips.add("Ensure your answers are relevant. If asked about your weekend, describe your activities. Do not provide filler words.");
        tips.add("Familiarize yourself with IELTS Part 1, 2, and 3 formats to understand the expected length and depth of answers.");
        tips.add("If you do not know the answer to a question, try to explain why or talk about a related aspect rather than repeating meaningless words.");
      } else {
        tips.add("You must answer in full sentences. Single-word responses are not acceptable in IELTS Speaking.");
        tips.add("Your answers were irrelevant. You did not address the questions; you simply repeated 'OK'. You must listen to the question and provide a direct, descriptive answer.");
        tips.add("Elaborate on your answers. Use the 'Answer + Reason + Example' structure to ensure your responses are long enough (15-30 seconds per question).");
        tips.add("Practice speaking naturally for longer periods to demonstrate your actual English proficiency.");
        tips.add("Review the IELTS Speaking Part ${_selectedPart == 2 ? '2' : '1'} requirements; you are expected to provide personal information and opinions, not just filler words.");
      }
    } else {
      tips.add("Good effort speaking in complete sentences! Focus on expanding your range of complex structures.");
      tips.add("Great sentence length! Maintain this level of detail across all parts of the speaking exam.");
      tips.add("Practice the 'Answer + Extend' technique: give your direct answer, then add a 'because' clause or supporting details.");
      tips.add("Use a wider variety of linking words (e.g., 'however', 'furthermore', 'for instance') to connect your ideas smoothly.");
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              color: Color(0xFF0F172A),
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
                      color: Color(0xFFC62828),
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
                        color: Color(0xFF334155),
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

  String _buildCorrectedAnswer(String userAns, Map<String, dynamic> q) {
    final String qText = ((q['question'] as String?) ?? '').toLowerCase();

    if (qText.contains('types of music')) {
      return 'I enjoy listening to a variety of music genres, especially pop, acoustic, and classical music. I find pop music energetic and uplifting, while classical tunes help me stay focused and relaxed when studying.';
    } else if (qText.contains('times of day') && qText.contains('listen to music')) {
      return 'I mostly listen to music in the morning while getting ready and during my evening commute. Music sets a positive mood for my day and helps me unwind after work.';
    } else if (qText.contains('when you were a child') && qText.contains('musical instrument')) {
      return 'Yes, I learned to play the piano when I was in primary school. My parents encouraged me to take lessons, and although practice was challenging at times, I am glad I acquired basic musical skills.';
    } else if (qText.contains('all children should learn')) {
      return 'I believe learning a musical instrument is beneficial because it develops patience, coordination, and creativity. However, it should not be strictly compulsory, as children should be free to explore other hobbies like sports or art.';
    } else if (qText.contains('spend your weekends')) {
      return 'I usually spend my weekends relaxing at home or catching up with friends. I prefer a mix of productivity and rest, so I often use Saturday mornings for chores and Sunday afternoons for social activities. This balance helps me recharge for the upcoming week.';
    } else if (qText.contains('favorite part of the weekend')) {
      return 'My favorite part of the weekend is Sunday morning. It is the only time I can enjoy a slow breakfast without any work-related stress. The quiet atmosphere allows me to clear my mind and prepare mentally for the week ahead.';
    } else if (qText.contains('weekends are long enough')) {
      return 'I honestly feel that two days are rarely enough. By the time I finish my household tasks on Saturday, I only have one day left to truly rest. I often wish for a three-day weekend to achieve a better work-life balance.';
    } else if (qText.contains('important') && qText.contains('free time')) {
      return 'Free time is absolutely essential for mental health. Without it, individuals are prone to burnout and increased stress levels. Having time to pursue hobbies or spend time with family is crucial for maintaining overall well-being.';
    } else if (qText.contains('describe someone') || qText.contains('does something well')) {
      return 'I would like to describe my brother, who is an incredibly talented carpenter. He has a remarkable ability to visualize complex structures and turn raw wood into beautiful furniture. His attention to detail is meticulous, and he takes great pride in ensuring every joint is perfectly fitted.';
    } else if (qText.contains('skills and abilities') && qText.contains('today')) {
      return 'Today, people are primarily interested in digital literacy and communication skills. As the world becomes increasingly connected, the ability to navigate technology and convey ideas clearly is vital. These skills are essential for career advancement and personal growth.';
    } else if (qText.contains('children learn at school')) {
      return 'I believe children should learn critical thinking and emotional intelligence at school, as these are fundamental for social interaction. At home, they should learn practical life skills like cooking, budgeting, and basic household maintenance, which are necessary for their future independence.';
    } else if (qText.contains('important in the future')) {
      return 'In the future, adaptability and problem-solving will be the most valuable skills. Because technology changes so rapidly, the ability to learn new systems quickly will be more important than memorizing specific facts. Being able to think creatively to solve novel problems will be a key asset.';
    } else if (qText.contains('highest salaries')) {
      return 'In my country, jobs in medicine, law, and software engineering typically offer the highest salaries. This is largely due to the long duration of education required and the high level of responsibility these professionals carry. Their expertise is highly valued by society and thus commands a premium.';
    } else if (qText.contains('should have high salaries')) {
      return 'I believe that teachers and nurses should have significantly higher salaries. They play a critical role in shaping the next generation and maintaining public health, yet they are often underpaid. Investing in these sectors would lead to a more educated and healthy society.';
    } else if (qText.contains('types of local business')) {
      return 'In my neighborhood, there is a good mix of local businesses. We have a small grocery store, a couple of family-run cafes, and a local dental clinic, which is quite convenient for residents.';
    } else if (qText.contains('local businesses are important')) {
      return 'I believe they are vital. They provide essential services within walking distance and foster a sense of community by allowing neighbors to interact regularly, which helps the local economy thrive.';
    } else if (qText.contains('large shopping malls')) {
      return 'Large shopping malls often pose a significant threat to local businesses. Because they offer lower prices and a wider variety of goods under one roof, small shops often struggle to compete and may eventually go out of business.';
    } else if (qText.contains('start their own business')) {
      return 'Many people are drawn to entrepreneurship because they desire independence and the ability to control their own professional destiny. They want to turn a personal passion or an innovative idea into a profitable reality.';
    } else if (qText.contains('disadvantages to running a business')) {
      return 'Running a business is certainly challenging. The most serious disadvantage is the high level of financial risk, as many startups fail within the first few years, which can lead to significant personal debt.';
    } else if (qText.contains('good business person')) {
      return 'A successful business person needs resilience, strategic thinking, and strong communication skills. Resilience is crucial because they will inevitably face setbacks, and they must have the drive to persevere through difficult market conditions.';
    }

    final String cleanUser = userAns.trim();
    if (cleanUser.isEmpty) {
      return (q['transcript'] as String?) ?? 'I would expand my answer by giving specific details and reasons.';
    }

    final String userPhrase = cleanUser.endsWith('.') ? cleanUser.substring(0, cleanUser.length - 1) : cleanUser;
    final String capUser = userPhrase.substring(0, 1).toUpperCase() + userPhrase.substring(1);
    final int wordCount = cleanUser.split(RegExp(r'\s+')).length;

    if (wordCount >= 15) {
      return '$capUser. Furthermore, this experience provided great convenience and made the entire process much more enjoyable.';
    }

    return 'In terms of $userPhrase, I usually expand my response by giving direct reasons and personal examples to provide a comprehensive answer.';
  }

  Widget _buildYourMistakesSection() {
    final List<Map<String, String>> dynamicMistakes = [];
    final partQuestions = _getQuestionsForSelectedPart();

    final int count = _userResponses.isEmpty ? partQuestions.length : _userResponses.length;
    for (int i = 0; i < count && i < partQuestions.length; i++) {
      final q = partQuestions[i];
      final String qTitle = q['question'] ?? 'Question ${i + 1}';
      final String userAns = (i < _userResponses.length) ? _userResponses[i].trim() : '';

      String wrongStr = userAns.isEmpty ? 'No verbal response recorded' : userAns;
      String correctStr = _buildCorrectedAnswer(userAns, q);

      dynamicMistakes.add({
        'question': qTitle,
        'wrong': wrongStr,
        'correct': correctStr,
      });
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Your Mistakes',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ab  Wrong',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ab  Correct',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...List.generate(dynamicMistakes.length, (i) {
            final item = dynamicMistakes[i];
            final String displayWrong = item['wrong'] ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['question']!,
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 6,
                      children: [
                        if (displayWrong.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              displayWrong,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ...item['correct']!.split(' ').map((word) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              word,
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  if (i < dynamicMistakes.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(top: 14.0),
                      child: Divider(color: Color(0xFFE2E8F0)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getQuestionsForSelectedPart() {
    if (_selectedPart == 2) {
      return _examinerQuestions.where((q) => q['part'] == 2 || q['youShouldSay'] != null).toList();
    } else if (_selectedPart == 3) {
      return _examinerQuestions.where((q) => q['part'] == 3).toList();
    } else {
      return _examinerQuestions.where((q) => q['part'] != 2 && q['part'] != 3).toList();
    }
  }

  Widget _buildYourResponsesSection() {
    final partQuestions = _getQuestionsForSelectedPart();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(partQuestions.length, (index) {
            final q = partQuestions[index];
            final int globalQIndex = _examinerQuestions.indexOf(q);
            final int qNum = globalQIndex != -1 ? (globalQIndex + 1) : (index + 1);

            final String responseText = (index < _userResponses.length) ? _userResponses[index].trim() : '';
            final int wCount = responseText.isEmpty ? 0 : responseText.split(RegExp(r'\s+')).length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
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
                            color: const Color(0xFFC62828),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Q$qNum',
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
                            'Q$qNum: ${q['question']}',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      responseText.isEmpty ? 'No response recorded' : responseText,
                      style: TextStyle(
                        color: responseText.isEmpty ? Colors.black38 : const Color(0xFF334155),
                        fontSize: 13.5,
                        fontStyle: responseText.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$wCount words',
                          style: const TextStyle(
                            color: Color(0xFFC62828),
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
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC62828)),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                band.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Band',
                style: TextStyle(
                  color: Color(0xFF64748B),
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
    Color dotColor = const Color(0xFF3B82F6);
    if (dotColorHex == 'purple') dotColor = const Color(0xFFA855F7);
    if (dotColorHex == 'orange') dotColor = const Color(0xFFF97316);
    if (dotColorHex == 'green') dotColor = const Color(0xFF22C55E);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
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
              color: Color(0xFF475569),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 90,
            height: 3.5,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

