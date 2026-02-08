import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:spendee/Dashboard/view/overview_screen.dart';
import 'package:spendee/Dashboard/view/profile_screen.dart';
import 'package:spendee/core/theme/theme_provider.dart';
import 'package:spendee/core/widgets/sync_indicator.dart';
import 'package:spendee/utils/logout_dialog.dart';
import 'add_expance_screen.dart';
import 'expance_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Editing state
  String? _editingId;
  int? _initialAmount;
  String? _initialCategory;
  DateTime? _initialDate;
  int _addKey = 0; // Increment this to reset the AddExpanceScreen

  void _handleEdit(Map<String, dynamic> data) {
    setState(() {
      _editingId = data['id'];
      _initialAmount = data['amount'];
      _initialCategory = data['category'];
      _initialDate = data['date'];
      _addKey++;
      // Update only the AddExpanceScreen in the cached list
      _screens[1] = _buildAddScreen();
      _selectedIndex = 1;
    });
  }

  void _resetAddForm() {
    setState(() {
      _editingId = null;
      _initialAmount = null;
      _initialCategory = null;
      _initialDate = null;
      _addKey++;
      // Reset only the AddExpanceScreen in the cached list
      _screens[1] = _buildAddScreen();
    });
  }

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initScreens();
  }

  void _initScreens() {
    _screens = [
      OverviewScreen(
        onAddExpenseTap: () {
          _resetAddForm();
          setState(() {
            _selectedIndex = 1;
          });
        },
        onViewAllTap: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
      ),
      _buildAddScreen(),
      ExpanceHistoryScreen(
        onAddExpenseTap: () {
          _resetAddForm();
          setState(() {
            _selectedIndex = 1;
          });
        },
        onEditExpense: _handleEdit,
      ),
      const ProfileScreen(),
    ];
  }

  Widget _buildAddScreen() {
    return AddExpanceScreen(
      key: ValueKey('add_$_addKey'),
      expenseId: _editingId,
      initialAmount: _initialAmount,
      initialCategory: _initialCategory,
      initialDate: _initialDate,
      onSuccess: () {
        _resetAddForm();
        setState(() {
          _selectedIndex = 2; // Switch to History
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => ConfirmDialog(
            title: "Exit App",
            message: "Are you sure you want to exit Spendee?",
            confirmText: "Exit",
            cancelText: "Stay",
            icon: Icons.exit_to_app_rounded,
            iconColor: Theme.of(context).primaryColor,
            onConfirm: () => Navigator.pop(context, true),
          ),
        );

        if (shouldExit == true) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              IndexedStack(index: _selectedIndex, children: _screens),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SyncIndicator(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
          ),
          child: NavigationBar(
            height: 70,
            elevation: 0,
            backgroundColor: Theme.of(context).cardTheme.color,
            indicatorColor: isDark
                ? const Color(0xFF16B888).withAlpha(40)
                : const Color(0xFFB9F6CA),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (index == 1) {
                _resetAddForm();
              }
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(
                  Icons.dashboard,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: const Icon(Icons.add),
                selectedIcon: Icon(
                  Icons.add,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Add',
              ),
              NavigationDestination(
                icon: const Icon(Icons.history),
                selectedIcon: Icon(
                  Icons.history,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Expense',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
