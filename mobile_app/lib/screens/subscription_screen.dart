import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'subscription_history_screen.dart';
import 'dashboard_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool isRegisterFlow;
  const SubscriptionScreen({super.key, this.isRegisterFlow = false});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  List<dynamic> _plans = [];
  dynamic _paymentInfo;
  String? _selectedPlanId;
  final TextEditingController _referenceController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final plansRes = await _apiService.request(path: '/subscriptions/plans', method: 'GET');
      final infoRes = await _apiService.request(path: '/subscriptions/payment-info', method: 'GET');

      if (plansRes.statusCode == 200 && infoRes.statusCode == 200) {
        final List<dynamic> allPlans = jsonDecode(plansRes.body);
        final dynamic paymentInfo = jsonDecode(infoRes.body);

        final prefs = await SharedPreferences.getInstance();
        final pendingPlan = prefs.getString('pendingOnboardingPlan');

        setState(() {
          _plans = allPlans.where((p) => p['code'] != 'FREE').toList();
          _paymentInfo = paymentInfo;
          
          if (_plans.isNotEmpty) {
            _selectedPlanId = _plans[0]['id'];
            if (pendingPlan != null) {
              final targetCode = pendingPlan == '12_MONTHS' ? 'PREMIUM' : 'PRO';
              for (final plan in _plans) {
                if (plan['code'] == targetCode) {
                  _selectedPlanId = plan['id'];
                  break;
                }
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading subscription info: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a premium plan to continue.')),
      );
      return;
    }
    if (_referenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your transaction reference or sender account name.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await _apiService.request(
        path: '/subscriptions/manual-request',
        method: 'POST',
        body: jsonEncode({
          'planId': _selectedPlanId,
          'receiptUrl': _referenceController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Payment Submitted', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
              content: const Text(
                'Proof of payment submitted successfully! Tutors will review and activate your account shortly.',
                style: TextStyle(color: AppColors.textSecondaryLight),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Pop dialog
                    if (widget.isRegisterFlow) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      );
                    } else {
                      Navigator.pop(context); // Pop screen
                    }
                  },
                  child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      } else {
        final body = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['message'] ?? 'Failed to submit request')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Upgrade Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: widget.isRegisterFlow
            ? const SizedBox()
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (widget.isRegisterFlow)
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Choose Your Premium Plan',
                    style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._plans.map((plan) {
                    final isSelected = _selectedPlanId == plan['id'];
                    final double price = double.tryParse(plan['price']?.toString() ?? '') ?? 0.0;
                    final features = plan['features'] as List?;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlanId = plan['id'];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.surfaceTint : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.cardBorderLight,
                            width: isSelected ? 2 : 1,
                          ),
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
                                  plan['name'] ?? '',
                                  style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '₦${price.toStringAsFixed(0)}',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (features != null)
                              ...features.map((feat) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 14),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            feat.toString(),
                                            style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  if (_paymentInfo != null) ...[
                    const Text(
                      'Payment Details',
                      style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                          _buildDetailRow('Bank Name', _paymentInfo['bankName'] ?? ''),
                          const Divider(color: AppColors.cardBorderLight, height: 20),
                          _buildDetailRow('Account Number', _paymentInfo['accountNumber'] ?? ''),
                          const Divider(color: AppColors.cardBorderLight, height: 20),
                          _buildDetailRow('Account Name', _paymentInfo['accountName'] ?? ''),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Confirm Your Payment',
                      style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _referenceController,
                      style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Transaction Reference / Sender Details',
                        labelStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                        helperText: 'Paste transaction reference ID, or enter sender account name and payment date.',
                        helperStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 10),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _submitting ? null : _submitRequest,
                      child: Text(
                        _submitting ? 'Submitting Details...' : 'Submit Payment Reference',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
        Text(value, style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
