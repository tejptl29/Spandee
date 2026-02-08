import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../signup/view/signup_screen.dart';
import '../../utils/custom_toast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isPasswordHidden = true;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = "User is not registered. Please sign up.";
          break;
        case 'wrong-password':
          message = "Incorrect password. Please try again.";
          break;
        case 'invalid-credential':
          message = "Invalid email or password. Please check and try again.";
          break;
        case 'invalid-email':
          message = "Invalid email address.";
          break;
        case 'user-disabled':
          message = "This account has been disabled.";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Try again later.";
          break;
        case 'network-request-failed':
          message = "No internet connection. Please check your settings.";
          break;
        default:
          message = "Login failed (${e.code}). Please try again.";
      }

      if (mounted) {
        CustomToast.show(context, message, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          "Error: ${e.toString()}",
          type: ToastType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).primaryColor.withAlpha(20),
                  ]
                : const [Color(0xFFFFFFFF), Color(0xFFEFF5EF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 30),

                /// Logo
                Lottie.asset(
                  'assets/icon/wallet_animation.json',
                  width: 140,
                  height: 140,
                ),

                const SizedBox(height: 10),

                Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Login to manage your expenses",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                    border: isDark
                        ? Border.all(color: Colors.white.withAlpha(20))
                        : null,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _inputField(
                          context: context,
                          controller: emailController,
                          hint: "Email",
                          icon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Email is required";
                            }
                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value.trim())) {
                              return "Enter a valid email";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _inputField(
                          context: context,
                          controller: passwordController,
                          hint: "Password",
                          icon: Icons.lock_outline,
                          obscure: _isPasswordHidden,
                          suffix: IconButton(
                            icon: Icon(
                              _isPasswordHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF16B888),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordHidden = !_isPasswordHidden;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Password is required";
                            }
                            if (value.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 26),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      _login();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16B888),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    icon: SvgPicture.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      height: 24,
                    ),
                    label: Text(
                      "Continue with Google",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardTheme.color,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha(20)
                            : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      try {
                        await _authService.signInWithGoogle();
                      } catch (e) {
                        if (!context.mounted) return;
                        CustomToast.show(
                          context,
                          "Google Sign-In Failed: $e",
                          type: ToastType.error,
                        );
                      } finally {
                        if (context.mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    },
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF16B888),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF16B888)),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(10) : Colors.grey[100],
        errorStyle: const TextStyle(color: Colors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF16B888), width: 1.5),
        ),
      ),
    );
  }
}
