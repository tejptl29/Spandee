import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendee/services/auth_service.dart';
import 'package:spendee/utils/custom_toast.dart';

class StartMonthPage extends StatefulWidget {
  final int? initialBudget;
  const StartMonthPage({super.key, this.initialBudget});

  @override
  State<StartMonthPage> createState() => _StartMonthPageState();
}

class _StartMonthPageState extends State<StartMonthPage> {
  late TextEditingController budgetController;

  @override
  void initState() {
    super.initState();
    budgetController = TextEditingController(
      text: widget.initialBudget != null ? widget.initialBudget.toString() : '',
    );
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentMonthYear = DateFormat('MMMM yyyy').format(DateTime.now());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Start Month"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Center(
                      child: Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          size: 44,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        "Start $currentMonthYear",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    Center(
                      child: Text(
                        "How much money do you have for this month?",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Monthly budget label
                    Text(
                      "Monthly Budget",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Budget input field
                    TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      cursorColor: theme.colorScheme.primary,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.currency_rupee_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        hintText: "4000",
                        hintStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? theme.colorScheme.surface.withAlpha(255)
                            : const Color(0xFFF5F7FA),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 24,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Helper text
                    Text(
                      "Enter your total budget for $currentMonthYear",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Start Tracking Button
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            final budgetText = budgetController.text.trim();
                            if (budgetText.isEmpty) {
                              CustomToast.show(
                                context,
                                "Please enter your monthly budget",
                                type: ToastType.error,
                              );
                              return;
                            }
                            final budget = int.tryParse(budgetText);
                            if (budget == null) {
                              CustomToast.show(
                                context,
                                "Enter a valid number",
                                type: ToastType.error,
                              );
                              return;
                            }
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              CustomToast.show(
                                context,
                                "User not logged in",
                                type: ToastType.error,
                              );
                              return;
                            }
                            final userId = user.uid;
                            try {
                              await AuthService().saveMonthlyBudget(
                                userId,
                                budget,
                              );
                              if (context.mounted) {
                                CustomToast.show(
                                  context,
                                  "Budget saved successfully",
                                  type: ToastType.success,
                                );
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                CustomToast.show(
                                  context,
                                  "Failed to save budget: $e",
                                  type: ToastType.error,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: theme.colorScheme.primary.withOpacity(
                              0.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "Start Tracking",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
