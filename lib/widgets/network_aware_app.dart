import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:taskswap/utils/error_handler.dart';

/// A widget that wraps the entire app and provides network connectivity awareness
class NetworkAwareApp extends StatefulWidget {
  final Widget child;
  final Function(bool isConnected)? onConnectivityChanged;

  const NetworkAwareApp({
    super.key,
    required this.child,
    this.onConnectivityChanged,
  });

  @override
  State<NetworkAwareApp> createState() => _NetworkAwareAppState();
}

class _NetworkAwareAppState extends State<NetworkAwareApp> {
  bool _isConnected = true;
  bool _showBanner = false;
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      setState(() {
        _isConnected = false;
        _showBanner = true;
      });
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;
    final isNowConnected = result != ConnectivityResult.none;

    setState(() {
      _isConnected = isNowConnected;

      // Only show the banner when connectivity changes
      if (wasConnected != isNowConnected) {
        _showBanner = true;

        // Hide the banner after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showBanner = false;
            });
          }
        });
      }
    });

    // Notify parent
    if (widget.onConnectivityChanged != null) {
      widget.onConnectivityChanged!(_isConnected);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a non-directional alignment and explicit textDirection to avoid the Directionality error
    return Stack(
      alignment: Alignment.topCenter, // Use Alignment instead of AlignmentDirectional
      textDirection: TextDirection.ltr, // Explicitly set text direction
      fit: StackFit.loose,
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showBanner ? 40 : 0,
                color: _isConnected ? Colors.green : Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isConnected ? Icons.wifi : Icons.wifi_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isConnected
                            ? 'Connected to the internet'
                            : ErrorHandler.offlineErrorMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
