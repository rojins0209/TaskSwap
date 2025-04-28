import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showBanner ? 0 : -100, // Slide in from top
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isConnected
                          ? [Colors.green.shade300, Colors.green.shade700]
                          : [Colors.red.shade300, Colors.red.shade700],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isConnected ? Colors.green.withAlpha(40) : Colors.red.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated icon
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _isConnected ? Icons.wifi : Icons.wifi_off,
                            key: ValueKey<bool>(_isConnected),
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Animated text
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _isConnected
                                ? 'Connected to the internet'
                                : 'You are offline',
                            key: ValueKey<bool>(_isConnected),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Dismiss button
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _showBanner = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
