import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using the wallet animation as a placeholder for connectivity issues
            // In a real app, we might use a specific "no connection" Lottie.
            Center(
              child: SizedBox(
                height: 250,
                child: Lottie.asset(
                  'assets/icon/wallet_animation.json',
                  repeat: true,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "No Internet Connection",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "It looks like you're offline. Please check your internet connection to continue using Spendee.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF16B888).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF16B888),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Waiting for connection...",
                    style: TextStyle(
                      color: Color(0xFF16B888),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
