import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper class to assist with creating Firestore indexes
class FirestoreIndexHelper {
  /// Opens the Firebase console to create the required index
  static Future<void> openIndexCreationPage(BuildContext context, String indexUrl) async {
    // Clean up the URL if it contains any line breaks or spaces
    final cleanUrl = indexUrl.trim().replaceAll(RegExp(r'\s+'), '');
    
    try {
      final Uri uri = Uri.parse(cleanUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // If we can't launch the URL, show a dialog with instructions
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Create Firestore Index'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please create the required Firestore index by following these steps:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('1. Go to the Firebase Console'),
                  const Text('2. Select your project "taskswap-e4bd7"'),
                  const Text('3. Go to Firestore Database > Indexes'),
                  const Text('4. Click "Add Index"'),
                  const Text('5. Collection: notifications'),
                  const Text('6. Fields to index:'),
                  const Text('   - userId (Ascending)'),
                  const Text('   - timestamp (Descending)'),
                  const Text('7. Click "Create"'),
                  const SizedBox(height: 16),
                  const Text(
                    'After creating the index, it may take a few minutes to build.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Could not open the URL: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Shows a dialog to help create the notifications index
  static void showNotificationsIndexDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Notifications Index'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The app needs a Firestore index to properly display notifications.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Would you like to create this index now?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openIndexCreationPage(
                context,
                'https://console.firebase.google.com/project/taskswap-e4bd7/firestore/indexes?create-composite=ClRwcm9qZWNOcy90YXNrc3dhcC1lNGJkNy9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbm90aWZpY2F0aW9ucy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoNCglOaW1lc3RhbXAQAhoMCghfX25hbWVfXxAC',
              );
            },
            child: const Text('Create Index'),
          ),
        ],
      ),
    );
  }
}
