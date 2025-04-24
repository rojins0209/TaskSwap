import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:taskswap/utils/analytics_test.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final String _supportEmail = 'rojinssmartin@gmail.com';
  String _appVersion = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Unknown';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendEmail(String subject) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=$subject',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          _showSnackBar('Could not launch email client');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // FAQ Section
                _buildSection(
                  title: 'Frequently Asked Questions',
                  icon: Icons.question_answer_outlined,
                  children: [
                    _buildFaqItem(
                      question: 'What is TaskSwap?',
                      answer: 'TaskSwap is a productivity app that helps you manage tasks, challenge friends, and earn aura points for completing activities. It combines task management with social features to make productivity more engaging and fun.',
                    ),
                    _buildFaqItem(
                      question: 'How do I earn aura points?',
                      answer: 'You can earn aura points by completing tasks, winning challenges, and receiving aura gifts from friends. The more consistent you are with completing tasks, the more points you\'ll earn!',
                    ),
                    _buildFaqItem(
                      question: 'What are streaks?',
                      answer: 'Streaks track your consecutive days of activity. Complete at least one task each day to build your streak. Longer streaks earn you bonus aura points!',
                    ),
                    _buildFaqItem(
                      question: 'How do challenges work?',
                      answer: 'You can challenge friends to complete specific tasks. When both you and your friend complete the challenge, you both earn bonus aura points. It\'s a fun way to stay accountable and motivate each other!',
                    ),
                    _buildFaqItem(
                      question: 'Can I customize my profile?',
                      answer: 'Yes! You can upload a profile picture or choose from our predefined avatars. You can also set your display name and customize your privacy settings.',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Contact Support Section
                _buildSection(
                  title: 'Contact Support',
                  icon: Icons.support_agent,
                  children: [
                    _buildSupportOption(
                      title: 'Report a Bug',
                      subtitle: 'Let us know if something isn\'t working correctly',
                      icon: Icons.bug_report_outlined,
                      onTap: () => _sendEmail('TaskSwap Bug Report'),
                    ),
                    _buildSupportOption(
                      title: 'Feature Request',
                      subtitle: 'Suggest new features or improvements',
                      icon: Icons.lightbulb_outline,
                      onTap: () => _sendEmail('TaskSwap Feature Request'),
                    ),
                    _buildSupportOption(
                      title: 'General Support',
                      subtitle: 'Get help with any other issues',
                      icon: Icons.help_outline,
                      onTap: () => _sendEmail('TaskSwap Support Request'),
                    ),
                    _buildSupportOption(
                      title: 'Email Support',
                      subtitle: _supportEmail,
                      icon: Icons.email_outlined,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: _supportEmail));
                        if (mounted) {
                          _showSnackBar('Email address copied to clipboard');
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // App Info Section
                _buildSection(
                  title: 'App Information',
                  icon: Icons.info_outline,
                  children: [
                    ListTile(
                      title: const Text('Version'),
                      subtitle: Text(_appVersion),
                      leading: Icon(
                        Icons.new_releases_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    _buildSupportOption(
                      title: 'Terms of Service',
                      subtitle: 'Read our terms of service',
                      icon: Icons.description_outlined,
                      onTap: () {
                        // TODO: Navigate to terms of service screen or launch URL
                        _showSnackBar('Terms of Service will be available soon');
                      },
                    ),
                    _buildSupportOption(
                      title: 'Privacy Policy',
                      subtitle: 'Read our privacy policy',
                      icon: Icons.privacy_tip_outlined,
                      onTap: () {
                        // TODO: Navigate to privacy policy screen or launch URL
                        _showSnackBar('Privacy Policy will be available soon');
                      },
                    ),
                    _buildSupportOption(
                      title: 'Test Analytics',
                      subtitle: 'Test Firebase Analytics connection',
                      icon: Icons.analytics_outlined,
                      onTap: () {
                        // Test Firebase Analytics
                        AnalyticsTest.testAnalytics(context);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // App credits
                Center(
                  child: Column(
                    children: [
                      Text(
                        'TaskSwap',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '© 2025 TaskSwap. All rights reserved.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Developed by RØJINS',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(50),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ExpansionTile(
      title: Text(
        question,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      collapsedIconColor: colorScheme.primary,
      iconColor: colorScheme.primary,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildSupportOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      leading: Icon(
        icon,
        color: colorScheme.primary,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}
