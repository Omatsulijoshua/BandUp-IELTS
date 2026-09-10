import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class SubscriptionHistoryScreen extends StatefulWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  State<SubscriptionHistoryScreen> createState() => _SubscriptionHistoryScreenState();
}

class _SubscriptionHistoryScreenState extends State<SubscriptionHistoryScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  List<dynamic> _logs = [];

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _loading = true);
    try {
      String path = '/subscriptions/history';
      final List<String> params = [];
      if (_startDate != null) {
        params.add('startDate=${_startDate!.toIso8601String()}');
      }
      if (_endDate != null) {
        params.add('endDate=${_endDate!.toIso8601String()}');
      }
      if (params.isNotEmpty) {
        path += '?${params.join('&')}';
      }

      final response = await _apiService.request(path: path, method: 'GET');
      if (response.statusCode == 200) {
        setState(() {
          _logs = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching billing history: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
      _fetchHistory();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      _fetchHistory();
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Billing History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Date Filter Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.cardBorderLight)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectStartDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startDate == null
                                    ? 'Start Date'
                                    : '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: _startDate == null ? AppColors.textSecondaryLight : AppColors.textPrimaryLight,
                                  fontSize: 12,
                                ),
                              ),
                              const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectEndDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _endDate == null
                                    ? 'End Date'
                                    : '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: _endDate == null ? AppColors.textSecondaryLight : AppColors.textPrimaryLight,
                                  fontSize: 12,
                                ),
                              ),
                              const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_startDate != null || _endDate != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _clearFilters,
                      child: const Text('Clear Filters', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Logs list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _logs.isEmpty
                    ? Center(
                        child: Text(
                          'No subscription logs found.',
                          style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final plan = log['plan'] ?? {};
                          final status = log['status'] ?? 'EXPIRED';
                          final double price = double.tryParse(plan['price']?.toString() ?? '') ?? 0.0;
                          final start = DateTime.tryParse(log['startDate'])?.toLocal();
                          final end = DateTime.tryParse(log['endDate'])?.toLocal();

                          Color statusBgColor = AppColors.surfaceTint;
                          Color statusTextColor = AppColors.primary;
                          if (status == 'EXPIRED') {
                            statusBgColor = Colors.grey.withValues(alpha: 0.1);
                            statusTextColor = AppColors.textSecondaryLight;
                          } else if (status == 'CANCELLED') {
                            statusBgColor = Colors.red.withValues(alpha: 0.1);
                            statusTextColor = Colors.red;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      plan['name'] ?? 'Plan',
                                      style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusBgColor,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: statusTextColor.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Amount Paid', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11)),
                                    Text(
                                      '₦${price.toStringAsFixed(0)}',
                                      style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (start != null && end != null) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Timeline', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11)),
                                      Text(
                                        '${start.year}-${start.month}-${start.day} to ${end.year}-${end.month}-${end.day}',
                                        style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
