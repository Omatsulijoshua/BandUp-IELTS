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
import '../theme/app_colors.dart';
import '../widgets/premium_paywall.dart';
import '../widgets/times_up_dialog.dart';
import 'history_screen.dart';

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
  StreamSubscription? _audioPositionSubscription;
  StreamSubscription? _audioPlayerCompleteSubscription;
  bool _isAudioSeeking = false;

  // ==========================================
  // IELTS BOOK 10 TEST 1 (Audio: 1-4.mp3, 5.mp3, 6-11.mp3)
  // ==========================================
  final List<Map<String, dynamic>> _book10Test1Questions = [
    // Part 1: Questions 1-4 (in q1.mp3 - q4.mp3)
    {
      'question': 'How do you usually spend your weekends? [Why?]',
      'audioAsset': 'q1.mp3',
      'duration': 2.54,
      'start': 0.0,
      'promptEnd': 2.54,
      'end': 2.54,
      'part': 1,
      'transcript': 'I usually spend my weekends relaxing at home with a book or catching up with friends for coffee. I enjoy this because it helps me decompress after a busy week of work.',
    },
    {
      'question': 'Which is your favorite part of the weekend? [Why?]',
      'audioAsset': 'q2.mp3',
      'duration': 3.02,
      'start': 0.0,
      'promptEnd': 3.02,
      'end': 3.02,
      'part': 1,
      'transcript': 'My favorite part is Sunday morning because it is quiet and peaceful. I can take my time having breakfast without any rush.',
    },
    {
      'question': 'Do you think your weekends are long enough? [Why/Why not?]',
      'audioAsset': 'q3.mp3',
      'duration': 3.02,
      'start': 0.0,
      'promptEnd': 3.02,
      'end': 3.02,
      'part': 1,
      'transcript': 'Honestly, two days often feel a bit short especially when there are many chores to do. A three-day weekend would give a much better balance between rest and personal projects.',
    },
    {
      'question': 'How important do you think it is to have free time at the weekends? [Why?]',
      'audioAsset': 'q4.mp3',
      'duration': 5.54,
      'start': 0.0,
      'promptEnd': 5.54,
      'end': 5.54,
      'part': 1,
      'transcript': 'I think free time on weekends is essential for mental health and well-being. It allows people to recharge their energy and spend quality time with loved ones.',
    },

    // Part 2: Question 5 (Cue Card in q5.mp3)
    {
      'question': 'Describe someone you know who does something well.',
      'audioAsset': 'q5.mp3',
      'duration': 4.03,
      'start': 0.0,
      'promptEnd': 4.03,
      'end': 4.03,
      'part': 2,
      'youShouldSay': [
        'who this person is',
        'how you know this person',
        'what they do well',
        'and explain why you think this person is so good at doing this.'
      ],
      'transcript': 'I would like to talk about my older brother, who is an exceptionally talented carpenter. He has a natural flair for visualizing complex designs and crafting bespoke furniture with immense precision. He has spent years honing his craft, and seeing him work with such precision is truly impressive. He is definitely the most skillful person I know.',
    },

    // Part 3: Questions 6-11 (in q6.mp3 - q11.mp3)
    {
      'question': 'What skills and abilities do people most want to have today? Why?',
      'audioAsset': 'q6.mp3',
      'duration': 5.04,
      'start': 0.0,
      'promptEnd': 5.04,
      'end': 5.04,
      'part': 3,
      'transcript': 'Nowadays, digital literacy, problem-solving, and effective communication are in high demand. People value these skills because they enhance employability and allow individuals to adapt quickly in a fast-evolving technological landscape.',
    },
    {
      'question': 'Which skills should children learn at school? Are there any skills which they should learn at home? What are they?',
      'audioAsset': 'q7.mp3',
      'duration': 6.53,
      'start': 0.0,
      'promptEnd': 6.53,
      'end': 6.53,
      'part': 3,
      'transcript': 'Schools should focus on academic knowledge, teamwork, and critical thinking. On the other hand, essential life skills such as emotional resilience, personal hygiene, and financial discipline are best taught at home by parents.',
    },
    {
      'question': 'Which skills do you think will be important in the future? Why?',
      'audioAsset': 'q8.mp3',
      'duration': 4.54,
      'start': 0.0,
      'promptEnd': 4.54,
      'end': 4.54,
      'part': 3,
      'transcript': 'In the future, adaptability, data analysis, and emotional intelligence will be crucial. As automation takes over repetitive tasks, human-centric abilities like creative thinking and empathy will become paramount.',
    },
    {
      'question': 'Which kinds of jobs have the highest salaries in your country? Why is this?',
      'audioAsset': 'q9.mp3',
      'duration': 5.54,
      'start': 0.0,
      'promptEnd': 5.54,
      'end': 5.54,
      'part': 3,
      'transcript': 'Roles in technology, medicine, and corporate management command the highest salaries in my country. This is because these positions require specialized expertise, years of rigorous training, and carry immense operational responsibility.',
    },
    {
      'question': 'Are there any other jobs that you think should have high salaries? Why do you think that?',
      'audioAsset': 'q10.mp3',
      'duration': 5.04,
      'start': 0.0,
      'promptEnd': 5.04,
      'end': 5.04,
      'part': 3,
      'transcript': 'Teachers and healthcare workers definitely deserve higher remuneration. They perform fundamental roles in nurturing future generations and saving lives, yet their compensation often does not reflect their immense social contribution.',
    },
    {
      'question': 'Some people say it would be better for society if everyone got the same salary. What do you think about that? Why?',
      'audioAsset': 'q11.mp3',
      'duration': 6.53,
      'start': 0.0,
      'promptEnd': 6.53,
      'end': 6.53,
      'part': 3,
      'transcript': 'I strongly disagree with that idea. Equal salaries for all professions would reduce motivation and work ethic, as people would lack incentives to pursue challenging, highly skilled, or high-risk careers. A fair economic system should reward effort, qualification, and responsibility while maintaining a basic safety net.',
    },
  ];

  // ==========================================
  // IELTS BOOK 10 TEST 2 (Audio: q1.mp3 - q11.mp3)
  // ==========================================
  final List<Map<String, dynamic>> _book10Test2Questions = [
    // Part 1: Questions 1-4 (in q1.mp3 - q4.mp3)
    {
      'question': 'What types of music do you like to listen to? [Why?]',
      'audioAsset': 'q1.mp3',
      'duration': 2.74,
      'start': 0.0,
      'promptEnd': 2.74,
      'end': 2.74,
      'part': 1,
      'transcript': 'I enjoy listening to a variety of music genres, especially pop, acoustic, and classical music. I find pop music energetic and uplifting, while classical tunes help me stay focused and relaxed when studying.',
    },
    {
      'question': 'At what times of day do you like to listen to music? [Why?]',
      'audioAsset': 'q2.mp3',
      'duration': 3.02,
      'start': 0.0,
      'promptEnd': 3.02,
      'end': 3.02,
      'part': 1,
      'transcript': 'I mostly listen to music in the morning while getting ready and during my evening commute. Music sets a positive mood for my day and helps me unwind after work.',
    },
    {
      'question': 'Did you learn to play a musical instrument when you were a child? [Why/Why not?]',
      'audioAsset': 'q3.mp3',
      'duration': 4.03,
      'start': 0.0,
      'promptEnd': 4.03,
      'end': 4.03,
      'part': 1,
      'transcript': 'Yes, I learned to play the piano when I was in primary school. My parents encouraged me to take lessons, and although practice was challenging at times, I am glad I acquired basic musical skills.',
    },
    {
      'question': 'Do you think all children should learn to play a musical instrument? [Why/why not?]',
      'audioAsset': 'q4.mp3',
      'duration': 5.04,
      'start': 0.0,
      'promptEnd': 5.04,
      'end': 5.04,
      'part': 1,
      'transcript': 'I believe learning a musical instrument is beneficial because it develops patience, coordination, and creativity. However, it should not be strictly compulsory, as children should be free to explore other hobbies like sports or art.',
    },

    // Part 2: Question 5 (Cue Card in q5.mp3)
    {
      'question': 'Describe a shop near where you live that you sometimes use.',
      'audioAsset': 'q5.mp3',
      'duration': 3.74,
      'start': 0.0,
      'promptEnd': 3.74,
      'end': 3.74,
      'part': 2,
      'youShouldSay': [
        'what sorts of product or service it sells',
        'what the shop looks like',
        'where it is located',
        'and explain why you use this shop.'
      ],
      'transcript': 'There is a small local grocery store just a five-minute walk from my apartment that I visit quite frequently. It is a family-run business that stocks a wide variety of fresh produce, dairy, and household essentials. I find it incredibly convenient because I can quickly pick up ingredients for dinner on my way home from work. The staff are always very friendly and helpful, which makes the shopping experience much more pleasant than going to a large, crowded supermarket.',
    },

    // Part 3: Questions 6-11 (in q6.mp3 - q11.mp3)
    {
      'question': 'What types of local business are there in your neighbourhood? Are there any restaurants, shops, or dentists for example?',
      'audioAsset': 'q6.mp3',
      'duration': 7.82,
      'start': 0.0,
      'promptEnd': 7.82,
      'end': 7.82,
      'part': 3,
      'transcript': 'In my neighborhood, there is a good mix of local businesses. We have a small grocery store, a couple of family-run cafes, and a local dental clinic, which is quite convenient for residents.',
    },
    {
      'question': 'Do you think local businesses are important for a neighborhood? In what way?',
      'audioAsset': 'q7.mp3',
      'duration': 5.54,
      'start': 0.0,
      'promptEnd': 5.54,
      'end': 5.54,
      'part': 3,
      'transcript': 'I believe they are vital. They provide essential services within walking distance and foster a sense of community by allowing neighbors to interact regularly, which helps the local economy thrive.',
    },
    {
      'question': 'How do large shopping malls and commercial centres affect small local businesses? Why do you think that is?',
      'audioAsset': 'q8.mp3',
      'duration': 6.84,
      'start': 0.0,
      'promptEnd': 6.84,
      'end': 6.84,
      'part': 3,
      'transcript': 'Large shopping malls often pose a significant threat to local businesses. Because they offer lower prices and a wider variety of goods under one roof, small shops often struggle to compete and may eventually go out of business.',
    },
    {
      'question': 'Why do some people want to start their own business?',
      'audioAsset': 'q9.mp3',
      'duration': 3.74,
      'start': 0.0,
      'promptEnd': 3.74,
      'end': 3.74,
      'part': 3,
      'transcript': 'Many people are drawn to entrepreneurship because they desire independence and the ability to control their own professional destiny. They want to turn a personal passion or an innovative idea into a profitable reality.',
    },
    {
      'question': 'Are there any disadvantages to running a business? Which is the most serious?',
      'audioAsset': 'q10.mp3',
      'duration': 5.23,
      'start': 0.0,
      'promptEnd': 5.23,
      'end': 5.23,
      'part': 3,
      'transcript': 'Running a business is certainly challenging. The most serious disadvantage is the high level of financial risk, as many startups fail within the first few years, which can lead to significant personal debt.',
    },
    {
      'question': 'What are the most important qualities that a good business person needs? Why is that?',
      'audioAsset': 'q11.mp3',
      'duration': 5.64,
      'start': 0.0,
      'promptEnd': 5.64,
      'end': 5.64,
      'part': 3,
      'transcript': 'A successful business person needs resilience, strategic thinking, and strong communication skills. Resilience is crucial because they will inevitably face setbacks, and they must have the drive to persevere through difficult market conditions.',
    },
  ];

  // ==========================================
  // IELTS BOOK 21 TEST 1 (Audio: q1.mp3 - q11.mp3)
  // ==========================================
  final List<Map<String, dynamic>> _book21Test1Questions = [
    // Part 1: Questions 1-4 (in q1.mp3 - q4.mp3)
    {
      'question': 'How do you usually spend your weekends? [Why?]',
      'audioAsset': 'q1.mp3',
      'duration': 2.33,
      'start': 0.0,
      'promptEnd': 2.33,
      'end': 2.33,
      'part': 1,
      'transcript': 'I usually spend my weekends catching up on rest, reading, or meeting friends for coffee. It helps me refresh my mind after a busy week.',
    },
    {
      'question': 'Which is your favorite part of the weekend? [Why?]',
      'audioAsset': 'q2.mp3',
      'duration': 3.02,
      'start': 0.0,
      'promptEnd': 3.02,
      'end': 3.02,
      'part': 1,
      'transcript': 'My favorite part is Saturday evening because I can spend unhurried leisure time doing activities I genuinely enjoy without worrying about waking up early.',
    },
    {
      'question': 'Do you think your weekends are long enough? [Why/Why not?]',
      'audioAsset': 'q3.mp3',
      'duration': 3.02,
      'start': 0.0,
      'promptEnd': 3.02,
      'end': 3.02,
      'part': 1,
      'transcript': 'Honestly, two days feel rather brief when there are household tasks and errands to complete. A three-day weekend would provide a much more balanced routine.',
    },
    {
      'question': 'How important do you think it is to have free time at the weekends? [Why?]',
      'audioAsset': 'q4.mp3',
      'duration': 5.04,
      'start': 0.0,
      'promptEnd': 5.04,
      'end': 5.04,
      'part': 1,
      'transcript': 'Having free time at the weekend is crucial for mental recuperation. It helps reduce stress, prevents burnout, and gives people space to nurture personal hobbies and family relationships.',
    },

    // Part 2: Question 5 (Cue Card in q5.mp3)
    {
      'question': 'Describe a time when you used information for tourists, for example from a guidebook or online.',
      'audioAsset': 'q5.mp3',
      'duration': 6.53,
      'start': 0.0,
      'promptEnd': 6.53,
      'end': 6.53,
      'part': 2,
      'youShouldSay': [
        'what information you needed',
        'where you found this information',
        'how you used this information',
        'and explain whether this information was helpful or not.'
      ],
      'transcript': 'Last summer, when I traveled to Kyoto, I relied heavily on an online travel blog and the official tourist portal. I needed up-to-date guidance on public bus routes and scenic cultural spots. The information was exceptionally helpful because it provided step-by-step navigation and recommended visiting certain temples early in the morning to avoid large tourist crowds.',
    },

    // Part 3: Questions 6-11 (in q6.mp3 - q11.mp3)
    {
      'question': 'What are the most popular kinds of holidays for people from your country to go on?',
      'audioAsset': 'q6.mp3',
      'duration': 5.33,
      'start': 0.0,
      'promptEnd': 5.33,
      'end': 5.33,
      'part': 3,
      'transcript': 'In my country, beach holidays and cultural city breaks are the most popular. Many families enjoy visiting coastal resorts for relaxation, while younger travelers often favor exploring vibrant urban centers with rich historical heritage.',
    },
    {
      'question': 'Do you think most people prefer to have a holiday abroad rather than in their own country?',
      'audioAsset': 'q7.mp3',
      'duration': 5.54,
      'start': 0.0,
      'promptEnd': 5.54,
      'end': 5.54,
      'part': 3,
      'transcript': 'It depends on personal interests and budget. Traveling abroad offers exciting opportunities to experience different cultures and languages, but domestic vacations are often more accessible, affordable, and less logistically complex.',
    },
    {
      'question': 'Why do some people want to do absolutely nothing when they go away on holiday?',
      'audioAsset': 'q8.mp3',
      'duration': 5.04,
      'start': 0.0,
      'promptEnd': 5.04,
      'end': 5.04,
      'part': 3,
      'transcript': 'Many people lead intense, high-stress professional lives, so their primary motivation during a holiday is total mental and physical decompression. Simply lounging by a pool or resting without scheduled commitments helps restore their mental well-being.',
    },
    {
      'question': 'What are the kinds of tourist attractions that visitors to your country like to see?',
      'audioAsset': 'q9.mp3',
      'duration': 4.73,
      'start': 0.0,
      'promptEnd': 4.73,
      'end': 4.73,
      'part': 3,
      'transcript': 'Visitors are usually drawn to our ancient historical landmarks, national museums, and picturesque national parks. These attractions showcase our unique cultural heritage and stunning natural scenery.',
    },
    {
      'question': 'Do you think tourist attractions such as museums should be free for local people to visit?',
      'audioAsset': 'q10.mp3',
      'duration': 5.74,
      'start': 0.0,
      'promptEnd': 5.74,
      'end': 5.74,
      'part': 3,
      'transcript': 'Yes, I believe public museums and galleries should be free for local residents because they serve an educational purpose and promote cultural literacy. They can be financed through modest ticket fees for international tourists and government grants.',
    },
    {
      'question': 'What can make a tourist attraction disappointing for visitors?',
      'audioAsset': 'q11.mp3',
      'duration': 3.74,
      'start': 0.0,
      'promptEnd': 3.74,
      'end': 3.74,
      'part': 3,
      'transcript': 'Severe overcrowding, excessive commercialization, and poor maintenance can ruin a visitor\'s experience. When an attraction feels overly transactional or does not match its marketing promises, tourists often feel dissatisfied.',
    },
  ];

  /// Dynamically resolves the questions based on the currently selected test
  List<Map<String, dynamic>> get _activeQuestions {
    if (_selectedTestTitle.contains('Book 10 Test 2')) {
      return _book10Test2Questions;
    } else if (_selectedTestTitle.contains('Book 10 Test 1')) {
      return _book10Test1Questions;
    } else if (_selectedTestTitle.contains('Book 21 Test 1')) {
      return _book21Test1Questions;
    }
    return _book10Test2Questions;
  }

  /// Backward-compatible alias for any legacy references
  List<Map<String, dynamic>> get _examinerQuestions => _activeQuestions;

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
    if (!folderName.contains('BOOK 10 Test 1') &&
        !folderName.contains('BOOK 10 Test 2') &&
        !folderName.contains('BOOK 21 Test 1')) {
      folderName = 'IELTS BOOK 10 Test 1';
    }

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
    _isAudioSeeking = true;
    try {
      await _flutterTts.stop();
      await _audioPlayer!.stop();
      await _audioPlayer!.setVolume(1.0);
      await _audioPlayer!.setPlaybackRate(1.0);
      
      bool played = false;
      final startPos = Duration(milliseconds: (startSec * 1000).toInt());

      try {
        if (startPos > Duration.zero) {
          await _audioPlayer!.play(AssetSource(audioAsset), position: startPos);
          await _audioPlayer!.seek(startPos);
        } else {
          await _audioPlayer!.play(AssetSource(audioAsset));
        }
        _isAudioSeeking = false;
        played = true;
      } catch (e1) {
        debugPrint('Primary play($audioAsset) failed: $e1, trying with assets/ prefix');
        try {
          if (startPos > Duration.zero) {
            await _audioPlayer!.play(AssetSource('assets/$audioAsset'), position: startPos);
            await _audioPlayer!.seek(startPos);
          } else {
            await _audioPlayer!.play(AssetSource('assets/$audioAsset'));
          }
          _isAudioSeeking = false;
          played = true;
        } catch (e2) {
          debugPrint('Secondary play(assets/$audioAsset) failed: $e2');
        }
      }

      _isAudioSeeking = false;
      if (!played) {
        debugPrint('Audio playback failed for "$text", falling back to TTS');
        await _speakText(text);
      }
    } catch (e) {
      _isAudioSeeking = false;
      debugPrint('Audio playback error: $e, falling back to TTS');
      await _speakText(text);
    }
  }

  @override
  void dispose() {
    _audioPositionSubscription?.cancel();
    _audioPlayerCompleteSubscription?.cancel();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit speaking response.')),
        );
      }
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
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary, size: 16),
          label: const Text('Back', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Speaking Practice',
              style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real IELTS Speaking Tests',
              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
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
                    colors: [AppColors.primary, Color(0xFF134E4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.waves, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Talk with AI',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Practice interactive IELTS speaking with an AI examiner',
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
              style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 17, fontWeight: FontWeight.bold),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLocked ? AppColors.surfaceTint : AppColors.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: isLocked ? AppColors.textSecondaryLight : AppColors.primary,
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
                      color: isLocked ? AppColors.textSecondaryLight : AppColors.textPrimaryLight,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isLocked ? Icons.lock_outline : Icons.chevron_right,
              color: AppColors.textSecondaryLight,
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primary, size: 24),
          onPressed: () {
            _aiSpeakingTimer?.cancel();
            setState(() {
              _currentScreen = 'HOME';
            });
          },
        ),
        title: const Text(
          'Talk with AI',
          style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
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
                            color: AppColors.primary,
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
                            color: isAi ? Colors.white : AppColors.surfaceTint,
                            borderRadius: BorderRadius.circular(16),
                            border: isAi ? Border.all(color: AppColors.cardBorderLight) : Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            msg['content'],
                            style: const TextStyle(
                              color: AppColors.textPrimaryLight,
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
                            color: AppColors.surfaceTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: AppColors.primary, size: 18),
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
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
                        color: _isAiSpeaking ? AppColors.accent : AppColors.textSecondaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isAiSpeaking ? 'AI is speaking...' : 'Tap microphone to speak',
                      style: TextStyle(
                        color: _isAiSpeaking ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
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
                            color: AppColors.accent,
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
                          color: _isAiSpeaking ? AppColors.surfaceTint : AppColors.accent,
                          shape: BoxShape.circle,
                          boxShadow: _isAiSpeaking
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                        ),
                        child: Icon(Icons.mic, color: _isAiSpeaking ? AppColors.textSecondaryLight : Colors.white, size: 28),
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
                          color: AppColors.surfaceTint,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorderLight),
                        ),
                        child: const Icon(Icons.replay, color: AppColors.textSecondaryLight, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Free limit counter
                Text(
                  '$_freeMessagesLeft free messages remaining',
                  style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11),
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => setState(() => _currentScreen = 'HOME'),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary, size: 16),
          label: const Text('Back', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        title: Text(
          _selectedTestTitle,
          style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorderLight),
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
                    style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedPart == 1
                        ? '4-5 minutes'
                        : _selectedPart == 2
                            ? '3-4 minutes'
                            : '4-5 minutes',
                    style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _selectedPart == 1
                        ? 'The examiner asks general questions about familiar topics like home, family, work, studies, and interests.'
                        : _selectedPart == 2
                            ? 'You receive a task card with a topic. You have 1 minute to prepare, then speak for 1-2 minutes.'
                            : 'The examiner asks deeper questions related to Part 2 topic. These require more abstract thinking and opinions.',
                    style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Pro Tips',
                    style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 15, fontWeight: FontWeight.bold),
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
                      color: AppColors.surfaceTint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
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
                                  color: AppColors.textPrimaryLight,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Questions are hidden until you start the speaking session to simulate real test conditions.',
                                style: TextStyle(
                                  color: AppColors.textSecondaryLight,
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
                  backgroundColor: AppColors.accent,
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
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.white70 : AppColors.textSecondaryLight,
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
            const Icon(Icons.lightbulb, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tip,
                style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            _timer?.cancel();
            setState(() {
              _currentScreen = 'TEST_DETAIL';
            });
          },
        ),
        title: const Text('Speaking Workspace', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Practice Mode', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _timerActive ? null : () => setState(() => _mode = 'PRACTICE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mode == 'PRACTICE' ? AppColors.primary : AppColors.surfaceTint,
                            foregroundColor: _mode == 'PRACTICE' ? Colors.white : AppColors.textPrimaryLight,
                            elevation: 0,
                            side: BorderSide(color: _mode == 'PRACTICE' ? AppColors.primary : AppColors.cardBorderLight),
                          ),
                          child: const Text('Practice'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _timerActive ? null : () => setState(() => _mode = 'EXAM'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mode == 'EXAM' ? AppColors.primary : AppColors.surfaceTint,
                            foregroundColor: _mode == 'EXAM' ? Colors.white : AppColors.textPrimaryLight,
                            elevation: 0,
                            side: BorderSide(color: _mode == 'EXAM' ? AppColors.primary : AppColors.cardBorderLight),
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
                  child: Text('No speaking prompts found.', style: TextStyle(color: AppColors.textSecondaryLight)),
                ),
              )
            else ...[
              // Prompt selector dropdown
              DropdownButtonFormField<dynamic>(
                value: _selectedPrompt,
                decoration: InputDecoration(
                  labelText: 'Choose Prompt',
                  labelStyle: const TextStyle(color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorderLight),
                  ),
                ),
                dropdownColor: Colors.white,
                items: _prompts.map((p) {
                  return DropdownMenuItem<dynamic>(
                    value: p,
                    child: Text(
                      p['topic'] ?? 'Speaking Cue Card',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 12),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('CUE CARD DESCRIPTION', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          if (_timerActive)
                            Text(
                              '⏱️ ${_formatTime(_timeLeft)}',
                              style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedPrompt['cueCardText'] ?? '',
                        style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, height: 1.5, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),

                      // Collapsible Tackle Steps Accordion
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorderLight),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: AppColors.primary,
                            collapsedIconColor: AppColors.primary,
                            title: const Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'How to Tackle this Speaking Task (Steps)',
                                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
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
                          style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Enter your custom speaking topic here...',
                            hintStyle: const TextStyle(color: AppColors.textSecondaryLight),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.cardBorderLight),
                            ),
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
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
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
                          style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13),
                          enabled: _timerActive || _mode == 'PRACTICE',
                          decoration: InputDecoration(
                            labelText: 'Your Speaking Response / Transcription',
                            labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.cardBorderLight),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_timerActive)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submitSpeaking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Speaking Band Score',
                        style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.surfaceTint, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                children: [
                                  const Text('EST. BAND', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 9)),
                                  const SizedBox(height: 4),
                                  Text('Band ${_feedback['estimatedBand']}', style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('⭐ What you did well:', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_feedback['wellDone'] ?? '', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                      
                      if (_feedback['mistakes'] != null && (_feedback['mistakes'] as List).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('⚠️ Mistakes & Corrections:', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (_feedback['mistakes'] as List).map((m) => Text('- $m', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12))).toList(),
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Text('📝 High Band Model Answer:', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.surfaceTint, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          _feedback['improvedAnswer'] ?? '',
                          style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, height: 1.5, fontStyle: FontStyle.italic),
                        ),
                      ),
                      
                      if (_feedback['practiceRecommendation'] != null) ...[
                        const SizedBox(height: 16),
                        const Text('📈 Recommendations:', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_feedback['practiceRecommendation'], style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                      ],
                    ],
                  ),
                ),

              // Exam success display
              if (_examSuccess)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.primary, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Exam Submitted Successfully!',
                        style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your response has been logged in Exam Mode for evaluation. You can check details in Attempt History later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _examSuccess = false),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
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

  // --- INTERACTIVE EXAMINER SESSION SCREEN ---
  void _startExaminerSession() async {
    _userResponses.clear();
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
    _audioPositionSubscription?.cancel();
    _audioPositionSubscription = _audioPlayer!.onPositionChanged.listen((position) {
      if (!mounted) return;
      if (_currentScreen == 'EXAMINER_SESSION' && _isExaminerSpeaking && !_isAudioSeeking) {
        final safeIndex = _currentQuestionIndex.clamp(0, _activeQuestions.length - 1);
        final currentQ = _activeQuestions[safeIndex];
        final double startSec = (currentQ['start'] as num).toDouble();
        final double promptEndSec = (currentQ['promptEnd'] as num).toDouble();
        final int posMs = position.inMilliseconds;
        final int startMs = (startSec * 1000).toInt();
        final int endMs = (promptEndSec * 1000).toInt();

        if (posMs >= (endMs - 100) && posMs >= startMs) {
          _audioPlayer!.pause();
          _examinerSpeakingTimer?.cancel();
          setState(() {
            _isExaminerSpeaking = false;
          });
        }
      }
    });

    // Completion listener when question audio finishes playing
    _audioPlayerCompleteSubscription?.cancel();
    _audioPlayerCompleteSubscription = _audioPlayer!.onPlayerComplete.listen((_) {
      if (!mounted) return;
      if (_currentScreen == 'EXAMINER_SESSION' && _isExaminerSpeaking) {
        _examinerSpeakingTimer?.cancel();
        setState(() {
          _isExaminerSpeaking = false;
        });
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

    // 1. Safety fallback timer: cancelled if onPositionChanged triggers first
    _examinerSpeakingTimer?.cancel();
    _examinerSpeakingTimer = Timer(Duration(milliseconds: promptDurationMs + 1500), () {
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
                // Warning icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.accent,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'End Test?',
                  style: TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to end this test?\nYour progress will be lost.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    // Left Button: End Test
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
                          backgroundColor: AppColors.surfaceTint,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'End Test',
                          style: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right Button: Continue
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
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
      const Color(0xFF0F766E), const Color(0xFF14B8A6), const Color(0xFFF97316), const Color(0xFF10B981),
      const Color(0xFF0F766E), const Color(0xFF14B8A6), const Color(0xFFF97316), const Color(0xFF10B981),
      const Color(0xFF0F766E), const Color(0xFF14B8A6), const Color(0xFFF97316), const Color(0xFF10B981),
      const Color(0xFF0F766E), const Color(0xFF14B8A6), const Color(0xFFF97316), const Color(0xFF10B981),
      const Color(0xFF0F766E), const Color(0xFF14B8A6), const Color(0xFFF97316), const Color(0xFF10B981)
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                    icon: const Icon(Icons.close, color: AppColors.primary, size: 28),
                    onPressed: _showEndTestDialog,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: (_isRecording || _isExaminerSpeaking) ? AppColors.accent : AppColors.textSecondaryLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(_sessionTime),
                          style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.bold),
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
                          border: Border.all(color: AppColors.cardBorderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
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
                                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isExaminerSpeaking ? 'Speaking' : _isRecording ? 'Recording' : 'Idle',
                                    style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Question Title Banner with Replay Audio Button
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceTint,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Q${_currentQuestionIndex + 1}: ${currentQ['question']}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textPrimaryLight,
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
                                          border: Border.all(color: AppColors.cardBorderLight),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'You should say:',
                                              style: TextStyle(
                                                color: AppColors.textSecondaryLight,
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
                                                      style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        bullet.toString(),
                                                        style: const TextStyle(
                                                          color: AppColors.textPrimaryLight,
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
                                        _playCurrentQuestion();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.volume_up, size: 16, color: AppColors.primary),
                                            SizedBox(width: 6),
                                            Text(
                                              'Tap to Listen / Replay Audio',
                                              style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
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
                                    color: AppColors.surfaceTint,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.cardBorderLight),
                                  ),
                                  child: Text(
                                    _recordedText.isEmpty
                                        ? (_isRecording
                                            ? 'Listening to your voice... speak into microphone'
                                            : 'Tap microphone below to record answer')
                                        : _recordedText,
                                    style: TextStyle(
                                      color: _recordedText.isEmpty ? AppColors.textSecondaryLight : AppColors.textPrimaryLight,
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
                                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
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
                                style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, fontWeight: FontWeight.w500),
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
                              border: Border.all(color: AppColors.primary, width: 3),
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
                              backgroundColor: AppColors.surfaceTint,
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
                              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.circle, color: AppColors.primary, size: 10),
                                SizedBox(width: 8),
                                Icon(Icons.circle, color: AppColors.primary, size: 10),
                                SizedBox(width: 8),
                                Icon(Icons.circle, color: AppColors.primary, size: 10),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        _isRecording ? 'Recording your answer...' : 'Tap the microphone to answer',
                        style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
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
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.35),
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
                        style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11),
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

    final partQuestions = _getQuestionsForSelectedPart();
    final StringBuffer formattedQA = StringBuffer();
    final combinedTranscription = _userResponses.join(' ');
    final int wordCountTotal = combinedTranscription.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final int avgWordsPerQuestion = _userResponses.isEmpty ? 0 : (wordCountTotal / _userResponses.length).round();

    for (int i = 0; i < partQuestions.length; i++) {
      final qText = partQuestions[i]['question'] ?? 'Question ${i + 1}';
      final userAns = (i < _userResponses.length) ? _userResponses[i].trim() : '';
      formattedQA.writeln('Question ${i + 1}: $qText');
      formattedQA.writeln('Student Spoken Response: ${userAns.isEmpty ? "[No response recorded / Candidate was silent]" : userAns}\n');
    }

    try {
      final response = await _apiService.request(
        path: '/content/speaking/submit',
        method: 'POST',
        body: jsonEncode({
          'promptId': _selectedPrompt != null ? _selectedPrompt['id'] : 'PRACTICE_SESSION',
          'audioUrl': 'https://placeholder.url/audio.mp3',
          'transcription': formattedQA.toString(),
          'customQuestionText': '$_selectedTestTitle - Part $_selectedPart',
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
        } else if (feedback['estimatedBand'] != null) {
          overallBand = (feedback['estimatedBand'] as num).toDouble();
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

        final perQFeedback = (feedback['perQuestionFeedback'] as List?) ?? [];
        final tipsList = (feedback['tips'] as List?)?.map((t) => t.toString()).toList() ?? [];
        final mistakesList = (feedback['mistakes'] as List?)?.map((m) => m.toString()).toList() ?? [];

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
            'perQuestionFeedback': perQFeedback,
            'tips': tipsList,
            'mistakes': mistakesList,
            'improvedAnswer': feedback['improvedAnswer'],
            'whyBetter': feedback['whyBetter'],
          };
          _isAnalyzingResults = false;
          _currentScreen = 'EXAMINER_RESULTS';
        });

        final attemptDetails = _buildSpeakingAttemptDetails(
          band: overallBand,
          examinerResults: _examinerResults!,
          tipsList: tipsList,
          perQFeedback: perQFeedback,
          partQuestions: partQuestions,
        );

        HistoryScreen.recordAttempt(
          title: _selectedTestTitle,
          module: 'Speaking',
          score: overallBand,
          details: attemptDetails,
          timestamp: DateTime.now(),
        );
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
      final bool hasNoSpokenWords = wordCountTotal == 0;
      final bool isBrief = avgWordsPerQuestion < 5;

      String fluencyFeedback;
      String lexicalFeedback;
      String grammarFeedback;
      String pronunciationFeedback;

      if (hasNoSpokenWords) {
        fluencyFeedback = 'No verbal response was detected during the practice session. You must speak into the microphone to receive an IELTS speaking assessment.';
        lexicalFeedback = 'No vocabulary was used during this attempt to evaluate lexical resource.';
        grammarFeedback = 'No grammatical structures were spoken.';
        pronunciationFeedback = 'No speech was recorded to assess pronunciation and intonation.';
      } else if (isBrief) {
        fluencyFeedback = 'Your spoken responses were brief (averaging ~$avgWordsPerQuestion words per question). In an IELTS speaking test, you must elaborate with supporting reasons and personal examples.';
        lexicalFeedback = 'Vocabulary range was limited ($wordCountTotal total words). Try to avoid isolated words or fragments and introduce more descriptive phrases.';
        grammarFeedback = 'Responses consisted mostly of short phrases. Focus on forming full subject-verb-object sentences.';
        pronunciationFeedback = 'Speech was detected, but extended sentences are required to evaluate natural rhythm and intonation patterns.';
      } else {
        fluencyFeedback = 'Good speech delivery with an average of ~$avgWordsPerQuestion words per question. Continue expanding your ideas with transitional connectors.';
        lexicalFeedback = 'Appropriate functional vocabulary used ($wordCountTotal total words). To achieve Band 7+, incorporate more topic-specific synonyms and idiomatic collocations.';
        grammarFeedback = 'Good control of basic sentence patterns. Practice using varied compound and complex structures.';
        pronunciationFeedback = 'Clear speech articulation and comprehensible delivery.';
      }

      setState(() {
        _examinerResults = {
          'overallBand': band,
          'fluency': {
            'score': intBand,
            'feedback': fluencyFeedback,
          },
          'lexical': {
            'score': intBand,
            'feedback': lexicalFeedback,
          },
          'grammar': {
            'score': intBand,
            'feedback': grammarFeedback,
          },
          'pronunciation': {
            'score': intBand,
            'feedback': pronunciationFeedback,
          },
        };
        _isAnalyzingResults = false;
        _currentScreen = 'EXAMINER_RESULTS';
      });

      final attemptDetails = _buildSpeakingAttemptDetails(
        band: band,
        examinerResults: _examinerResults!,
        tipsList: [],
        perQFeedback: [],
        partQuestions: partQuestions,
      );

      HistoryScreen.recordAttempt(
        title: _selectedTestTitle,
        module: 'Speaking',
        score: band,
        details: attemptDetails,
        timestamp: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> _buildSpeakingAttemptDetails({
    required double band,
    required Map<String, dynamic> examinerResults,
    required List<String> tipsList,
    required List<dynamic> perQFeedback,
    required List<Map<String, dynamic>> partQuestions,
  }) {
    final List<Map<String, dynamic>> dynamicMistakes = [];
    final List<Map<String, dynamic>> dynamicResponses = [];

    final int count = _userResponses.isEmpty ? partQuestions.length : _userResponses.length;
    for (int i = 0; i < count && i < partQuestions.length; i++) {
      final q = partQuestions[i];
      final String qTitle = q['question'] ?? 'Question ${i + 1}';
      final String userAns = (i < _userResponses.length) ? _userResponses[i].trim() : '';

      String wrongStr = userAns.isEmpty ? 'No verbal response recorded' : userAns;
      String correctStr = '';
      String critiqueStr = '';

      if (i < perQFeedback.length && perQFeedback[i] is Map) {
        final item = perQFeedback[i] as Map;
        if (item['improvedAnswer'] != null && item['improvedAnswer'].toString().trim().isNotEmpty) {
          correctStr = item['improvedAnswer'].toString().trim();
        }
        if (item['critique'] != null) {
          critiqueStr = item['critique'].toString().trim();
        }
      }

      if (correctStr.isEmpty) {
        correctStr = _fineTuneStudentAnswer(userAns, q);
      }

      dynamicMistakes.add({
        'question': qTitle,
        'wrong': wrongStr,
        'correct': correctStr,
        if (critiqueStr.isNotEmpty) 'critique': critiqueStr,
      });

      final int words = userAns.isEmpty ? 0 : userAns.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      dynamicResponses.add({
        'questionNumber': 'Q${i + 1}',
        'questionText': qTitle,
        'answer': userAns.isEmpty ? 'No verbal response recorded' : userAns,
        'wordCount': words,
      });
    }

    final finalTips = tipsList.isNotEmpty
        ? tipsList
        : _generateDynamicTips(_userResponses, _selectedPart);

    return {
      'overallBand': band,
      'fluency': examinerResults['fluency'],
      'lexical': examinerResults['lexical'],
      'grammar': examinerResults['grammar'],
      'pronunciation': examinerResults['pronunciation'],
      'tips': finalTips,
      'mistakes': dynamicMistakes,
      'responses': dynamicResponses,
    };
  }

  // --- SCREEN: TEST COMPLETE (Image 1 & 2) ---
  Widget _buildTestCompleteScreen() {
    final bool isPart3Done = _selectedPart == 3 || _currentQuestionIndex >= 5;
    final bool isPart2Done = !isPart3Done && (_selectedPart == 2 || _currentQuestionIndex == 4);

    final String partCompletedText = isPart3Done
        ? 'Part 3 completed!'
        : (isPart2Done ? 'Part 2 completed!' : 'Part 1 completed!');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                    border: Border.all(color: AppColors.cardBorderLight),
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
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        partCompletedText,
                        style: const TextStyle(
                          color: AppColors.primary,
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
                                side: const BorderSide(color: AppColors.primary, width: 1.8),
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
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Analyzing...',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'See Results',
                                          style: TextStyle(
                                            color: AppColors.primary,
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
                                    } else {
                                      _selectedPart = 2;
                                    }
                                  });
                                  _startExaminerSession();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
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
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textSecondaryLight,
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _selectedPart == 3 ? 'AI Feedback' : 'Part ${_selectedPart == 2 ? '2' : '1'} Results',
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
                    _currentScreen = 'TEST_COMPLETE';
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
              _selectedPart == 3 ? 'Speaking Score' : 'Part ${_selectedPart == 2 ? '2' : '1'} Score',
              style: const TextStyle(
                color: AppColors.textPrimaryLight,
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

  List<String> _generateDynamicTips(List<String> responses, int part) {
    final int totalWords = responses.fold(0, (sum, r) {
      return sum + r.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    });
    final int nonBlankCount = responses.where((r) => r.trim().isNotEmpty).length;
    final double avgWords = nonBlankCount == 0 ? 0 : totalWords / nonBlankCount;

    if (totalWords == 0) {
      return [
        'No verbal response was detected during the recording session. Please ensure microphone access is enabled and speak clearly throughout each prompt.',
        'Practice speaking aloud without hesitation to build confidence and muscle memory for the IELTS Speaking test.',
        'Aim to speak for the full allotted time: 15-30 seconds for Part 1 questions, and 1 to 2 minutes for Part 2.',
        'Read questions carefully and take a brief breath before beginning your response.',
      ];
    } else if (avgWords < 5) {
      return [
        'Expand your responses beyond one-word answers or short phrases. IELTS Speaking requires full, developed thoughts.',
        'Use the \'ARE\' structure: Answer directly, provide a Reason, and give a personal or realistic Example.',
        'Incorporate cohesive connectors such as \'for instance\', \'in particular\', and \'on top of that\' to link ideas.',
        'Avoid simple confirmations like \'yes\' or \'no\'; always explain your viewpoint to demonstrate vocabulary depth.',
      ];
    } else if (avgWords < 15) {
      return [
        'Good foundation in your answers! To reach Band 7.0+, develop your ideas with contrasting perspectives (e.g. \'While some argue that...\').',
        'Incorporate more varied, topic-specific vocabulary and idiomatic collocations.',
        'Practice using complex sentence structures, including conditional clauses and relative pronouns.',
        'Maintain a steady, natural rhythm and avoid extended hesitation when searching for vocabulary.',
      ];
    } else {
      return [
        'Excellent answer development and fluency! Keep maintaining this high level of detail across all parts.',
        'Focus on subtle nuances in pronunciation, sentence stress, and intonation to convey emphasis effectively.',
        'Ensure seamless cohesion across complex explanations, transitioning smoothly between contrasting points.',
        'Review advanced lexical items and formal idioms to consistently achieve Band 8.5 to 9.0.',
      ];
    }
  }

  Widget _buildImprovementTipsSection() {
    final aiTips = (_examinerResults?['tips'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final List<String> tips = aiTips.isNotEmpty
        ? aiTips
        : _generateDynamicTips(_userResponses, _selectedPart);

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

  String _fineTuneStudentAnswer(String userAns, Map<String, dynamic> q) {
    final String clean = userAns.trim();
    final String qText = ((q['question'] as String?) ?? '').toLowerCase();

    // 1. Silent / No response fallback
    if (clean.isEmpty || clean.toLowerCase() == 'no verbal response recorded') {
      if (qText.contains('types of music')) {
        return 'I enjoy listening to an eclectic variety of music genres, particularly pop and acoustic melodies. Upbeat pop tracks keep me motivated during busy work days, while softer acoustic tunes allow me to unwind peacefully in the evenings.';
      } else if (qText.contains('times of day')) {
        return 'I predominantly listen to music first thing in the morning and during my daily commute. Having cheerful music playing sets an optimistic tone for my morning tasks and helps me decompress after hours of work.';
      } else if (qText.contains('musical instrument')) {
        return 'Yes, I actually had the opportunity to learn the piano while in primary school. Although consistent practice was challenging at that young age, acquiring basic musical literacy was an exceptionally rewarding experience.';
      } else if (qText.contains('weekends')) {
        return 'I generally spend my weekends striking a balance between rejuvenating rest and personal productivity. I allocate Saturday mornings to personal chores and use Sunday afternoons to socialize with close friends and family.';
      } else if (qText.contains('free time')) {
        return 'Free time is undeniably vital for maintaining optimal mental health. Without regular periods of downtime to disconnect from professional obligations, individuals inevitably succumb to fatigue and chronic burnout.';
      }
      return (q['transcript'] as String?) ?? 'In response to this question, I would present a direct answer followed by supporting details, personal examples, and a clear concluding rationale.';
    }

    // 2. Personalize and fine-tune what the candidate ACTUALLY said
    final String lower = clean.toLowerCase();

    // Single words or simple confirmations
    if (lower == 'yes' || lower == 'yeah' || lower == 'yep') {
      return 'Yes, absolutely. In my perspective, this plays a fundamental role because it allows individuals to cultivate broader life skills and develop a deeper sense of self-discipline.';
    }
    if (lower == 'no' || lower == 'nope') {
      return 'No, I cannot honestly say that I do. From my standpoint, there are far more practical and engaging alternatives that cater better to personal preferences.';
    }
    if (lower == 'ok' || lower == 'okay') {
      return 'I completely acknowledge that perspective. However, when examining the issue closely, one must consider both the underlying advantages and potential drawbacks before arriving at a definitive conclusion.';
    }

    // If candidate spoke about music genres
    if (qText.contains('types of music') || qText.contains('music')) {
      return 'To be completely honest, I have always gravitated toward $clean. I find that this genre possesses an invigorating rhythm that consistently elevates my mood and provides an instant boost of creative energy throughout the day.';
    }

    // If candidate answered about time of day
    if (qText.contains('times of day') || qText.contains('when')) {
      return 'Without hesitation, I would say that $clean is my preferred time. Tuning in at that point provides a much-needed mental break and establishes a tranquil atmosphere to reflect and recharge.';
    }

    // If candidate answered about shopping / places / tourists
    if (qText.contains('shop') || qText.contains('tourist') || qText.contains('place') || qText.contains('holiday')) {
      final String formatted = clean.endsWith('.') ? clean.substring(0, clean.length - 1) : clean;
      return 'I distinctly recall that $formatted. It was a remarkably memorable experience that offered genuine insight and convenience, leaving a thoroughly positive impression on me.';
    }

    // General response fine-tuning: elevate their own phrase into Band 8.5-9.0 syntax
    String userPhrase = clean.endsWith('.') ? clean.substring(0, clean.length - 1) : clean;
    if (userPhrase.isNotEmpty) {
      userPhrase = userPhrase[0].toUpperCase() + userPhrase.substring(1);
    }

    final int wordCount = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount >= 10) {
      return '$userPhrase. Furthermore, this has had a profound impact on my perspective, and I consider it to be of paramount importance for anyone in a similar position.';
    } else {
      return 'Speaking from personal experience, $userPhrase. In my view, this is an essential consideration because it directly enhances personal well-being and daily effectiveness.';
    }
  }

  Widget _buildYourMistakesSection() {
    final List<Map<String, String>> dynamicMistakes = [];
    final partQuestions = _getQuestionsForSelectedPart();
    final List perQFeedback = (_examinerResults?['perQuestionFeedback'] as List?) ?? [];

    final int count = _userResponses.isEmpty ? partQuestions.length : _userResponses.length;
    for (int i = 0; i < count && i < partQuestions.length; i++) {
      final q = partQuestions[i];
      final String qTitle = q['question'] ?? 'Question ${i + 1}';
      final String userAns = (i < _userResponses.length) ? _userResponses[i].trim() : '';

      String wrongStr = userAns.isEmpty ? 'No verbal response recorded' : userAns;
      String correctStr = '';
      String critiqueStr = '';

      // Check if AI provided per-question upgraded answer
      if (i < perQFeedback.length && perQFeedback[i] is Map) {
        final item = perQFeedback[i] as Map;
        if (item['improvedAnswer'] != null && item['improvedAnswer'].toString().trim().isNotEmpty) {
          correctStr = item['improvedAnswer'].toString().trim();
        }
        if (item['critique'] != null) {
          critiqueStr = item['critique'].toString().trim();
        }
      }

      if (correctStr.isEmpty) {
        correctStr = _fineTuneStudentAnswer(userAns, q);
      }

      dynamicMistakes.add({
        'question': qTitle,
        'wrong': wrongStr,
        'correct': correctStr,
        'critique': critiqueStr,
      });
    }

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
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_fix_high,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Fine-Tuned Band 8.5–9.0 Answers',
                  style: TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Your actual spoken words upgraded with high-band vocabulary and complex structures:',
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(dynamicMistakes.length, (i) {
            final item = dynamicMistakes[i];
            final String displayWrong = item['wrong'] ?? '';
            final String critique = item['critique'] ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Q${i + 1}',
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
                          item['question']!,
                          style: const TextStyle(
                            color: AppColors.textPrimaryLight,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // What You Said (Red tint container)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mic_none, size: 15, color: Color(0xFFDC2626)),
                            const SizedBox(width: 6),
                            const Text(
                              'What You Said',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (displayWrong.isNotEmpty && displayWrong != 'No verbal response recorded')
                              Text(
                                '${displayWrong.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayWrong,
                          style: TextStyle(
                            color: displayWrong == 'No verbal response recorded' ? const Color(0xFF991B1B) : const Color(0xFF7F1D1D),
                            fontSize: 13,
                            height: 1.4,
                            fontStyle: displayWrong == 'No verbal response recorded' ? FontStyle.italic : FontStyle.normal,
                            decoration: (displayWrong.isNotEmpty && displayWrong != 'No verbal response recorded') ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Band 8.5-9.0 Fine-Tuned Version (Green tint container)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 15, color: Color(0xFF16A34A)),
                            SizedBox(width: 6),
                            Text(
                              'Band 8.5–9.0 Fine-Tuned Answer',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['correct']!,
                          style: const TextStyle(
                            color: Color(0xFF14532D),
                            fontSize: 13.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (critique.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Examiner Note: $critique',
                              style: const TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (i < dynamicMistakes.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Divider(color: AppColors.cardBorderLight),
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
                      responseText.isEmpty ? 'No response recorded' : responseText,
                      style: TextStyle(
                        color: responseText.isEmpty ? AppColors.textSecondaryLight : AppColors.textPrimaryLight,
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
    if (dotColorHex == 'green') dotColor = const Color(0xFF059669); // Minty green

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
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 90,
            height: 3.5,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

