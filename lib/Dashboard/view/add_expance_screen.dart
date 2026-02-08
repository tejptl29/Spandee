import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:spendee/core/theme/theme_provider.dart';
import 'package:spendee/services/auth_service.dart';
import 'package:spendee/utils/custom_toast.dart';

class AddExpanceScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final String? expenseId;
  final int? initialAmount;
  final String? initialCategory;
  final DateTime? initialDate;

  const AddExpanceScreen({
    super.key,
    this.onSuccess,
    this.expenseId,
    this.initialAmount,
    this.initialCategory,
    this.initialDate,
  });

  @override
  State<AddExpanceScreen> createState() => _AddExpanceScreenState();
}

class _AddExpanceScreenState extends State<AddExpanceScreen> {
  String? _selectedCategoryLabel = "Food";
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  bool _isLoading = false;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount.toString();
    }
    if (widget.initialCategory != null) {
      bool isStandard = categories.any(
        (c) => c['label'] == widget.initialCategory,
      );
      if (isStandard) {
        _selectedCategoryLabel = widget.initialCategory;
      } else {
        _selectedCategoryLabel = "Other";
        _categoryController.text = widget.initialCategory!;
      }
    }
  }

  final List<Map<String, String>> categories = [
    {"icon": "🍔", "label": "Food"},
    {"icon": "⛽", "label": "Petrol"},
    {"icon": "📱", "label": "Recharge"},
    {"icon": "🚗", "label": "Travel"},
    {"icon": "🛍️", "label": "Shopping"},
    {"icon": "🏥", "label": "Health"},
    {"icon": "🎬", "label": "Movies"},
    {"icon": "🎓", "label": "Education"},
    {"icon": "🎁", "label": "Gifts"},
    {"icon": "🍕", "label": "Snacks"},
    {"icon": "📦", "label": "Other"},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Provider.of<ThemeProvider>(
          context,
          listen: false,
        ).isDarkMode;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF12B886),
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF12B886),
                    onPrimary: Colors.white,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_amountController.text.isEmpty) {
      CustomToast.show(
        context,
        'Please enter an amount',
        type: ToastType.error,
      );
      return;
    }

    final categoryLabel = _selectedCategoryLabel;
    final categoryName = categoryLabel == 'Other'
        ? _categoryController.text.trim()
        : categoryLabel;

    if (categoryName == null || categoryName.isEmpty) {
      CustomToast.show(
        context,
        'Please enter a category name',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final connectivityResult = await Connectivity().checkConnectivity();
        final isOffline = connectivityResult.contains(ConnectivityResult.none);

        if (widget.expenseId != null) {
          // Update mode
          final updateFuture = AuthService().updateExpense(
            userId: user.uid,
            expenseId: widget.expenseId!,
            amount: int.parse(_amountController.text),
            category: categoryName,
            date: _selectedDate,
          );

          if (!isOffline) await updateFuture;
        } else {
          // Add mode
          final saveFuture = AuthService().saveExpense(
            userId: user.uid,
            amount: int.parse(_amountController.text),
            category: categoryName,
            date: _selectedDate,
          );

          if (!isOffline) await saveFuture;
        }

        if (mounted) {
          CustomToast.show(
            context,
            isOffline
                ? 'Changes saved offline - will sync later'
                : (widget.expenseId != null
                      ? 'Expense updated successfully'
                      : 'Expense saved successfully'),
            type: isOffline ? ToastType.info : ToastType.success,
          );

          // Clear fields
          _amountController.clear();
          _categoryController.clear();
          setState(() {
            _selectedCategoryLabel = "Food";
          });

          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Error saving expense: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCategoryPicker() async {
    final cat = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 20),
                blurRadius: 20,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Select Category",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategoryLabel == cat['label'];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF12B886).withAlpha(30)
                            : isDark
                            ? Colors.white.withAlpha(10)
                            : Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF12B886)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            cat['icon']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['label']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF12B886)
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );

    if (cat != null && mounted) {
      setState(() {
        _selectedCategoryLabel = cat['label'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen context

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Title
                Text(
                  widget.expenseId != null ? "Edit Expense" : "Add Expense",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.expenseId != null
                      ? "Keep your spending records up to date"
                      : "Track your spending effortlessly",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(140),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                /// Amount
                Text(
                  "Amount",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(200),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: _cardDecoration(context: context),
                  child: Row(
                    children: [
                      Icon(
                        Icons.currency_rupee_rounded,
                        size: 26,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "0.00",
                            hintStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(60),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.expenseId != null) ...[
                  const SizedBox(height: 24),

                  /// Date
                  Text(
                    "Date",
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(200),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: _cardDecoration(context: context),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Color(0xFF12B886),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('d MMMM y').format(_selectedDate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                /// Category
                Text(
                  "Category",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(200),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showCategoryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: _cardDecoration(context: context),
                    child: Row(
                      children: [
                        Text(
                          categories.firstWhere(
                            (c) => c['label'] == _selectedCategoryLabel,
                            orElse: () => categories.first,
                          )['icon']!,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedCategoryLabel ?? "Select Category",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 24,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_selectedCategoryLabel == 'Other') ...[
                  const SizedBox(height: 24),
                  Text(
                    "Custom Category",
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(200),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: _cardDecoration(context: context),
                    child: TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter category name",
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(80),
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                /// Date
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(context: context),
                  child: Text(
                    "Date: ${DateFormat('EEEE, d MMMM').format(DateTime.now())}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),

                const SizedBox(height: 40), // Spacing instead of Spacer
                /// Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12B886),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveExpense,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.expenseId != null
                                ? "Update Expense"
                                : "Save Expense",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({
    required BuildContext context,
    bool selected = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: selected
          ? const Color(0xFF12B886).withAlpha(isDark ? 50 : 30)
          : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: selected
            ? const Color(0xFF12B886)
            : isDark
            ? Colors.white.withAlpha(15)
            : Colors.grey.withAlpha(30),
        width: selected ? 2 : 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withAlpha(50)
              : Colors.black.withAlpha(10),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
