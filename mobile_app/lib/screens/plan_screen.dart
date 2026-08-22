import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization.dart';
import 'listening_practice_screen.dart';
import 'reading_practice_screen.dart';
import 'writing_practice_screen.dart';
import 'speaking_practice_screen.dart';
import 'dashboard_screen.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _schedule = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    try {
      final response = await _apiService.request(
        path: '/content/schedule',
        method: 'GET',
      );
      if (response.statusCode == 200) {
        setState(() {
          _schedule = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _t(String key) => LocalizationService.translate(key);

  void _launchTask(Map<String, dynamic> task) {
    final module = task['module'];
    final entityId = task['entityId'];

    if (entityId == 'practice-session') return;

    Widget targetScreen;
    if (module == 'LISTENING') {
      targetScreen = const ListeningPracticeScreen();
    } else if (module == 'READING') {
      targetScreen = const ReadingPracticeScreen();
    } else if (module == 'WRITING') {
      targetScreen = const WritingPracticeScreen();
    } else if (module == 'SPEAKING') {
      targetScreen = const SpeakingPracticeScreen();
    } else {
      return;
    }

    _navigateToPractice(targetScreen);
  }

  Future<void> _navigateToPractice(Widget screen) async {
    final dashboardState = context.findAncestorStateOfType<DashboardScreenState>();
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (result != null && dashboardState != null) {
      dashboardState.setTabIndex(result);
    }
  }

  int _getHistoryCount(dynamic history) {
    if (history == null) return 0;
    if (history is List) return history.length;
    if (history is String) {
      try {
        final decoded = jsonDecode(history);
        if (decoded is List) return decoded.length;
      } catch (_) {}
    }
    return 0;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Oct 11, 2026';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return 'Oct 11, 2026';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    
    // Calculate total and completed tasks from the schedule
    int totalTasksCount = 0;
    int completedTasksCount = 0;
    for (final day in _schedule) {
      final tasks = day['tasks'] as List? ?? [];
      for (final task in tasks) {
        totalTasksCount++;
        if (task['completed'] == true) {
          completedTasksCount++;
        }
      }
    }
    final int weekTotal = totalTasksCount > 0 ? totalTasksCount : 33;
    final int weekCompleted = completedTasksCount;
    final int weekPercent = weekTotal > 0 ? (weekCompleted * 100 ~/ weekTotal) : 0;

    // Module done stats
    final int listeningDone = _getHistoryCount(user?['progressStats']?['listeningHistory']);
    final int readingDone = _getHistoryCount(user?['progressStats']?['readingHistory']);
    final int writingDone = _getHistoryCount(user?['progressStats']?['writingHistory']);
    final int speakingDone = _getHistoryCount(user?['progressStats']?['speakingHistory']);

    final double targetBand = (user?['targetBand'] as num? ?? 7.0).toDouble();
    final String targetBandStr = targetBand.toStringAsFixed(0);
    final String examDateFormatted = _formatDate(user?['testDate']);

    // Today's tasks (day 0 or matching date)
    final Map<String, dynamic> todayDay = _schedule.isNotEmpty
        ? (_schedule[0] as Map<String, dynamic>)
        : {
            'dayLabel': 'Today',
            'tasks': [
              {'title': 'Listening: IELTS Book 10 Test 1', 'module': 'LISTENING', 'duration': '~30 min', 'completed': false},
              {'title': 'Reading: Psychology/Business', 'module': 'READING', 'duration': '~20 min', 'completed': false},
              {'title': 'Writing: IELTS Book 10 Test 1 (Full Test)', 'module': 'WRITING', 'duration': '~60 min', 'completed': false},
              {'title': 'Speaking: IELTS Book 10 Test 1', 'module': 'SPEAKING', 'duration': '~15 min', 'completed': false},
            ]
          };

    final List todayTasks = todayDay['tasks'] as List? ?? [];
    final int todayTotal = todayTasks.length;
    final int todayDone = todayTasks.where((t) => t['completed'] == true).length;

    // Upcoming schedule days (from index 1 onward)
    final List upcomingDays = _schedule.length > 1
        ? _schedule.sublist(1)
        : [
            {
              'date': '2026-08-24',
              'dayLabel': 'Mon',
              'dayNumber': '24',
              'tasks': [
                {'title': 'Listening: IELTS Book 10 Test 2', 'module': 'LISTENING', 'completed': false},
                {'title': 'Reading: History/Economics', 'module': 'READING', 'completed': false},
                {'title': 'Writing: IELTS Book 10 Test 2 (Full Test)', 'module': 'WRITING', 'completed': false},
                {'title': 'Speaking: IELTS Book 10 Test 2', 'module': 'SPEAKING', 'completed': false},
              ]
            }
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFC62828)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- IMAGE 1 (TOP SECTION) ---

                    // 1. Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Study Plan',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Refresh Button
                        GestureDetector(
                          onTap: () {
                            setState(() => _isLoading = true);
                            _fetchSchedule();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black.withOpacity(0.06)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF64748B),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Badges Row
                    Row(
                      children: [
                        const Icon(Icons.track_changes_rounded, color: Color(0xFFC62828), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Band $targetBandStr',
                          style: const TextStyle(
                            color: Color(0xFFC62828),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.calendar_month_rounded, color: Color(0xFF64748B), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          examDateFormatted,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. Streak Card
                    Container(
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
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFF64748B),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user?['streak'] ?? 0}',
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'day streak',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Band Progress Card
                    Container(
                      padding: const EdgeInsets.all(18),
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
                          const Text(
                            'Band Progress',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildBandProgressRow('Listening', Icons.headset_rounded, const Color(0xFF0284C7), targetBand),
                          const SizedBox(height: 14),
                          _buildBandProgressRow('Reading', Icons.menu_book_rounded, const Color(0xFF9333EA), targetBand),
                          const SizedBox(height: 14),
                          _buildBandProgressRow('Writing', Icons.edit_rounded, const Color(0xFFD97706), targetBand),
                          const SizedBox(height: 14),
                          _buildBandProgressRow('Speaking', Icons.mic_rounded, const Color(0xFF16A34A), targetBand),
                          const SizedBox(height: 14),
                          const Text(
                            'Complete practice tests to see your estimated band per skill.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Today Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$todayDone/$todayTotal • ~125 min left',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Today's Task Cards
                    ...todayTasks.map<Widget>((task) {
                      final module = task['module'] ?? '';
                      final isCompleted = task['completed'] ?? false;
                      final duration = task['duration'] ?? (module == 'WRITING' ? '~60 min' : (module == 'LISTENING' ? '~30 min' : (module == 'READING' ? '~20 min' : '~15 min')));

                      IconData icon;
                      Color iconColor;
                      Color iconBg;
                      if (module == 'LISTENING') {
                        icon = Icons.headset_rounded;
                        iconColor = const Color(0xFF0284C7);
                        iconBg = const Color(0xFFE0F2FE);
                      } else if (module == 'READING') {
                        icon = Icons.menu_book_rounded;
                        iconColor = const Color(0xFF9333EA);
                        iconBg = const Color(0xFFF3E8FF);
                      } else if (module == 'WRITING') {
                        icon = Icons.edit_rounded;
                        iconColor = const Color(0xFFD97706);
                        iconBg = const Color(0xFFFEF3C7);
                      } else {
                        icon = Icons.mic_rounded;
                        iconColor = const Color(0xFF16A34A);
                        iconBg = const Color(0xFFDCFCE7);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _launchTask(task as Map<String, dynamic>),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                              child: Row(
                                children: [
                                  // Icon Badge
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(icon, color: iconColor, size: 20),
                                  ),
                                  const SizedBox(width: 14),

                                  // Title and Duration
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task['title'] ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                                            const SizedBox(width: 4),
                                            Text(
                                              duration,
                                              style: const TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  if (isCompleted)
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18)
                                  else
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.black26,
                                      size: 14,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // --- IMAGE 2 (MIDDLE & BOTTOM SECTION) ---

                    // 5. 4-Module Stats Card
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildModuleCounterColumn('Listening', listeningDone, Icons.headset_rounded, const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
                          _buildModuleCounterColumn('Reading', readingDone, Icons.menu_book_rounded, const Color(0xFF9333EA), const Color(0xFFF3E8FF)),
                          _buildModuleCounterColumn('Writing', writingDone, Icons.edit_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                          _buildModuleCounterColumn('Speaking', speakingDone, Icons.mic_rounded, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. This Week Progress Card
                    Container(
                      padding: const EdgeInsets.all(18),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'This Week',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$weekCompleted/$weekTotal tasks done',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$weekPercent%',
                                style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: weekTotal > 0 ? (weekCompleted / weekTotal) : 0.0,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC62828)),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 7. Ahead of Schedule Card
                    (() {
                      final int dayOfWeek = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
                      final double targetPercent = (dayOfWeek / 7.0) * 100;
                      final double actualPercent = weekPercent.toDouble();

                      String paceTitle = 'Ahead of Schedule';
                      String paceSubtitle = 'Great pace — keep it up!';
                      Color paceColor = const Color(0xFF16A34A);
                      Color paceBg = const Color(0xFFDCFCE7);
                      IconData paceIcon = Icons.arrow_upward_rounded;

                      if (weekCompleted == 0) {
                        if (dayOfWeek >= 3) {
                          paceTitle = 'Behind Schedule';
                          paceSubtitle = 'You haven\'t started your tasks for this week yet.';
                          paceColor = const Color(0xFFEA580C);
                          paceBg = const Color(0xFFFFEDD5);
                          paceIcon = Icons.warning_rounded;
                        } else {
                          paceTitle = 'Ahead of Schedule';
                          paceSubtitle = 'Great pace — keep it up!';
                          paceColor = const Color(0xFF16A34A);
                          paceBg = const Color(0xFFDCFCE7);
                          paceIcon = Icons.arrow_upward_rounded;
                        }
                      } else if (actualPercent >= targetPercent + 15) {
                        paceTitle = 'Ahead of Schedule';
                        paceSubtitle = 'Great pace — keep it up!';
                        paceColor = const Color(0xFF16A34A);
                        paceBg = const Color(0xFFDCFCE7);
                        paceIcon = Icons.arrow_upward_rounded;
                      } else if (actualPercent < targetPercent - 15) {
                        paceTitle = 'Behind Schedule';
                        paceSubtitle = 'Catch up on your pending tasks to stay on track.';
                        paceColor = const Color(0xFFDC2626);
                        paceBg = const Color(0xFFFEE2E2);
                        paceIcon = Icons.warning_rounded;
                      } else {
                        paceTitle = 'On Track';
                        paceSubtitle = 'Good progress — keep it up!';
                        paceColor = const Color(0xFF16A34A);
                        paceBg = const Color(0xFFDCFCE7);
                        paceIcon = Icons.check_circle_outline_rounded;
                      }

                      return Container(
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
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: paceBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                paceIcon,
                                color: paceColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    paceTitle,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    paceSubtitle,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    })(),
                    const SizedBox(height: 28),

                    // 8. Upcoming Section
                    const Text(
                      'Upcoming',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upcoming Timeline
                    ...upcomingDays.asMap().entries.map<Widget>((entry) {
                      final int dayIdx = entry.key;
                      final day = entry.value;
                      final String dateStr = day['date']?.toString() ?? '2026-08-24';
                      final String dayLabel = day['dayLabel']?.toString() ?? 'Mon';
                      final String dayShort = dayLabel.length >= 3 ? dayLabel.substring(0, 3) : dayLabel;
                      final String dayNumber = day['dayNumber']?.toString() ?? dateStr.split('-').last;

                      final tasks = day['tasks'] as List? ?? [];

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Date Column
                            Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dayShort,
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dayNumber,
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (dayIdx < upcomingDays.length - 1)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: const Color(0xFFE2E8F0),
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Day's Task list
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  children: tasks.map<Widget>((task) {
                                    final module = task['module'] ?? '';

                                    IconData icon;
                                    Color iconColor;
                                    Color iconBg;
                                    if (module == 'LISTENING') {
                                      icon = Icons.headset_rounded;
                                      iconColor = const Color(0xFF0284C7);
                                      iconBg = const Color(0xFFE0F2FE);
                                    } else if (module == 'READING') {
                                      icon = Icons.menu_book_rounded;
                                      iconColor = const Color(0xFF9333EA);
                                      iconBg = const Color(0xFFF3E8FF);
                                    } else if (module == 'WRITING') {
                                      icon = Icons.edit_rounded;
                                      iconColor = const Color(0xFFD97706);
                                      iconBg = const Color(0xFFFEF3C7);
                                    } else {
                                      icon = Icons.mic_rounded;
                                      iconColor = const Color(0xFF16A34A);
                                      iconBg = const Color(0xFFDCFCE7);
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
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
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(16),
                                          onTap: () => _launchTask(task as Map<String, dynamic>),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color: iconBg,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(icon, color: iconColor, size: 18),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        task['title'] ?? '',
                                                        style: const TextStyle(
                                                          color: Color(0xFF0F172A),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12.5,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      const Text(
                                                        'Upcoming',
                                                        style: TextStyle(
                                                          color: Color(0xFF94A3B8),
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBandProgressRow(String label, IconData icon, Color iconColor, double targetBand) {
    // Relative target tick position between 0 and 9
    final double targetRatio = (targetBand / 9.0).clamp(0.0, 1.0);

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 12),
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Track bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Target indicator notch
              Align(
                alignment: Alignment((targetRatio * 2) - 1, 0),
                child: Container(
                  width: 2,
                  height: 12,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          '—',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCounterColumn(String label, int val, IconData icon, Color color, Color bgColor) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          '$val',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
