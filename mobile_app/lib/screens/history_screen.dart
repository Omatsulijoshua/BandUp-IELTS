import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  /// Static helper to record an attempt from any screen (e.g. Speaking, Writing, Reading, Listening)
  static Future<void> recordAttempt({
    required String title,
    required String module,
    required double score,
    Map<String, dynamic>? details,
    DateTime? timestamp,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('user_attempt_history');
      List<dynamic> list = [];
      if (raw != null) {
        try {
          list = jsonDecode(raw) as List<dynamic>;
        } catch (_) {}
      }

      final now = timestamp ?? DateTime.now();
      final dateStr = _formatDateHeader(now);
      final timeStr = _formatTime(now);

      final newItem = {
        'id': 'attempt_${now.millisecondsSinceEpoch}',
        'title': title,
        'module': module,
        'score': score,
        'timeStr': timeStr,
        'dateStr': dateStr,
        'timestamp': now.millisecondsSinceEpoch,
        if (details != null) 'details': details,
      };

      list.insert(0, newItem);
      await prefs.setString('user_attempt_history', jsonEncode(list));
    } catch (e) {
      debugPrint('Error recording attempt: $e');
    }
  }

  static String _formatDateHeader(DateTime dt) {
    const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, $monthName ${dt.day}';
  }

  static String _formatTime(DateTime dt) {
    int hour = dt.hour;
    final String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    final String minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _historyItems = [];
  String _selectedFilter = 'All'; // 'All', 'Listening', 'Reading', 'Writing', 'Speaking'
  Map<String, dynamic>? _selectedAttempt;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rawLocal = prefs.getString('user_attempt_history');

      List<Map<String, dynamic>> loaded = [];

      if (rawLocal != null && rawLocal.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawLocal) as List<dynamic>;
          loaded = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } catch (_) {}
      }

      // Purge any sample/seed records from previous versions so history contains strictly the user's own generated results
      final int initialCount = loaded.length;
      loaded.removeWhere((item) =>
          item['id'] == 'b10t2_speaking_1' ||
          item['id'] == 'b10t1_speaking_1' ||
          item['id'] == 'b21t1_speaking_1');
      if (loaded.length != initialCount) {
        await prefs.setString('user_attempt_history', jsonEncode(loaded));
      }

      // Optionally fetch from backend and merge if user is online
      try {
        final response = await _apiService.request(path: '/analytics/history', method: 'GET');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _mergeBackendHistory(data, loaded);
        }
      } catch (be) {
        debugPrint('Backend history fetch skipped: $be');
      }

      // Sort by timestamp desc
      loaded.sort((a, b) => ((b['timestamp'] ?? 0) as num).compareTo((a['timestamp'] ?? 0) as num));

      setState(() {
        _historyItems = loaded;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
      setState(() => _loading = false);
    }
  }

  void _mergeBackendHistory(dynamic backendData, List<Map<String, dynamic>> target) {
    if (backendData == null) return;
    final existingIds = target.map((e) => e['id']).toSet();

    void checkList(List<dynamic>? list, String module) {
      if (list == null) return;
      for (final item in list) {
        final id = item['id']?.toString() ?? '';
        if (id.isNotEmpty && !existingIds.contains(id)) {
          existingIds.add(id);
          final createdAt = DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now();
          final score = (item['bandScoreEstimate'] as num?)?.toDouble() ?? 5.0;
          final title = item['prompt']?['title'] ?? item['prompt']?['topic'] ?? 'IELTS $module Practice';

          target.add({
            'id': id,
            'title': title,
            'module': module,
            'score': score,
            'timeStr': HistoryScreen._formatTime(createdAt),
            'dateStr': HistoryScreen._formatDateHeader(createdAt),
            'timestamp': createdAt.millisecondsSinceEpoch,
          });
        }
      }
    }

    checkList(backendData['practiceMode']?['speaking'], 'Speaking');
    checkList(backendData['practiceMode']?['writing'], 'Writing');
    checkList(backendData['examMode']?['speaking'], 'Speaking');
    checkList(backendData['examMode']?['writing'], 'Writing');
  }

  // --- Dynamic Stats Calculations ---
  double get _averageScore {
    if (_historyItems.isEmpty) return 0.0;
    final total = _historyItems.fold<double>(0.0, (sum, item) => sum + ((item['score'] as num?)?.toDouble() ?? 0.0));
    return total / _historyItems.length;
  }

  double get _bestScore {
    if (_historyItems.isEmpty) return 0.0;
    return _historyItems.fold<double>(0.0, (maxVal, item) {
      final s = (item['score'] as num?)?.toDouble() ?? 0.0;
      return max(maxVal, s);
    });
  }

  int get _totalTests => _historyItems.length;

  int _countForModule(String module) {
    return _historyItems.where((e) => (e['module'] as String?)?.toLowerCase() == module.toLowerCase()).length;
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedFilter == 'All') return _historyItems;
    return _historyItems.where((e) => (e['module'] as String?)?.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedAttempt != null) {
      return AttemptDetailScreen(
        attempt: _selectedAttempt!,
        onBack: () => setState(() => _selectedAttempt = null),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: Navigator.canPop(context) ? 48 : 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827), size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)))
            : RefreshIndicator(
                onRefresh: _loadHistory,
                color: const Color(0xFFDC2626),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildStatsRow(),
                      const SizedBox(height: 22),
                      _buildFilterPills(),
                      const SizedBox(height: 24),
                      _buildContentSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // --- 1. Top Header with Badge ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'History',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2), // Soft pastel red
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$_totalTests',
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. Summary Stats Cards (Average, Best, Tests) ---
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            value: _averageScore.toStringAsFixed(1),
            label: 'Average',
            icon: _buildBarChartIcon(),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            value: _bestScore.toStringAsFixed(1),
            label: 'Best',
            icon: const Icon(Icons.emoji_events_rounded, color: Color(0xFFEF4444), size: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            value: '$_totalTests',
            label: 'Tests',
            icon: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartIcon() {
    return SizedBox(
      width: 22,
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(width: 4, height: 10, decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 2.5),
          Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 2.5),
          Container(width: 4, height: 13, decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Widget icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Filter Pills Row ---
  Widget _buildFilterPills() {
    final int allCount = _totalTests;
    final int speakingCount = _countForModule('Speaking');
    final int listeningCount = _countForModule('Listening');
    final int readingCount = _countForModule('Reading');
    final int writingCount = _countForModule('Writing');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterPill(
            label: 'All $allCount',
            filterKey: 'All',
            icon: Icons.grid_view_rounded,
            activeColor: const Color(0xFFC5221F), // Red
          ),
          const SizedBox(width: 10),
          _buildFilterPill(
            label: listeningCount > 0 ? 'Listening $listeningCount' : 'Listening',
            filterKey: 'Listening',
            icon: Icons.headphones_rounded,
            activeColor: const Color(0xFF007AFF), // Blue
          ),
          const SizedBox(width: 10),
          _buildFilterPill(
            label: readingCount > 0 ? 'Reading $readingCount' : 'Reading',
            filterKey: 'Reading',
            icon: Icons.menu_book_rounded,
            activeColor: const Color(0xFFC026D3), // Purple
          ),
          const SizedBox(width: 10),
          _buildFilterPill(
            label: writingCount > 0 ? 'Writing $writingCount' : 'Writing',
            filterKey: 'Writing',
            icon: Icons.edit_outlined,
            activeColor: const Color(0xFFF97316), // Orange
          ),
          const SizedBox(width: 10),
          _buildFilterPill(
            label: 'Speaking',
            badgeText: speakingCount > 0 ? '$speakingCount' : null,
            filterKey: 'Speaking',
            icon: Icons.mic_rounded,
            activeColor: const Color(0xFF10B981), // Emerald
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required String filterKey,
    required IconData icon,
    required Color activeColor,
    String? badgeText,
  }) {
    final bool isSelected = _selectedFilter == filterKey;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
        });
      },
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF374151),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1F2937),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 6),
              Text(
                badgeText,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- 4. Content Section (List of Cards or Empty State) ---
  Widget _buildContentSection() {
    final items = _filteredItems;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    // Group items by dateStr
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in items) {
      final dateStr = (item['dateStr'] as String?) ?? 'RECENT';
      grouped.putIfAbsent(dateStr, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
              child: Text(
                entry.key.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            ...entry.value.map((item) => _buildTestCard(item)),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  // --- 5. Test Card Item ---
  Widget _buildTestCard(Map<String, dynamic> item) {
    final String module = item['module'] ?? 'Speaking';
    final String title = item['title'] ?? 'IELTS Test';
    final String timeStr = item['timeStr'] ?? '';
    final double score = (item['score'] as num?)?.toDouble() ?? 1.0;

    // Visual attributes per module
    Color iconBg;
    Color iconColor;
    IconData iconData;
    Color moduleLabelColor;

    switch (module.toLowerCase()) {
      case 'listening':
        iconBg = const Color(0xFFEBF5FF);
        iconColor = const Color(0xFF007AFF);
        iconData = Icons.headphones_rounded;
        moduleLabelColor = const Color(0xFF007AFF);
        break;
      case 'reading':
        iconBg = const Color(0xFFF5EDFD);
        iconColor = const Color(0xFF9333EA);
        iconData = Icons.menu_book_rounded;
        moduleLabelColor = const Color(0xFF9333EA);
        break;
      case 'writing':
        iconBg = const Color(0xFFFFF4EB);
        iconColor = const Color(0xFFEA580C);
        iconData = Icons.edit_outlined;
        moduleLabelColor = const Color(0xFFEA580C);
        break;
      case 'speaking':
      default:
        iconBg = const Color(0xFFE8F8EE);
        iconColor = const Color(0xFF10B981);
        iconData = Icons.mic_rounded;
        moduleLabelColor = const Color(0xFF10B981);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _selectedAttempt = item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Module icon box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            module,
                            style: TextStyle(
                              color: moduleLabelColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (timeStr.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Score
                Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFFDC2626), // Bold red
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFD1D5DB),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 6. Empty States (Matches Images 3, 4, 5) ---
  Widget _buildEmptyState() {
    Color circleBg;
    Color iconColor;
    IconData iconData;
    String moduleName = _selectedFilter;

    switch (_selectedFilter.toLowerCase()) {
      case 'listening':
        circleBg = const Color(0xFFEBF5FF);
        iconColor = const Color(0xFF3B82F6);
        iconData = Icons.headphones_rounded;
        break;
      case 'reading':
        circleBg = const Color(0xFFF5EDFD);
        iconColor = const Color(0xFFA855F7);
        iconData = Icons.menu_book_rounded;
        break;
      case 'writing':
        circleBg = const Color(0xFFFFF4EB);
        iconColor = const Color(0xFFF97316);
        iconData = Icons.edit_rounded;
        break;
      case 'speaking':
        circleBg = const Color(0xFFE8F8EE);
        iconColor = const Color(0xFF10B981);
        iconData = Icons.mic_rounded;
        break;
      default:
        circleBg = const Color(0xFFF3F4F6);
        iconColor = const Color(0xFF9CA3AF);
        iconData = Icons.history_rounded;
        moduleName = 'Test';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 46,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No $moduleName History',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a $moduleName test to\nsee your results here',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 7. Attempt Details Modal ---
  void _showAttemptDetails(Map<String, dynamic> item) {
    final String title = item['title'] ?? 'IELTS Test';
    final String module = item['module'] ?? 'Speaking';
    final double score = (item['score'] as num?)?.toDouble() ?? 1.0;
    final String dateStr = item['dateStr'] ?? '';
    final String timeStr = item['timeStr'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Band ${score.toStringAsFixed(1)}',
                        style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$module • $dateStr $timeStr',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Attempt Summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 8),
                Text(
                  'You completed this $module evaluation with an estimated Band ${score.toStringAsFixed(1)}. To review individual question recordings, improvement tips, and Band 9 model answers, visit the Speaking module workspace.',
                  style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =========================================================================
// ATTEMPT DETAIL REVIEW SCREEN (Matches Images 1, 2, 3, 4, 5, 6, 7)
// =========================================================================
class AttemptDetailScreen extends StatelessWidget {
  final Map<String, dynamic> attempt;
  final VoidCallback onBack;

  const AttemptDetailScreen({
    super.key,
    required this.attempt,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final String title = attempt['title'] ?? 'IELTS Test';
    final String module = attempt['module'] ?? 'Speaking';
    final double score = (attempt['score'] as num?)?.toDouble() ?? 1.0;
    final Map<String, dynamic>? details = attempt['details'] as Map<String, dynamic>?;

    final bool isSpeaking = module.toLowerCase() == 'speaking';
    final bool isWriting = module.toLowerCase() == 'writing';
    final bool isReading = module.toLowerCase() == 'reading';
    final bool isListening = module.toLowerCase() == 'listening';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FB),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827), size: 20),
            onPressed: onBack,
          ),
          centerTitle: true,
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Circular Band Score Gauge
              _buildScoreGauge(score, module),
              const SizedBox(height: 24),

              // 2. Module specific cards
              if (isSpeaking) ...[
                _buildSpeakingCriteriaCards(details, score),
                const SizedBox(height: 18),
                _buildImprovementTipsCard(details, score),
                const SizedBox(height: 18),
                _buildYourMistakesCard(details),
                const SizedBox(height: 18),
                _buildYourResponsesCard(details),
              ] else if (isWriting) ...[
                _buildWritingCriteriaCards(details, score),
                const SizedBox(height: 18),
                _buildImprovementTipsCard(details, score),
                const SizedBox(height: 18),
                _buildWritingEssayCard(details),
              ] else if (isReading || isListening) ...[
                _buildObjectiveSummaryCards(details, module),
                const SizedBox(height: 18),
                _buildObjectiveQuestionsReview(details),
              ] else ...[
                _buildFallbackCard(details, score, module),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Circular Band Score Gauge ---
  Widget _buildScoreGauge(double score, String module) {
    return Center(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _ScoreGaugePainter(
            score: score,
            progressColor: const Color(0xFFDC2626), // crimson red matching screenshot
            trackColor: const Color(0xFFF1F5F9),    // subtle light grey
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$module Band',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. Speaking: 4 Criterion Cards ---
  Widget _buildSpeakingCriteriaCards(Map<String, dynamic>? details, double score) {
    final fluency = details?['fluency'] as Map<String, dynamic>?;
    final lexical = details?['lexical'] as Map<String, dynamic>?;
    final grammar = details?['grammar'] as Map<String, dynamic>?;
    final pronunciation = details?['pronunciation'] as Map<String, dynamic>?;

    final int defaultScore = score.toInt() > 0 ? score.toInt() : 1;

    return Column(
      children: [
        _buildCriterionCard(
          title: 'Fluency & Coherence',
          bulletColor: const Color(0xFF007AFF), // Blue
          score: fluency?['score'] ?? defaultScore,
          feedback: fluency?['feedback']?.toString() ??
              'Your answers were highly irrelevant and failed to address the questions. Answering \'Yes\' to complex questions about economics and business is not acceptable in an IELTS speaking test. You failed to provide any coherent information.',
        ),
        const SizedBox(height: 12),
        _buildCriterionCard(
          title: 'Lexical Resource',
          bulletColor: const Color(0xFFC026D3), // Purple
          score: lexical?['score'] ?? defaultScore,
          feedback: lexical?['feedback']?.toString() ??
              'There is no vocabulary range to assess. Using only the word \'Yes\' demonstrates a complete lack of lexical resource.',
        ),
        const SizedBox(height: 12),
        _buildCriterionCard(
          title: 'Grammatical Range',
          bulletColor: const Color(0xFFF97316), // Orange
          score: grammar?['score'] ?? defaultScore,
          feedback: grammar?['feedback']?.toString() ??
              'There is no grammatical structure to assess. You provided no full sentences or complex language.',
        ),
        const SizedBox(height: 12),
        _buildCriterionCard(
          title: 'Pronunciation',
          bulletColor: const Color(0xFF10B981), // Green
          score: pronunciation?['score'] ?? defaultScore,
          feedback: pronunciation?['feedback']?.toString() ??
              'While the word \'Yes\' is audible, it is impossible to evaluate pronunciation for a complete IELTS speaking task based on this.',
        ),
      ],
    );
  }

  Widget _buildCriterionCard({
    required String title,
    required Color bulletColor,
    required dynamic score,
    required String feedback,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: bulletColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444), // red badge
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Improvement Tips Card ---
  Widget _buildImprovementTipsCard(Map<String, dynamic>? details, double score) {
    List<String> tips = [];
    if (details?['tips'] != null) {
      tips = (details!['tips'] as List).map((e) => e.toString()).toList();
    }
    if (tips.isEmpty) {
      tips = [
        'You must stop answering with single words. IELTS Speaking requires you to develop your answers by providing examples, reasons, and explanations.',
        'Your answers were off-topic because you ignored the content of the questions. You must answer what is asked, not just give a generic response.',
        'Practice the \'PPF\' method (Past, Present, Future) or the \'ARE\' method (Answer, Reason, Example) to expand your responses.',
        'Review the IELTS Speaking band descriptors; you cannot achieve a passing score if you do not speak in full sentences.',
        'Listen to sample IELTS speaking tests to understand the expected length and depth of responses for Part 3 questions.',
      ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Improvement Tips',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
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
                      color: Color(0xFFDC2626),
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
                        color: Color(0xFF4B5563),
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
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

  // --- 4. Your Mistakes Card ---
  Widget _buildYourMistakesCard(Map<String, dynamic>? details) {
    List<dynamic> mistakes = (details?['mistakes'] as List?) ?? [];
    if (mistakes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
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

          // Mistakes list
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
                      color: Color(0xFFB91C1C), // dark red
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
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
                              fontWeight: FontWeight.w600,
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

  // --- 5. Your Responses Card ---
  Widget _buildYourResponsesCard(Map<String, dynamic>? details) {
    List<dynamic> responses = (details?['responses'] as List?) ?? [];
    if (responses.isEmpty) {
      final mistakes = (details?['mistakes'] as List?) ?? [];
      if (mistakes.isNotEmpty) {
        responses = List.generate(mistakes.length, (i) {
          final m = mistakes[i] as Map;
          final wrong = m['wrong']?.toString() ?? 'Yes';
          final words = wrong.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          return {
            'questionNumber': 'Q${i + 1}',
            'questionText': m['question'] ?? 'Question ${i + 1}',
            'answer': wrong,
            'wordCount': words,
          };
        });
      }
    }

    if (responses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Responses',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(responses.length, (index) {
            final r = Map<String, dynamic>.from(responses[index] as Map);
            final String qNum = r['questionNumber'] ?? 'Q${index + 1}';
            final String qText = r['questionText'] ?? '';
            final String userAns = r['answer'] ?? '';
            final int wordCount = (r['wordCount'] as num?)?.toInt() ??
                userAns.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        qNum,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        qText,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    userAns,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$wordCount words',
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (index < responses.length - 1)
                  const Divider(color: Color(0xFFF3F4F6), height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  // --- 6. Objective: Reading & Listening Summary ---
  Widget _buildObjectiveSummaryCards(Map<String, dynamic>? details, String module) {
    final int correct = (details?['correctCount'] as num?)?.toInt() ?? 0;
    final int total = (details?['totalCount'] as num?)?.toInt() ?? 40;
    final int percent = total > 0 ? ((correct / total) * 100).round() : 0;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                const SizedBox(height: 8),
                Text(
                  '$correct / $total',
                  style: const TextStyle(color: Color(0xFF111827), fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                const Text('Correct Answers', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.percent_rounded, color: Color(0xFF007AFF), size: 24),
                const SizedBox(height: 8),
                Text(
                  '$percent%',
                  style: const TextStyle(color: Color(0xFF111827), fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                const Text('Accuracy', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 7. Objective: Questions Review List ---
  Widget _buildObjectiveQuestionsReview(Map<String, dynamic>? details) {
    final List<dynamic> questions = (details?['questions'] as List?) ?? [];
    if (questions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Question Review',
            style: TextStyle(color: Color(0xFF111827), fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ...List.generate(questions.length, (index) {
            final q = Map<String, dynamic>.from(questions[index] as Map);
            final bool isCorrect = q['isCorrect'] == true;
            final String qText = q['questionText'] ?? 'Question ${index + 1}';
            final String userAns = q['userAnswer'] ?? '(No answer)';
            final String correctAns = q['correctAnswerStr'] ?? q['correctAnswer'] ?? '';
            final String explanation = q['explanation'] ?? '';

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              size: 14,
                              color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCorrect ? 'Correct' : 'Incorrect',
                              style: TextStyle(
                                color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Q${index + 1}',
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    qText,
                    style: const TextStyle(color: Color(0xFF111827), fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Your Answer:', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          userAns,
                          style: TextStyle(
                            color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            decoration: isCorrect ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      if (!isCorrect && correctAns.isNotEmpty) ...[
                        Text('Correct:', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            correctAns,
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (explanation.isNotEmpty && explanation != 'No explanation available.') ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        explanation,
                        style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 8. Writing: 4 Criteria Cards ---
  Widget _buildWritingCriteriaCards(Map<String, dynamic>? details, double score) {
    final ta = details?['taskAchievement'] as Map<String, dynamic>?;
    final cc = details?['coherenceCohesion'] as Map<String, dynamic>?;
    final lr = details?['lexicalResource'] as Map<String, dynamic>?;
    final gr = details?['grammaticalRange'] as Map<String, dynamic>?;

    final int defaultScore = score.toInt() > 0 ? score.toInt() : 6;

    return Column(
      children: [
        _buildCriterionCard(
          title: 'Task Achievement',
          bulletColor: const Color(0xFF007AFF),
          score: ta?['score'] ?? defaultScore,
          feedback: ta?['feedback']?.toString() ?? 'All parts of the prompt were addressed with appropriate detail and support.',
        ),
        const SizedBox(height: 12),
        _buildCriterionCard(
          title: 'Coherence & Cohesion',
          bulletColor: const Color(0xFFC026D3),
          score: cc?['score'] ?? defaultScore,
          feedback: cc?['feedback']?.toString() ?? 'Information and ideas are organized logically with clear overall progression throughout the essay.',
        ),
        const SizedBox(height: 12),
        _buildCriterionCard(
          title: 'Lexical Resource',
          bulletColor: const Color(0xFFF97316),
          score: lr?['score'] ?? defaultScore,
          feedback: lr?['feedback']?.toString() ?? 'A sufficient range of vocabulary was used with some flexibility and precise word choices.',
        ),
        const SizedBox(height: 12),
        _buildCriterionCard(
          title: 'Grammatical Range & Accuracy',
          bulletColor: const Color(0xFF10B981),
          score: gr?['score'] ?? defaultScore,
          feedback: gr?['feedback']?.toString() ?? 'Uses a variety of complex structures with good control of grammar and punctuation.',
        ),
      ],
    );
  }

  // --- 9. Writing: Essay Review Card ---
  Widget _buildWritingEssayCard(Map<String, dynamic>? details) {
    final String essay = details?['userEssay']?.toString() ?? '';
    final int wordCount = (details?['wordCount'] as num?)?.toInt() ??
        essay.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    if (essay.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Submitted Essay',
                style: TextStyle(color: Color(0xFF111827), fontSize: 17, fontWeight: FontWeight.w800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$wordCount words',
                  style: const TextStyle(color: Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Text(
              essay,
              style: const TextStyle(color: Color(0xFF374151), fontSize: 13.5, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCard(Map<String, dynamic>? details, double score, String module) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attempt Summary', style: TextStyle(color: Color(0xFF111827), fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
            'You completed this $module test with an estimated Band ${score.toStringAsFixed(1)}.',
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// SCORE GAUGE PAINTER
// =========================================================================
class _ScoreGaugePainter extends CustomPainter {
  final double score;
  final Color progressColor;
  final Color trackColor;

  _ScoreGaugePainter({
    required this.score,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track ring
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc starting from top (-pi / 2)
    final sweepAngle = (score.clamp(0.0, 9.0) / 9.0) * 2 * pi;
    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreGaugePainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.progressColor != progressColor;
}
