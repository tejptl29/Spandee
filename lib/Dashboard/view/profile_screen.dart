import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendee/core/theme/theme_provider.dart';
import 'package:spendee/services/app_pref.dart';
import 'package:spendee/services/auth_service.dart';
import 'package:spendee/utils/custom_toast.dart';
import 'package:spendee/utils/logout_dialog.dart';
import 'package:spendee/Dashboard/view/historical_data_screen.dart';
import 'package:spendee/Dashboard/view/premium_upgrade_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  Future<void> _fetchUserEmail() async {
    String? email = await AppPref().getEmail();

    // Fallback to FirebaseAuth if AppPref is empty
    if (email == null || email.isEmpty) {
      email = AuthService().currentUser?.email;
    }

    if (mounted) {
      setState(() {
        _userEmail = email;
      });
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool isLoading = false;
    bool showNewPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardTheme.color,
              scrollable: true,
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 10,
              content: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          const Icon(Icons.lock_reset, size: 26),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Change Password",
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Email (readonly)
                      TextFormField(
                        initialValue: _userEmail,
                        enabled: false,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          labelText: "Email",
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withAlpha(15)
                              : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // New password
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: !showNewPassword,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(() {
                              showNewPassword = !showNewPassword;
                            }),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                Theme.of(context).brightness == Brightness.dark
                                ? BorderSide(color: Colors.white.withAlpha(40))
                                : BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withAlpha(10)
                              : Colors.grey[50],
                        ),
                        validator: (value) => value == null || value.length < 6
                            ? "Minimum 6 characters"
                            : null,
                      ),

                      const SizedBox(height: 32),

                      // Actions
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  setState(() => isLoading = true);

                                  try {
                                    await AuthService().changePassword(
                                      newPassword: newPasswordController.text,
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      CustomToast.show(
                                        context,
                                        "Password updated successfully",
                                        type: ToastType.success,
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      CustomToast.show(
                                        context,
                                        e.toString().replaceAll(
                                          "Exception: ",
                                          "",
                                        ),
                                        type: ToastType.error,
                                      );
                                    }
                                  } finally {
                                    if (context.mounted) {
                                      setState(() => isLoading = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16B888),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Update Password",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header
                Text(
                  "Profile",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 24),

                /// User Info Card
                _card(
                  context: context,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeProvider.isDarkMode
                              ? Colors.teal.withAlpha(40)
                              : const Color(0xFFE6F8F2),
                        ),
                        child: Icon(
                          Icons.person,
                          color: themeProvider.isDarkMode
                              ? Colors.teal.shade300
                              : const Color(0xFF12B886),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userEmail ?? "Loading...",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Expense Tracker User",
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// Appearance Card (Dark Mode Toggle)
                _card(
                  context: context,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeProvider.isDarkMode
                              ? Colors.orange.withAlpha(40)
                              : Colors.orange.withAlpha(15),
                        ),
                        child: Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Dark Mode",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              themeProvider.isDarkMode
                                  ? "Switch to light mode"
                                  : "Switch to dark mode",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: themeProvider.isDarkMode,
                        activeThumbColor: const Color(0xFF16B888),
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// Premium Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiumUpgradeScreen(),
                      ),
                    );
                  },
                  child: _card(
                    context: context,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber.withAlpha(
                              themeProvider.isDarkMode ? 40 : 15,
                            ),
                          ),
                          child: const Icon(
                            Icons.stars_rounded,
                            color: Colors.amber,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Premium Access",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                "Unlock PDF downloads and more",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(100),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// Historical Data Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoricalDataScreen(),
                      ),
                    );
                  },
                  child: _card(
                    context: context,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeProvider.isDarkMode
                                ? Colors.purple.withAlpha(40)
                                : Colors.purple.withAlpha(15),
                          ),
                          child: Icon(
                            Icons.history_edu,
                            color: Colors.purple,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Expense History",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                "View all past expenses",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(100),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // // Reset password
                // _card(
                //   context: context,
                //   child: Row(
                //     children: [

                //     ],
                //   ),
                // ),

                /// Change Password Card
                GestureDetector(
                  onTap: () {
                    _showChangePasswordDialog(context);
                  },
                  child: _card(
                    context: context,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeProvider.isDarkMode
                                ? Colors.blue.withAlpha(40)
                                : Colors.blue.withAlpha(15),
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.blue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Change Password",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                "Update your account password",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(100),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// App Info Card
                _card(
                  context: context,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeProvider.isDarkMode
                              ? Colors.teal.withAlpha(40)
                              : const Color(0xFFE6F8F2),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: themeProvider.isDarkMode
                              ? Colors.teal.shade300
                              : const Color(0xFF12B886),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Expense Tracker",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Version 1.0.0",
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "A simple app to track your monthly expenses. Keep your finances in check!",
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// Logout Button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.red.withAlpha(40)
                        : const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ConfirmDialog(
                          title: "Logout",
                          message: "Are you sure you want to logout?",
                          confirmText: "Logout",
                          cancelText: "Cancel",
                          onConfirm: () async {
                            Navigator.pop(context); // close dialog
                            await AuthService().signOut();
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text(
                      "Log Out",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
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

  /// Reusable Card
  Widget _card({required BuildContext context, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withAlpha(20)
              : Colors.grey.shade200,
        ),
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : Colors.black.withAlpha(20),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
