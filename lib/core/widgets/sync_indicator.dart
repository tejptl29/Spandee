import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:spendee/core/services/connectivity_service.dart';

class SyncIndicator extends StatefulWidget {
  const SyncIndicator({super.key});

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  bool _isOffline = false;
  bool _showOnlineBar = false;
  Timer? _timer;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _subscribeToConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final isConnected = await ConnectivityService().isConnected;
    if (mounted) {
      setState(() {
        _isOffline = !isConnected;
      });
    }
  }

  void _subscribeToConnectivity() {
    _subscription = ConnectivityService().connectivityStream.listen((results) {
      final isNowOffline = results.contains(ConnectivityResult.none);

      if (mounted) {
        if (_isOffline && !isNowOffline) {
          // Transition: Offline -> Online
          setState(() {
            _isOffline = false;
            _showOnlineBar = true;
          });

          _timer?.cancel();
          _timer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showOnlineBar = false;
              });
            }
          });
        } else if (isNowOffline != _isOffline) {
          setState(() {
            _isOffline = isNowOffline;
            if (isNowOffline) {
              _showOnlineBar = false;
              _timer?.cancel();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return _buildIndicator(isOffline: true);
    } else if (_showOnlineBar) {
      return _buildIndicator(isOffline: false);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildIndicator({required bool isOffline}) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: isOffline
              ? const Color(0xFFF57C00).withAlpha(230)
              : const Color(0xFF2E7D32).withAlpha(230),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isOffline ? "Offline" : "Online",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
