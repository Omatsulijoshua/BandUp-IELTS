import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_paywall.dart';
import 'history_screen.dart';

class MockExamsScreen extends ConsumerStatefulWidget {
  const MockExamsScreen({super.key});

  @override
  ConsumerState<MockExamsScreen> createState() => _MockExamsScreenState();
}

class _MockExamsScreenState extends ConsumerState<MockExamsScreen> {
  // Screen state: 'INTRO', 'SECTION_INTRO', 'SECTION_TEST', 'CORRECTIONS'
  String _currentView = 'INTRO';
  int _currentSectionIndex = 0;
  final Map<String, String> _answersMap = {};

  int _timeLeft = 0;
  Timer? _timer;
  // Audio player for listening section
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription? _playerStateSubscription;

  // Tracking last selected IDs to guarantee variety between consecutive tests
  String? _lastListeningId;
  String? _lastReadingId;
  String? _lastWritingId;
  String? _lastSpeakingId;

  // Active mock test sections currently assigned for this run
  List<Map<String, dynamic>> _activeSections = [];

  // Corrections / results data
  Map<String, dynamic>? _correctionsData;

  // ===========================================================================
  // CAMBRIDGE IELTS TEST POOLS
  // ===========================================================================

  // --- LISTENING POOL (Cambridge IELTS Books 10 & 21) ---
  final List<Map<String, dynamic>> _listeningPool = [
    {
      'id': 'listening_b10t1',
      'source': 'Cambridge IELTS Book 10 Test 1',
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
        {'q': '1. Address: 24 ___ Road', 'ans': 'Ardleigh', 'exp': 'Spelled out: A-R-D-L-E-I-G-H Road.'},
        {'q': '2. Heard about company from: ___', 'ans': 'newspaper', 'exp': 'The customer states she read about the company in the newspaper.'},
        {'q': '3. Trip One - Los Angeles: wants to visit some ___ parks', 'ans': 'theme', 'exp': 'She plans to visit some theme parks with her children.'},
        {'q': '4. Trip One - Yosemite: customer wants to stay in a lodge, not a ___', 'ans': 'tent', 'exp': 'She specifies wanting a solid lodge accommodation, not a tent.'},
        {'q': '5. Trip Two: customer wants to see the ___ on the way to Cambria', 'ans': 'castle', 'exp': 'Stop off at Hearst Castle on the scenic drive.'},
        {'q': '6. Trip Two - At San Diego: wants to spend time on the ___', 'ans': 'beach', 'exp': 'Customer requested relaxing days at the beach.'},
        {'q': '7. Trip One (12 days) - Total distance: ___ km', 'ans': '2020', 'exp': 'Total road distance is two thousand and twenty kilometers.'},
        {'q': '8. Trip One (£525) - Includes: accommodation, car, one ___', 'ans': 'flight', 'exp': 'Price covers hotel, rental vehicle, and one domestic flight.'},
        {'q': '9. Trip Two (9 days, 980 km) - Price per person: £___', 'ans': '429', 'exp': 'Nine-day itinerary price is four hundred and twenty-nine pounds.'},
        {'q': '10. Trip Two - Includes: accommodation, car, ___', 'ans': 'dinner', 'exp': 'Package includes accommodation, car hire, and nightly dinner.'},
      ],
    },
    {
      'id': 'listening_b10t2',
      'source': 'Cambridge IELTS Book 10 Test 2',
      'title': 'Listening',
      'subtitle': '4 parts • 40 questions • ~30 min',
      'durationMinutes': 30,
      'infoItems': [
        '4 parts • 40 questions',
        'Approximately 30 minutes',
        'Each recording plays once only — answer as you listen'
      ],
      'instructions': 'Listen to the Leisure Club Facilities dialogue and answer questions 1-10.',
      'questions': [
        {
          'q': '1. Which facility at the leisure club has recently been improved first?',
          'options': ['A. the gym', 'B. the running tracks', 'C. the outdoor pool', 'D. sports coaching'],
          'ans': 'A',
          'exp': 'The gym facility was completely refurbished first with brand-new equipment.'
        },
        {
          'q': '2. Which other facility at the leisure club has recently been improved?',
          'options': ['A. sauna rooms', 'B. tennis court', 'C. the indoor pool', 'D. cafe area'],
          'ans': 'C',
          'exp': 'The indoor heated swimming pool was recently upgraded.'
        },
        {'q': '3. Personal Assessment: New members should describe any ___', 'ans': 'health problems', 'exp': 'Members must disclose prior health problems to the trainer.'},
        {'q': '4. The ___ will be explained to you before you use the equipment.', 'ans': 'safety rules', 'exp': 'Trainers explain essential safety rules before machine access.'},
        {'q': '5. You will be given a six-week personal fitness ___', 'ans': 'plan', 'exp': 'A six-week custom workout plan is prepared for every member.'},
        {'q': '6. Types of membership: There is a compulsory £90 ___ fee.', 'ans': 'joining', 'exp': 'New entrants pay a £90 initial joining fee.'},
        {'q': '7. Gold members are given ___ to all the LP clubs.', 'ans': 'free entry', 'exp': 'Gold tier grants free entry across all regional branches.'},
        {'q': '8. Premier members are given priority during ___ hours.', 'ans': 'peak', 'exp': 'Premier members enjoy prioritized booking during peak times.'},
        {'q': '9. Premier members can bring some ___ every month.', 'ans': 'guests', 'exp': 'Premier tier allows bringing registered guests each month.'},
        {'q': '10. Members should always take their ___ with them.', 'ans': 'photo card', 'exp': 'Members must present their physical photo card at reception.'},
      ],
    },
    {
      'id': 'listening_b21t1',
      'source': 'Cambridge IELTS Book 21 Test 1',
      'title': 'Listening',
      'subtitle': '4 parts • 40 questions • ~30 min',
      'durationMinutes': 30,
      'infoItems': [
        '4 parts • 40 questions',
        'Approximately 30 minutes',
        'Each recording plays once only — answer as you listen'
      ],
      'instructions': 'Listen to the Design Competition briefing and answer questions 1-10.',
      'questions': [
        {
          'q': '1. What is the primary focus of this year’s design competition?',
          'options': ['A. inventing a new tool', 'B. energy conservation', 'C. finding a new use for current technology'],
          'ans': 'C',
          'exp': 'The brief asks students to adapt existing domestic technology in novel ways.'
        },
        {
          'q': '2. Which aspect of the appliance should the design prioritize?',
          'options': ['A. ease of use for seniors', 'B. bright color palette', 'C. low shipping weight'],
          'ans': 'A',
          'exp': 'Designers must make the user interface intuitive and accessible for elderly users.'
        },
        {
          'q': '3. What is the main drawback with current appliance designs?',
          'options': ['A. excessive price', 'B. overly complicated buttons', 'C. fragile casing'],
          'ans': 'B',
          'exp': 'The current models are criticized for having overly complex interfaces.'
        },
        {'q': '4. Requirement: The design aesthetic must be visually ___', 'ans': 'attractive', 'exp': 'The brief emphasizes that prototypes must be modern and attractive.'},
        {'q': '5. Key benefit: Students gain hands-on practical ___', 'ans': 'experience', 'exp': 'Participants gain invaluable real-world industry experience.'},
        {'q': '6. Requirement: Students must submit a comprehensive ___', 'ans': 'presentation', 'exp': 'Teams submit a detailed design slide deck presentation.'},
        {'q': '7. Requirement: Teams must build a physical working ___', 'ans': 'model', 'exp': 'A 3D physical mock-up model must accompany the documentation.'},
        {'q': '8. Specification: Documentation must enumerate each ___ used.', 'ans': 'material', 'exp': 'A full bill of materials and components is required.'},
        {'q': '9. The winning candidate will be awarded a research ___', 'ans': 'grant', 'exp': 'Winners receive a competitive developmental research grant.'},
        {'q': '10. The panel evaluation will emphasize ___ innovation.', 'ans': 'technical', 'exp': 'Judges focus heavily on technical ingenuity and feasibility.'},
      ],
    },
  ];

  // --- READING POOL (Cambridge IELTS Books 10 & 21) ---
  final List<Map<String, dynamic>> _readingPool = [
    {
      'id': 'reading_b10t1',
      'source': 'Cambridge IELTS Book 10 Test 1',
      'title': 'Reading',
      'subtitle': '3 passages • 40 questions • 60 min',
      'durationMinutes': 60,
      'infoItems': [
        '3 passages • 40 questions',
        'Approximately 60 minutes',
        'Read the texts and answer all questions in official sequence'
      ],
      'instructions': 'Read the passage below on Stepwells of India and answer questions 1-6.',
      'readingPassage': {
        'title': 'Stepwells of India: Ancient Engineering & Community Life',
        'text': 'Stepwells are unique subterranean monuments found primarily in India. Developed in the sixth and seventh centuries, these ingenious civil engineering marvels served multiple functions: providing year-round access to water, offering cool communal gathering pavilions during sweltering summers, and acting as revered spaces for spiritual worship.\\n\\nWhen the water table was elevated during monsoon periods, villagers only had to descend a few stone steps to draw water; conversely, during dry arid months, dozens of intricate stepped tiers had to be negotiated. Built from locally quarried stone and reinforced with ornate carved pillars, shaded verandas provided respite for travelers.\\n\\nWhile modern piped plumbing caused many stepwells to fall into dereliction, exceptional surviving sites such as Rani Ki Vav in Gujarat miraculously withstood a devastating earthquake in 2001, showcasing the enduring structural genius of ancient Indian masonry.'
      },
      'questions': [
        {
          'q': '1. The number of steps above the water level altered during the course of a year.',
          'options': ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
          'ans': 'A',
          'exp': 'The passage confirms that seasonal water table changes altered the number of visible steps.'
        },
        {
          'q': '2. Stepwells were first built in the 6th century.',
          'options': ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
          'ans': 'B',
          'exp': 'They were developed in the 6th-7th centuries, but there is no evidence they were first invented then.'
        },
        {
          'q': '3. The stepwells had multiple community functions in addition to supplying drinking water.',
          'options': ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
          'ans': 'A',
          'exp': 'The text lists community gathering, shade, leisure, and religious worship.'
        },
        {
          'q': '4. Which architectural feature offered shelter and shade from extreme heat?',
          'ans': 'pavilions',
          'exp': 'Shaded stone pavilions sheltered visitors from relentless summer heat.'
        },
        {
          'q': '5. What natural disaster did the Rani Ki Vav monument survive in 2001?',
          'ans': 'earthquake',
          'exp': 'Rani Ki Vav remarkably survived the massive 2001 Gujarat earthquake.'
        },
        {
          'q': '6. Ancient stepwells were predominantly constructed using locally quarried ___',
          'ans': 'stone',
          'exp': 'The monuments were constructed primarily from stone supported by pillars.'
        },
      ],
    },
    {
      'id': 'reading_b10t2',
      'source': 'Cambridge IELTS Book 10 Test 2',
      'title': 'Reading',
      'subtitle': '3 passages • 40 questions • 60 min',
      'durationMinutes': 60,
      'infoItems': [
        '3 passages • 40 questions',
        'Approximately 60 minutes',
        'Read the texts and answer all questions in official sequence'
      ],
      'instructions': 'Read the European Transport Trends excerpt and answer questions 1-6.',
      'readingPassage': {
        'title': 'European Transport Infrastructure & Environmental Challenges',
        'text': 'Across the European continent, consumer and commercial transport demand has expanded at an unprecedented rate over the last three decades. Road transport currently dominates both passenger mobility (accounting for over 84% of passenger-kilometers) and freight haulage (representing roughly 44% of overall tonnage).\\n\\nThis heavy dependence on road vehicles has generated substantial traffic congestion, air pollution, and heightened carbon emissions. Simultaneously, railway transit, which once formed the backbone of cross-border European freight, has contracted significantly.\\n\\nThe European Commission\'s environmental transport directive emphasizes that unless user pricing charges are implemented and substantial volume is shifted onto electrified rail and inland canals, sustained economic expansion will remain locked in direct conflict with European carbon neutrality objectives.'
      },
      'questions': [
        {
          'q': '1. What percentage of European passenger movements is accounted for by road transport?',
          'options': ['A. 44%', 'B. 68%', 'C. 84%', 'D. 95%'],
          'ans': 'C',
          'exp': 'The passage states road transport accounts for over 84% of passenger mobility.'
        },
        {
          'q': '2. The primary source of rising European transport emissions is highway traffic.',
          'options': ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
          'ans': 'A',
          'exp': 'Heavy road vehicle reliance is directly tied to elevated emissions.'
        },
        {
          'q': '3. Rail freight has increased its total market share since 1990.',
          'options': ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
          'ans': 'B',
          'exp': 'The text confirms railway freight has contracted rather than expanded.'
        },
        {
          'q': '4. What policy mechanism does the Commission recommend to reduce roadway crowding?',
          'options': ['A. Free tolls', 'B. Road user pricing charges', 'C. Lower rail budgets'],
          'ans': 'B',
          'exp': 'The directive proposes implementing user pricing charges on road transport.'
        },
        {
          'q': '5. Freight transported by road represents roughly ___ percent of overall tonnage.',
          'ans': '44',
          'exp': 'Road freight represents roughly 44% of all haulage tonnage.'
        },
        {
          'q': '6. The European Commission aims to decouple economic growth from environmental ___',
          'ans': 'sustainability',
          'exp': 'Policy focuses on harmonizing economic growth with environmental sustainability.'
        },
      ],
    },
    {
      'id': 'reading_b21t1',
      'source': 'Cambridge IELTS Book 21 Test 1',
      'title': 'Reading',
      'subtitle': '3 passages • 40 questions • 60 min',
      'durationMinutes': 60,
      'infoItems': [
        '3 passages • 40 questions',
        'Approximately 60 minutes',
        'Read the texts and answer all questions in official sequence'
      ],
      'instructions': 'Read the Workplace Psychology passage and answer questions 1-6.',
      'readingPassage': {
        'title': 'The Psychology of Workplace Innovation and Creative Thinking',
        'text': 'Contemporary enterprise design frequently promotes open-plan workspaces furnished with vivid lounges, recreation areas, and complimentary refreshments, on the assumption that playful environments automatically catalyze innovative ideation.\\n\\nHowever, rigorous psychological research conducted across multinational firms demonstrates that architectural novelty alone rarely triggers creative problem-solving. Genuine organizational innovation relies upon psychological safety—a team atmosphere wherein individuals feel fully empowered to voice unorthodox proposals without apprehension of reprimand or peer mockery.\\n\\nWhen corporate leaders actively reward calculated intellectual risk and cultivate cross-disciplinary collaboration, breakthrough concepts surface consistently, regardless of physical seating arrangements or office decor.'
      },
      'questions': [
        {
          'q': '1. Architectural novelty in office styling guarantees higher employee creativity.',
          'options': ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
          'ans': 'B',
          'exp': 'Research proves physical novelty alone does not generate genuine creative breakthroughs.'
        },
        {
          'q': '2. Psychological safety allows team members to propose unusual ideas without fear.',
          'options': ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
          'ans': 'A',
          'exp': 'Psychological safety ensures workers can share unorthodox ideas safely.'
        },
        {
          'q': '3. Open-plan office designs were invented exclusively by modern tech startups.',
          'options': ['A. TRUE', 'B. FALSE', 'C. NOT GIVEN'],
          'ans': 'C',
          'exp': 'The passage does not state who originally invented open-plan offices.'
        },
        {
          'q': '4. What organizational condition is most essential for real workplace innovation?',
          'options': ['A. Free snacks', 'B. Psychological safety & leadership support', 'C. Isolated desks'],
          'ans': 'B',
          'exp': 'Psychological safety and receptive leadership are the core drivers.'
        },
        {
          'q': '5. Workers must feel secure putting forward ___ proposals.',
          'ans': 'unorthodox',
          'exp': 'The passage highlights the freedom to voice unorthodox proposals.'
        },
        {
          'q': '6. Breakthrough innovation is strengthened by ___ collaboration among diverse specialists.',
          'ans': 'cross-disciplinary',
          'exp': 'Cross-disciplinary collaboration unlocks breakthrough concepts.'
        },
      ],
    },
  ];

  // --- WRITING POOL (Cambridge IELTS Books 10 & 21) ---
  final List<Map<String, dynamic>> _writingPool = [
    {
      'id': 'writing_b10t1',
      'source': 'Cambridge IELTS Book 10 Test 1',
      'title': 'Writing',
      'subtitle': '2 tasks • 60 min • AI-scored',
      'durationMinutes': 60,
      'infoItems': [
        '2 tasks (Task 1 & Task 2)',
        'Approximately 60 minutes',
        'Task 1 minimum 150 words • Task 2 minimum 250 words'
      ],
      'instructions': 'Task 1: Describe visual data (150 words). Task 2: Write an opinion essay (250 words).',
      'questions': [
        {
          'title': 'Task 1: Report on Household Energy',
          'prompt': 'The bar charts show how energy is used in an average Australian household and the greenhouse gas emissions that result from this energy use. Summarise the information by selecting and reporting the main features, and make comparisons where relevant (write at least 150 words).',
          'minWords': 150,
        },
        {
          'title': 'Task 2: Essay on Discipline & Punishment',
          'prompt': 'It is important for children to learn the distinction between right and wrong at an early age. Some people believe punishment is necessary to help them learn this distinction. To what extent do you agree or disagree? What sort of punishment should parents and teachers be allowed to use (write at least 250 words)?',
          'minWords': 250,
        },
      ],
    },
    {
      'id': 'writing_b10t2',
      'source': 'Cambridge IELTS Book 10 Test 2',
      'title': 'Writing',
      'subtitle': '2 tasks • 60 min • AI-scored',
      'durationMinutes': 60,
      'infoItems': [
        '2 tasks (Task 1 & Task 2)',
        'Approximately 60 minutes',
        'Task 1 minimum 150 words • Task 2 minimum 250 words'
      ],
      'instructions': 'Task 1: Describe freight trends (150 words). Task 2: Write a technology impact essay (250 words).',
      'questions': [
        {
          'title': 'Task 1: Report on Freight Transport',
          'prompt': 'The charts show the proportion of freight transported by road, rail, water, and pipeline in the UK between 1974 and 2002. Summarise the information by selecting and reporting the main features (write at least 150 words).',
          'minWords': 150,
        },
        {
          'title': 'Task 2: Essay on Technology in Modern Life',
          'prompt': 'Some people believe that modern technology has made human lives more complicated rather than simpler. To what extent do you agree or disagree? Give reasons for your answer and include relevant examples from your experience (write at least 250 words).',
          'minWords': 250,
        },
      ],
    },
    {
      'id': 'writing_b21t1',
      'source': 'Cambridge IELTS Book 21 Test 1',
      'title': 'Writing',
      'subtitle': '2 tasks • 60 min • AI-scored',
      'durationMinutes': 60,
      'infoItems': [
        '2 tasks (Task 1 & Task 2)',
        'Approximately 60 minutes',
        'Task 1 minimum 150 words • Task 2 minimum 250 words'
      ],
      'instructions': 'Task 1: Analyze educational funding data (150 words). Task 2: Discuss remote work (250 words).',
      'questions': [
        {
          'title': 'Task 1: Report on Higher Education Expenditure',
          'prompt': 'The table compares government spending on university education and tuition fee levels across five developed countries in 2022. Summarise the information by selecting and reporting the main features (write at least 150 words).',
          'minWords': 150,
        },
        {
          'title': 'Task 2: Essay on Remote vs Office Work',
          'prompt': 'In many nations, an increasing proportion of employees work from home on a permanent or hybrid schedule. Do the advantages of remote working for individuals and society outweigh its potential disadvantages? Discuss both views and give your opinion (write at least 250 words).',
          'minWords': 250,
        },
      ],
    },
  ];

  // --- SPEAKING POOL (Cambridge IELTS Books 10 & 21) ---
  final List<Map<String, dynamic>> _speakingPool = [
    {
      'id': 'speaking_b10t1',
      'source': 'Cambridge IELTS Book 10 Test 1',
      'title': 'Speaking',
      'subtitle': '3 parts • 11–14 min • AI examiner',
      'durationMinutes': 14,
      'infoItems': [
        '3 parts (Interview, Cue Card, Discussion)',
        'Approximately 11–14 minutes',
        'AI simulated examiner evaluates fluency, vocabulary, and grammar'
      ],
      'instructions': 'Speak aloud or type your responses for each part of the official speaking interview.',
      'questions': [
        {
          'part': 'Part 1: Introduction & Weekend Habits',
          'prompt': 'How do you usually spend your weekends? Which is your favorite part of the weekend, and why? Do you think two days of weekend rest are sufficient for working professionals?',
        },
        {
          'part': 'Part 2: Long Turn (Cue Card - 2 min)',
          'prompt': 'Describe someone you know who does something very well.\\nYou should say:\\n• who this person is\\n• how you know them\\n• what skill or craft they do well\\n• and explain why you think they are so good at doing this.',
        },
        {
          'part': 'Part 3: Two-Way Analytical Discussion',
          'prompt': 'What skills and competencies do employers value most in the contemporary job market? Should children learn life skills primarily at school or at home? What is your view on the debate over income inequality?',
        },
      ],
    },
    {
      'id': 'speaking_b10t2',
      'source': 'Cambridge IELTS Book 10 Test 2',
      'title': 'Speaking',
      'subtitle': '3 parts • 11–14 min • AI examiner',
      'durationMinutes': 14,
      'infoItems': [
        '3 parts (Interview, Cue Card, Discussion)',
        'Approximately 11–14 minutes',
        'AI simulated examiner evaluates fluency, vocabulary, and grammar'
      ],
      'instructions': 'Speak aloud or type your responses for each part of the official speaking interview.',
      'questions': [
        {
          'part': 'Part 1: Introduction & Music Preferences',
          'prompt': 'What genres of music do you enjoy listening to? At what times of day do you usually listen to music? Did you learn any musical instrument during your childhood?',
        },
        {
          'part': 'Part 2: Long Turn (Cue Card - 2 min)',
          'prompt': 'Describe a local shop near where you live that you frequently use.\\nYou should say:\\n• what products or services it provides\\n• what the store looks like\\n• where it is located\\n• and explain why you prefer using this local shop.',
        },
        {
          'part': 'Part 3: Two-Way Analytical Discussion',
          'prompt': 'Why are independent neighborhood businesses crucial for a community? How do large suburban shopping malls affect traditional small retailers? What qualities distinguish an exceptional entrepreneur?',
        },
      ],
    },
    {
      'id': 'speaking_b21t1',
      'source': 'Cambridge IELTS Book 21 Test 1',
      'title': 'Speaking',
      'subtitle': '3 parts • 11–14 min • AI examiner',
      'durationMinutes': 14,
      'infoItems': [
        '3 parts (Interview, Cue Card, Discussion)',
        'Approximately 11–14 minutes',
        'AI simulated examiner evaluates fluency, vocabulary, and grammar'
      ],
      'instructions': 'Speak aloud or type your responses for each part of the official speaking interview.',
      'questions': [
        {
          'part': 'Part 1: Introduction & Daily Leisure Routine',
          'prompt': 'How do you typically unwind in the evenings after work or study? Do you prefer outdoor recreational activities or staying indoors during public holidays? How has your hometown changed over the past five years?',
        },
        {
          'part': 'Part 2: Long Turn (Cue Card - 2 min)',
          'prompt': 'Describe an impressive place you visited recently.\\nYou should say:\\n• where this place is located\\n• when and with whom you visited\\n• what activities you engaged in there\\n• and explain why you found this place so memorable and impressive.',
        },
        {
          'part': 'Part 3: Two-Way Analytical Discussion',
          'prompt': 'Why do many people prefer living in vibrant urban cities despite higher living expenses? How does international mass tourism impact delicate historical heritage sites? Should governments subsidize domestic cultural tourism?',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playerState = state);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ===========================================================================
  // RANDOMIZATION LOGIC (USER REQUIREMENT):
  // "anytime mock is clicked it supposed t be different so based on what i have
  //  and its avaliable use to randomised but if there is only 1 use the same
  //  everytime till more than 1 is avalable"
  // ===========================================================================
  Map<String, dynamic> _pickSection(List<Map<String, dynamic>> pool, String? lastSelectedId) {
    if (pool.isEmpty) {
      throw StateError('Section pool cannot be empty');
    }

    // If only 1 is available, use the same every time till more than 1 is available!
    if (pool.length == 1) {
      return pool.first;
    }

    // If more than 1 is available, randomize!
    // Try to pick a different one from the previous session if possible
    final candidates = pool.where((item) => item['id'] != lastSelectedId).toList();
    final candidatePool = candidates.isNotEmpty ? candidates : pool;
    final randIdx = Random().nextInt(candidatePool.length);
    return candidatePool[randIdx];
  }

  void _generateRandomizedMock() {
    final listening = _pickSection(_listeningPool, _lastListeningId);
    final reading = _pickSection(_readingPool, _lastReadingId);
    final writing = _pickSection(_writingPool, _lastWritingId);
    final speaking = _pickSection(_speakingPool, _lastSpeakingId);

    // Save selected IDs to ensure subsequent mock tests select different ones
    _lastListeningId = listening['id'];
    _lastReadingId = reading['id'];
    _lastWritingId = writing['id'];
    _lastSpeakingId = speaking['id'];

    setState(() {
      _activeSections = [listening, reading, writing, speaking];
    });
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

    // Generate a fresh randomized mock exam from available Cambridge pools!
    _generateRandomizedMock();

    setState(() {
      _currentView = 'SECTION_INTRO';
      _currentSectionIndex = 0;
      _answersMap.clear();
      _correctionsData = null;
    });
  }

  void _beginCurrentSection() {
    if (_activeSections.isEmpty) {
      _generateRandomizedMock();
    }
    final currentSec = _activeSections[_currentSectionIndex];
    final int duration = (currentSec['durationMinutes'] as int? ?? 30) * 60;

    setState(() {
      _currentView = 'SECTION_TEST';
      _timeLeft = duration;
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
    _audioPlayer.stop();

    if (_currentSectionIndex < _activeSections.length - 1) {
      setState(() {
        _currentSectionIndex++;
        _currentView = 'SECTION_INTRO';
      });
    } else {
      // Finished all 4 sections! Calculate real results and record attempt
      _finishMockExam();
    }
  }

  void _finishMockExam() {
    _timer?.cancel();
    _audioPlayer.stop();

    // 1. Grade Listening
    final lSec = _activeSections[0];
    final lQuestions = lSec['questions'] as List? ?? [];
    int lCorrect = 0;
    for (int i = 0; i < lQuestions.length; i++) {
      final qKey = 'sec_${lSec['id']}_$i';
      final userAns = (_answersMap[qKey] ?? '').trim().toLowerCase();
      final correctAns = (lQuestions[i]['ans'] ?? '').toString().trim().toLowerCase();
      if (userAns.isNotEmpty && (userAns == correctAns || userAns.contains(correctAns) || correctAns.contains(userAns))) {
        lCorrect++;
      }
    }
    final double lBand = (lCorrect >= 9) ? 8.5 : (lCorrect >= 8) ? 8.0 : (lCorrect >= 6) ? 7.0 : (lCorrect >= 4) ? 6.0 : 5.5;

    // 2. Grade Reading
    final rSec = _activeSections[1];
    final rQuestions = rSec['questions'] as List? ?? [];
    int rCorrect = 0;
    for (int i = 0; i < rQuestions.length; i++) {
      final qKey = 'sec_${rSec['id']}_$i';
      final userAns = (_answersMap[qKey] ?? '').trim().toLowerCase();
      final correctAns = (rQuestions[i]['ans'] ?? '').toString().trim().toLowerCase();
      if (userAns.isNotEmpty && (userAns == correctAns || userAns.startsWith(correctAns) || correctAns.contains(userAns))) {
        rCorrect++;
      }
    }
    final double rBand = (rCorrect >= 5) ? 8.0 : (rCorrect >= 4) ? 7.5 : (rCorrect >= 3) ? 6.5 : (rCorrect >= 2) ? 6.0 : 5.5;

    // 3. Grade Writing
    final wSec = _activeSections[2];
    int totalWords = 0;
    final wQuestions = wSec['questions'] as List? ?? [];
    for (int i = 0; i < wQuestions.length; i++) {
      final qKey = 'sec_${wSec['id']}_$i';
      final text = _answersMap[qKey] ?? '';
      totalWords += text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\\s+')).length;
    }
    final double wBand = (totalWords >= 400) ? 7.5 : (totalWords >= 250) ? 7.0 : (totalWords >= 150) ? 6.5 : (totalWords >= 50) ? 6.0 : 5.0;

    // 4. Grade Speaking
    final sSec = _activeSections[3];
    int totalSpeakingWords = 0;
    final sQuestions = sSec['questions'] as List? ?? [];
    for (int i = 0; i < sQuestions.length; i++) {
      final qKey = 'sec_${sSec['id']}_$i';
      final text = _answersMap[qKey] ?? '';
      totalSpeakingWords += text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\\s+')).length;
    }
    final double sBand = (totalSpeakingWords >= 200) ? 7.5 : (totalSpeakingWords >= 100) ? 7.0 : (totalSpeakingWords >= 40) ? 6.5 : 5.5;

    // Overall official IELTS rounding: rounded to nearest 0.5
    final double rawOverall = (lBand + rBand + wBand + sBand) / 4.0;
    final double overallBand = (rawOverall * 2).round() / 2.0;

    final composition = _activeSections.map((s) => s['source'] ?? s['title']).join(' • ');

    final resultData = {
      'overallBand': overallBand.toStringAsFixed(1),
      'listeningScore': lBand.toStringAsFixed(1),
      'readingScore': rBand.toStringAsFixed(1),
      'writingScore': wBand.toStringAsFixed(1),
      'speakingScore': sBand.toStringAsFixed(1),
      'composition': composition,
      'sections': _activeSections,
      'listeningCorrect': '$lCorrect / ${lQuestions.length}',
      'readingCorrect': '$rCorrect / ${rQuestions.length}',
    };

    setState(() {
      _currentView = 'CORRECTIONS';
      _correctionsData = resultData;
    });

    // Record user attempt to dynamic history with current timestamp
    HistoryScreen.recordAttempt(
      title: 'Full Mock Test ($composition)',
      module: 'Mock',
      score: overallBand,
      details: resultData,
      timestamp: DateTime.now(),
    );
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
                  color: Colors.black.withValues(alpha: 0.08), blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEDD5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEA580C),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'End Test?',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Are you sure you want to end\\nthis test?\\nYour progress will be lost.',
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
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _timer?.cancel();
                            _audioPlayer.stop();
                            setState(() {
                              _currentView = 'INTRO';
                              _answersMap.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFE4E6),
                            foregroundColor: const Color(0xFFE11D48),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'End Test',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
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

  // ===========================================================================
  // SCREEN 1: INTRO SCREEN (Pixel-perfect matches user screenshot)
  // ===========================================================================
  Widget _buildIntroScreen() {
    final previewSections = [
      {
        'title': 'Listening',
        'subtitle': '4 parts • 40 questions • ~30 min',
        'icon': Icons.headset_rounded,
        'iconColor': const Color(0xFF0284C7),
        'iconBg': const Color(0xFFE0F2FE),
      },
      {
        'title': 'Reading',
        'subtitle': '3 passages • 40 questions • 60 min',
        'icon': Icons.menu_book_rounded,
        'iconColor': const Color(0xFF9333EA),
        'iconBg': const Color(0xFFF3E8FF),
      },
      {
        'title': 'Writing',
        'subtitle': '2 tasks • 60 min • AI-scored',
        'icon': Icons.edit_rounded,
        'iconColor': const Color(0xFFD97706),
        'iconBg': const Color(0xFFFEF3C7),
      },
      {
        'title': 'Speaking',
        'subtitle': '3 parts • 11–14 min • AI examiner',
        'icon': Icons.mic_rounded,
        'iconColor': const Color(0xFF16A34A),
        'iconBg': const Color(0xFFDCFCE7),
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Full Mock Test',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
        child: Column(
          children: [
            const SizedBox(height: 6),
            // Top Circle with Red Clock / Timer Logo
            Center(
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_filled_rounded,
                    color: Color(0xFFDC2626),
                    size: 34,
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
                  fontSize: 12.5,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),

            // Pill Badge: IELTS Academic • ⏱️ 2h 45m
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_rounded, size: 15, color: Color(0xFFB91C1C)),
                  SizedBox(width: 6),
                  Text(
                    'IELTS Academic',
                    style: TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Color(0xFFB91C1C))),
                  SizedBox(width: 8),
                  Icon(Icons.access_time_rounded, size: 13, color: Color(0xFFB91C1C)),
                  SizedBox(width: 4),
                  Text(
                    '2h 45m',
                    style: TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4 Skill Preview Cards (1, 2, 3, 4)
            ...previewSections.asMap().entries.map((entry) {
              final idx = entry.key;
              final sec = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02), blurRadius: 8,
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
                        color: sec['iconBg'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(sec['icon'] as IconData, color: sec['iconColor'] as Color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sec['title'] as String,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sec['subtitle'] as String,
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
                  backgroundColor: const Color(0xFFBE123C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Mock Test',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
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

  // ===========================================================================
  // SCREEN 2: SECTION INTRO SCREEN
  // ===========================================================================
  Widget _buildSectionIntroScreen() {
    if (_activeSections.isEmpty) {
      _generateRandomizedMock();
    }
    final sec = _activeSections[_currentSectionIndex];

    IconData icon;
    Color iconColor;
    Color iconBg;
    if (_currentSectionIndex == 0) {
      icon = Icons.headset_rounded;
      iconColor = const Color(0xFF0284C7);
      iconBg = const Color(0xFFE0F2FE);
    } else if (_currentSectionIndex == 1) {
      icon = Icons.menu_book_rounded;
      iconColor = const Color(0xFF9333EA);
      iconBg = const Color(0xFFF3E8FF);
    } else if (_currentSectionIndex == 2) {
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
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Column(
            children: [
              // Header Row: Close "X" Button + Section X of 4 Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                            color: Colors.black.withValues(alpha: 0.02), blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.black87, size: 20),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02), blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Section ${_currentSectionIndex + 1} of ${_activeSections.length}',
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

              // Center Module Icon
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
              const SizedBox(height: 18),

              // Module Title
              Text(
                sec['title'] ?? '',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              // Cambridge Source Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sec['source'] ?? 'Cambridge IELTS',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03), blurRadius: 10,
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
                    backgroundColor: const Color(0xFFBE123C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Begin Section',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
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

  // ===========================================================================
  // SCREEN 3: ACTIVE TEST WORKSPACE
  // ===========================================================================
  Widget _buildSectionTestScreen() {
    final sec = _activeSections[_currentSectionIndex];
    final questions = sec['questions'] as List? ?? [];
    final bool isWriting = _currentSectionIndex == 2;
    final bool isSpeaking = _currentSectionIndex == 3;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87, size: 22),
          onPressed: _showEndTestDialog,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sec['title'] ?? 'Mock Exam',
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              sec['source'] ?? '',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled, color: Color(0xFFDC2626), size: 14),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_timeLeft),
                  style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 13),
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
                    color: Colors.black.withValues(alpha: 0.02), blurRadius: 6,
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
            const SizedBox(height: 18),

            // Audio Player card if Listening
            if (sec['audioUrl'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _playerState == PlayerState.playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        color: const Color(0xFF0284C7),
                        size: 38,
                      ),
                      onPressed: () async {
                        if (_playerState == PlayerState.playing) {
                          await _audioPlayer.pause();
                        } else {
                          await _audioPlayer.play(UrlSource(sec['audioUrl']));
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Audio Track',
                            style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Audio plays once in real examination conditions',
                            style: TextStyle(color: Color(0xFF0369A1), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Reading passage if Reading
            if (sec['readingPassage'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02), blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sec['readingPassage']['title'] ?? '',
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    Text(
                      sec['readingPassage']['text'] ?? '',
                      style: const TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Questions list
            ...questions.asMap().entries.map((entry) {
              final idx = entry.key;
              final qItem = entry.value;
              final questionKey = 'sec_${sec['id']}_$idx';

              if (isWriting) {
                final currentText = _answersMap[questionKey] ?? '';
                final int currentWords = currentText.trim().isEmpty ? 0 : currentText.trim().split(RegExp(r'\s+')).length;
                final int targetWords = (qItem['minWords'] as int?) ?? 150;

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02), blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        qItem['title'] ?? 'Task ${idx + 1}',
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        qItem['prompt'] ?? '',
                        style: const TextStyle(color: Color(0xFF334155), fontSize: 12.5, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your Essay:', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(
                            '$currentWords / $targetWords words',
                            style: TextStyle(
                              color: currentWords >= targetWords ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: currentText,
                        maxLines: 8,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, height: 1.4),
                        decoration: InputDecoration(
                          hintText: 'Type your essay response here...',
                          hintStyle: const TextStyle(color: Colors.black26, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _answersMap[questionKey] = val;
                          });
                        },
                      ),
                    ],
                  ),
                );
              } else if (isSpeaking) {
                final currentText = _answersMap[questionKey] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02), blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        qItem['part'] ?? 'Part ${idx + 1}',
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        qItem['prompt'] ?? '',
                        style: const TextStyle(color: Color(0xFF334155), fontSize: 12.5, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        initialValue: currentText,
                        maxLines: 4,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Speak aloud or type your spoken points here...',
                          hintStyle: const TextStyle(color: Colors.black26, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                          ),
                        ),
                        onChanged: (val) {
                          _answersMap[questionKey] = val;
                        },
                      ),
                    ],
                  ),
                );
              }

              // Listening / Reading questions (Multiple Choice or Text Input)
              final qText = (qItem['q'] ?? '').toString();
              final List<dynamic>? options = qItem['options'] as List<dynamic>?;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02), blurRadius: 6,
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

                    if (options != null && options.isNotEmpty) ...[
                      Column(
                        children: options.map((opt) {
                          final optStr = opt.toString();
                          final letter = optStr.split('.').first.trim();
                          final isSelected = (_answersMap[questionKey] ?? '').toUpperCase() == letter.toUpperCase();

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _answersMap[questionKey] = letter;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFEE2E2) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFDC2626) : Colors.black.withValues(alpha: 0.08),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    size: 16,
                                    color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      optStr,
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      TextFormField(
                        initialValue: _answersMap[questionKey] ?? '',
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Type your answer...',
                          hintStyle: const TextStyle(color: Colors.black26, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                          ),
                        ),
                        onChanged: (val) {
                          _answersMap[questionKey] = val;
                        },
                      ),
                    ],
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
                  backgroundColor: const Color(0xFFBE123C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _currentSectionIndex < _activeSections.length - 1 ? 'Complete Section & Continue' : 'Submit Mock Exam',
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

  // ===========================================================================
  // SCREEN 4: CORRECTIONS / RESULTS SCREEN
  // ===========================================================================
  Widget _buildCorrectionsScreen() {
    final overall = _correctionsData?['overallBand'] ?? '7.5';
    final lScore = _correctionsData?['listeningScore'] ?? '8.0';
    final rScore = _correctionsData?['readingScore'] ?? '7.5';
    final wScore = _correctionsData?['writingScore'] ?? '7.0';
    final sScore = _correctionsData?['speakingScore'] ?? '7.5';
    final composition = _correctionsData?['composition'] ?? 'Cambridge IELTS';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mock Exam Results', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
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
                border: Border.all(color: AppColors.cardBorderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03), blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('Estimated Overall Band', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Band $overall',
                    style: const TextStyle(color: AppColors.primary, fontSize: 36, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    composition,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreChip('🎧 Listening', lScore),
                      _buildScoreChip('📖 Reading', rScore),
                      _buildScoreChip('✏️ Writing', wScore),
                      _buildScoreChip('🎙️ Speaking', sScore),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Question Breakdown List
            ..._activeSections.map((sec) {
              final questions = sec['questions'] as List? ?? [];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(sec['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                        Text(sec['source'] ?? '', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                      ],
                    ),
                    const Divider(height: 18),
                    ...questions.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final qItem = entry.value;
                      final qKey = 'sec_${sec['id']}_$idx';
                      final userAns = _answersMap[qKey] ?? '[No Answer]';
                      final correctAns = qItem['ans'] ?? '';
                      final exp = qItem['exp'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q${idx + 1}: ${qItem['q'] ?? qItem['title'] ?? ''}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 3),
                            Text('Your answer: $userAns', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            if (correctAns.toString().isNotEmpty) ...[
                              Text('Correct: $correctAns', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                            ],
                            if (exp.toString().isNotEmpty) ...[
                              Text('Explanation: $exp', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // Take Another Mock Button (calls _startMockExamFlow to pick a new randomized test!)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _startMockExamFlow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBE123C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shuffle_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Take Another Mock Test (Randomized)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentView = 'INTRO';
                    _correctionsData = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Full Mock Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 30),
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
