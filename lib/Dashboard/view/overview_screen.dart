import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:spendee/Dashboard/view/start_month_screen.dart';
import 'package:spendee/services/auth_service.dart';
import 'package:spendee/utils/logout_dialog.dart';

import 'package:spendee/Dashboard/view/widget/expance_chart.dart';
import 'package:provider/provider.dart';
import 'package:spendee/core/theme/theme_provider.dart';
import 'package:spendee/core/utils/category_utils.dart';
import 'add_expance_screen.dart';

class OverviewScreen extends StatefulWidget {
  final VoidCallback? onAddExpenseTap;
  final VoidCallback? onViewAllTap;

  const OverviewScreen({super.key, this.onAddExpenseTap, this.onViewAllTap});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              themeProvider.isDarkMode
                  ? Theme.of(context).primaryColor.withAlpha(30)
                  : const Color(0xFFEFF5EF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              final userData =
                  userSnapshot.data?.data() as Map<String, dynamic>?;
              final lastBudgetMonth = userData?['lastBudgetMonth'] ?? '';
              final lastBudgetAmount = userData?['lastBudgetAmount'] as int?;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('expenses')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmerLoading(currentMonth);
                  }

                  int totalSpent = 0;
                  List<QueryDocumentSnapshot> recentExpenses = [];

                  if (snapshot.hasData) {
                    final allDocs = snapshot.data!.docs;
                    final now = DateTime.now();

                    // Filter for current month and calculate total spent
                    for (var doc in allDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = (data['date'] as Timestamp).toDate();
                      if (date.month == now.month && date.year == now.year) {
                        totalSpent += (data['amount'] as num).toInt();
                      }
                    }

                    // Get 5 most recent
                    recentExpenses = allDocs.take(5).toList();
                  }

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dashboard',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.logout,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ConfirmDialog(
                                      title: "Logout",
                                      message:
                                          "Are you sure you want to logout?",
                                      confirmText: "Logout",
                                      cancelText: "Cancel",
                                      onConfirm: () async {
                                        Navigator.pop(context); // close dialog
                                        await AuthService().signOut();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // Add Month Budget Button (if not set)
                          if (lastBudgetMonth != currentMonth) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const StartMonthPage(),
                                    ),
                                  );
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                    Theme.of(context).cardTheme.color,
                                  ),
                                  foregroundColor: WidgetStateProperty.all(
                                    const Color(0xFF16B888),
                                  ),
                                  shape: WidgetStateProperty.resolveWith((
                                    states,
                                  ) {
                                    return RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color:
                                            states.contains(WidgetState.pressed)
                                            ? Colors.greenAccent
                                            : const Color(0xFF16B888),
                                        width: 1.5,
                                      ),
                                    );
                                  }),
                                ),

                                child: const Text(
                                  'Add Month Budget',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // No Budget Spending Summary Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white.withAlpha(20)
                                      : Colors.black12,
                                  width: 1,
                                ),
                                boxShadow: themeProvider.isDarkMode
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(10),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Spent',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${NumberFormat('#,##,###').format(totalSpent)}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sets a budget to track savings',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 30),
                          // Current Month Budget Card
                          if (lastBudgetMonth == currentMonth)
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StartMonthPage(
                                      initialBudget: lastBudgetAmount,
                                    ),
                                  ),
                                );
                                // No manual refresh needed, StreamBuilder handles it!
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: themeProvider.isDarkMode
                                        ? Colors.white.withAlpha(20)
                                        : Colors.black12,
                                    width: 1,
                                  ),
                                  boxShadow: themeProvider.isDarkMode
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(10),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Row: Title and Edit
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'This Month\'s Budget',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(100),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Budget Row: Total Budget
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          currentMonth,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          '₹${NumberFormat('#,##,###').format(lastBudgetAmount ?? 0)}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF16B888),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // New Row: Spent and Remaining
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Spent Container
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withAlpha(
                                                themeProvider.isDarkMode
                                                    ? 40
                                                    : 30,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Spent',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '₹${NumberFormat('#,##,###').format(totalSpent)}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Remaining Container
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withAlpha(
                                                themeProvider.isDarkMode
                                                    ? 40
                                                    : 30,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Remaining',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '₹${NumberFormat('#,##,###').format((lastBudgetAmount ?? 0) - totalSpent)}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                // Navigate to Add Expense Screen
                                if (widget.onAddExpenseTap != null) {
                                  widget.onAddExpenseTap!();
                                } else {
                                  // Fallback or legacy behavior
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AddExpanceScreen(),
                                    ),
                                  );
                                  // No manual refresh needed, StreamBuilder handles it!
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16B888),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: const Color(
                                  0xFF16B888,
                                ).withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                'Add Expense',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Recent Expenses",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (widget.onViewAllTap != null) {
                                    widget.onViewAllTap!();
                                  }
                                },
                                child: Text(
                                  "View All",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 400),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: themeProvider.isDarkMode
                                    ? Colors.white.withAlpha(20)
                                    : Colors.black12,
                                width: 1,
                              ),
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: recentExpenses.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 40,
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Wallet Animation
                                        Lottie.asset(
                                          'assets/icon/wallet_animation.json',
                                          height: 180,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          "No expenses yet",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: themeProvider.isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Start tracking your spending\nto see insights here.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: themeProvider.isDarkMode
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: recentExpenses.length,
                                    itemBuilder: (context, index) {
                                      final data =
                                          recentExpenses[index].data()
                                              as Map<String, dynamic>;
                                      final category =
                                          (data['category'] as String?) ??
                                          'Other';
                                      final amount = (data['amount'] as num)
                                          .toInt();
                                      final date = (data['date'] as Timestamp)
                                          .toDate();

                                      return ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: themeProvider.isDarkMode
                                                ? Colors.white.withAlpha(10)
                                                : const Color(0xFFF1F3F5),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            CategoryUtils.getCategoryIcon(
                                              category,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          category,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        subtitle: Text(
                                          DateFormat(
                                            'dd MMM yyyy | hh:mm a',
                                          ).format(date),
                                        ),
                                        trailing: Text(
                                          '₹${NumberFormat('#,##,###').format(amount)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          // Add the Expense Chart here
                          const SizedBox(height: 10),
                          ExpenseChart(
                            expenses: snapshot.data!.docs,
                            selectedMonth: DateTime.now(),
                          ),
                          const SizedBox(height: 10),
                          // Center(
                          //   child: Opacity(
                          //     opacity: 0.5,
                          //     child: Image.asset(
                          //       'assets/icon/appLogo.png',
                          //       height: 40,
                          //       fit: BoxFit.contain,
                          //     ),
                          //   ),
                          // ),
                          Center(
                            child: Text(
                              "© ${DateTime.now().year} Spendee. All rights reserved.",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(100),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(String currentMonth) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 150,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
            // Budget Card Shimmer
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 20),
            // Add Button Shimmer
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 40),
            // Recent Title Shimmer
            Container(
              width: 180,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 15),
            // List Items Shimmer
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                padding: EdgeInsets.zero,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 60,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Container(width: 50, height: 15, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
