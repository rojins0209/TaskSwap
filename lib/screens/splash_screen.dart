import 'package:flutter/material.dart';
import 'package:taskswap/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Icon(
              Icons.swap_horiz_rounded,
              size: 100,
              color: AppTheme.accentColor,
            ),
            const SizedBox(height: 24),
            // App name
            Text(
              'TaskSwap',
              style: AppTheme.headingLarge,
            ),
            const SizedBox(height: 16),
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
