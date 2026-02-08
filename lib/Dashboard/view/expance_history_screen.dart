import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:spendee/core/theme/theme_provider.dart';
import 'package:spendee/core/utils/category_utils.dart';
import 'package:spendee/services/auth_service.dart';
import 'package:spendee/utils/custom_toast.dart';

class ExpanceHistoryScreen extends StatefulWidget {
  final VoidCallback? onAddExpenseTap;
  final Function(Map<String, dynamic>)? onEditExpense;

  const ExpanceHistoryScreen({
    super.key,
    this.onAddExpenseTap,
    this.onEditExpense,
  });

  @override
  State<ExpanceHistoryScreen> createState() => _ExpanceHistoryScreenState();
}

class _ExpanceHistoryScreenState extends State<ExpanceHistoryScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  Timer? _debounce;
  DateTime? _selectedDateFilter;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
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
    if (picked != null && picked != _selectedDateFilter) {
      setState(() {
        _selectedDateFilter = picked;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header (Stable)
                Text(
                  "All Expenses",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                /// Search Bar (Stable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search category, amount...",
                            hintStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(100),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged("");
                          },
                        ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.calendar_month,
                          size: 20,
                          color: _selectedDateFilter != null
                              ? const Color(0xFF12B886)
                              : Colors.grey,
                        ),
                        onPressed: () => _selectDate(context),
                      ),
                    ],
                  ),
                ),

                if (_selectedDateFilter != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12B886).withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF12B886).withAlpha(50),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event,
                              size: 14,
                              color: Color(0xFF12B886),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat(
                                'd MMM y ',
                              ).format(_selectedDateFilter!),
                              style: const TextStyle(
                                color: Color(0xFF12B886),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedDateFilter = null),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Color(0xFF12B886),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                /// Dynamic Content
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .collection('expenses')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      final allDocs = snapshot.data!.docs;

                      // Filter logic
                      final filteredDocs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final category =
                            ((data['category'] as String?) ?? 'Other')
                                .toLowerCase();
                        final amount = ((data['amount'] as num?) ?? 0)
                            .toString();
                        final date = (data['date'] as Timestamp).toDate();
                        final dateStr = DateFormat(
                          'd MMM y',
                        ).format(date).toLowerCase();
                        final query = _searchQuery.toLowerCase();

                        bool matchesQuery =
                            category.contains(query) ||
                            amount.contains(query) ||
                            dateStr.contains(query);

                        bool matchesDate = true;
                        if (_selectedDateFilter != null) {
                          matchesDate =
                              date.year == _selectedDateFilter!.year &&
                              date.month == _selectedDateFilter!.month &&
                              date.day == _selectedDateFilter!.day;
                        }

                        return matchesQuery && matchesDate;
                      }).toList();

                      // Calculate monthly summaries
                      final Map<String, int> monthlyTotals = {};
                      final Map<String, int> monthlyCounts = {};

                      for (var doc in filteredDocs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final date = (data['date'] as Timestamp).toDate();
                        final monthKey = DateFormat('MMMM yyyy').format(date);
                        final amount = (data['amount'] as num).toInt();

                        monthlyTotals[monthKey] =
                            (monthlyTotals[monthKey] ?? 0) + amount;
                        monthlyCounts[monthKey] =
                            (monthlyCounts[monthKey] ?? 0) + 1;
                      }

                      int totalAmount = 0;
                      for (var doc in filteredDocs) {
                        totalAmount +=
                            ((doc.data() as Map<String, dynamic>)['amount']
                                    as num)
                                .toInt();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Grand Total Summary
                          Text(
                            "Grand Total: ₹${NumberFormat('#,##,###').format(totalAmount)} • ${filteredDocs.length} ${filteredDocs.length == 1 ? 'Expense' : 'Expenses'}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                          const SizedBox(height: 20),

                          /// List or No Match
                          if (filteredDocs.isEmpty &&
                              (_searchQuery.isNotEmpty ||
                                  _selectedDateFilter != null))
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "No matching expenses found",
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(150),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredDocs.length,
                                itemBuilder: (context, index) {
                                  final data =
                                      filteredDocs[index].data()
                                          as Map<String, dynamic>;
                                  final docId = filteredDocs[index].id;
                                  final amount = (data['amount'] as num)
                                      .toInt();
                                  final category =
                                      (data['category'] as String?) ?? 'Other';
                                  final date = (data['date'] as Timestamp)
                                      .toDate();
                                  final currentMonth = DateFormat(
                                    'MMMM yyyy',
                                  ).format(date);

                                  bool showHeader = false;
                                  if (index == 0) {
                                    showHeader = true;
                                  } else {
                                    final prevData =
                                        filteredDocs[index - 1].data()
                                            as Map<String, dynamic>;
                                    final prevDate =
                                        (prevData['date'] as Timestamp)
                                            .toDate();
                                    final prevMonth = DateFormat(
                                      'MMMM yyyy',
                                    ).format(prevDate);
                                    if (currentMonth != prevMonth) {
                                      showHeader = true;
                                    }
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (showHeader) ...[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                            bottom: 12,
                                            left: 4,
                                          ),
                                          child: Text(
                                            "$currentMonth • ${monthlyCounts[currentMonth]} ${monthlyCounts[currentMonth] == 1 ? 'item' : 'items'} • ₹${NumberFormat('#,##,###').format(monthlyTotals[currentMonth])}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                      Dismissible(
                                        key: Key(docId),
                                        direction: DismissDirection.horizontal,
                                        background: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.only(
                                            left: 20,
                                          ),
                                          alignment: Alignment.centerLeft,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF12B886,
                                            ).withAlpha(200),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                          ),
                                        ),
                                        secondaryBackground: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.only(
                                            right: 20,
                                          ),
                                          alignment: Alignment.centerRight,
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade400,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                        ),
                                        confirmDismiss: (direction) async {
                                          if (direction ==
                                              DismissDirection.startToEnd) {
                                            // Edit action
                                            if (widget.onEditExpense != null) {
                                              widget.onEditExpense!({
                                                'id': docId,
                                                'amount': amount,
                                                'category': category,
                                                'date': date,
                                              });
                                            }
                                            return false; // Don't dismiss the item
                                          } else {
                                            // Delete action
                                            return await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                  "Delete Expense",
                                                ),
                                                content: const Text(
                                                  "Are you sure you want to delete this expense?",
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: const Text(
                                                      "Delete",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        },
                                        onDismissed: (direction) async {
                                          if (direction ==
                                              DismissDirection.endToStart) {
                                            await AuthService().deleteExpense(
                                              user!.uid,
                                              docId,
                                            );
                                            if (mounted) {
                                              CustomToast.show(
                                                context,
                                                'Expense deleted',
                                                type: ToastType.success,
                                              );
                                            }
                                          }
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).cardTheme.color,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withAlpha(20)
                                                  : CategoryUtils.getCategoryColor(
                                                      category,
                                                    ).withAlpha(100),
                                              width: 1.2,
                                            ),
                                            boxShadow: isDark
                                                ? []
                                                : [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withAlpha(5),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      CategoryUtils.getCategoryColor(
                                                        category,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      CategoryUtils.getCategoryIcon(
                                                        category,
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      category,
                                                      style: TextStyle(
                                                        color:
                                                            CategoryUtils.getCategoryTextColor(
                                                              category,
                                                              isDark,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                DateFormat(
                                                  'd MMM y',
                                                ).format(date),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withAlpha(150),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                "₹${NumberFormat('#,##,###').format(amount)}",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        ],
                      );
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

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "0 expenses • Total ₹0",
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.receipt_long,
                size: 40,
                color: Color(0xFF12B886),
              ),
              const SizedBox(height: 14),
              Text(
                "No expenses yet",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Start adding your expenses to track them",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
              if (widget.onAddExpenseTap != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onAddExpenseTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12B886),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Add First Expense",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
