import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:spendee/core/theme/theme_provider.dart';
import 'package:spendee/services/auth_service.dart';
import 'package:spendee/utils/custom_toast.dart';

class PremiumUpgradeScreen extends StatefulWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  State<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends State<PremiumUpgradeScreen> {
  int _selectedPlanIndex = 1; // 0 for Monthly, 1 for Yearly (Default)
  late Razorpay _razorpay;
  bool _isPremium = false;
  bool _isLoading = true;
  String _premiumPlan = "";
  DateTime? _premiumExpiry;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _checkPremiumStatus() async {
    final details = await AuthService().getPremiumDetails();
    if (mounted) {
      setState(() {
        _isPremium = details?['isPremium'] ?? false;
        _premiumPlan = details?['plan'] ?? "";
        final expiryTimestamp = details?['premiumExpiry'] as Timestamp?;
        _premiumExpiry = expiryTimestamp?.toDate();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Check connectivity before updating status
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        CustomToast.show(
          context,
          "Payment successful, but failed to update status due to no internet. We will retry automatically.",
          type: ToastType.info,
        );
      }
      // Note: Ideally, we should save this locally and retry when online.
      // For now, we'll try to update anyway as Firestore has offline support,
      // but the toast informs the user.
    }

    // Update premium status in Firebase
    final plan = _selectedPlanIndex == 0 ? "Monthly" : "Yearly";
    final days = _selectedPlanIndex == 0 ? 30 : 365;

    try {
      await AuthService().updatePremiumStatus(
        isPremium: true,
        plan: plan,
        durationDays: days,
      );

      // Refresh data
      await _checkPremiumStatus();

      if (mounted) {
        CustomToast.show(
          context,
          "Premium Activated! 🎉",
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          "Error updating status",
          type: ToastType.error,
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    CustomToast.show(
      context,
      "Payment Failed: ${response.message}",
      type: ToastType.error,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    CustomToast.show(
      context,
      "External Wallet: ${response.walletName}",
      type: ToastType.info,
    );
  }

  void _openCheckout() async {
    // Check connectivity
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        CustomToast.show(
          context,
          "No internet connection. Please try again later.",
          type: ToastType.error,
        );
      }
      return;
    }

    final amount = _selectedPlanIndex == 0 ? 99 : 999;
    final planName = _selectedPlanIndex == 0 ? "Monthly Plan" : "Yearly Plan";
    final user = AuthService().currentUser;

    var options = {
      'key': 'rzp_test_SD6vNhX4Nekpki', // ADD YOUR KEY HERE
      'amount': amount * 100, // in paise
      'name': 'Spendee Premium',
      'description': planName,
      'prefill': {
        'contact': user?.phoneNumber ?? '',
        'email': user?.email ?? '',
      },
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Star Icon & Title
              Icon(
                Icons.stars_rounded,
                size: 80,
                color: _isPremium ? const Color(0xFF16B888) : Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                _isPremium ? "Premium Active" : "⭐ Premium Access ⭐",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isPremium
                    ? "Thank you for supporting us!"
                    : "Unlock PDF Downloads & More",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),

              // Feature List
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureRow(context, "Download Monthly PDF"),
                  _buildFeatureRow(context, "Unlimited Records"),
                  _buildFeatureRow(context, "Secure Cloud Backup"),
                ],
              ),

              const SizedBox(height: 48),

              if (!_isPremium) ...[
                // Plan selection
                _buildPlanCard(
                  context,
                  title: "Monthly Plan",
                  price: "₹99 / month",
                  isBestValue: false,
                  isSelected: _selectedPlanIndex == 0,
                  onTap: () => setState(() => _selectedPlanIndex = 0),
                ),
                const SizedBox(height: 16),
                _buildPlanCard(
                  context,
                  title: "Yearly Plan",
                  price: "₹999 / year",
                  subtitle: "(Save 20%)",
                  isBestValue: true,
                  isSelected: _selectedPlanIndex == 1,
                  onTap: () => setState(() => _selectedPlanIndex = 1),
                ),
                const SizedBox(height: 48),
                // Upgrade Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _openCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16B888),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Upgrade to Premium",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16B888).withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF16B888)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF16B888),
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Premium Active",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "You have full access to all features.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(180),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem("Plan", _premiumPlan),
                          if (_premiumExpiry != null)
                            _buildDetailItem(
                              "Expires On",
                              DateFormat('dd MMM yyyy').format(_premiumExpiry!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String text) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF16B888),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    String? subtitle,
    required bool isBestValue,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16B888)
                : (isDark ? Colors.white24 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBestValue) ...[
                  Row(
                    children: const [
                      Text("🔥 ", style: TextStyle(fontSize: 14)),
                      Text(
                        "Best Value",
                        style: TextStyle(
                          color: Color(0xFF16B888),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? const Color(0xFF16B888)
                    : Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
