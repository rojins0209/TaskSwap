import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taskswap/services/aura_gift_service.dart';
import 'package:taskswap/services/user_service.dart';
import 'package:taskswap/theme/app_theme.dart';

class GiveAuraDialog extends StatefulWidget {
  final String receiverId;
  final VoidCallback? onAuraGiven;
  final String? taskId;
  final String? taskTitle;

  const GiveAuraDialog({
    super.key,
    required this.receiverId,
    this.onAuraGiven,
    this.taskId,
    this.taskTitle,
  });

  @override
  State<GiveAuraDialog> createState() => _GiveAuraDialogState();
}

class _GiveAuraDialogState extends State<GiveAuraDialog> {
  final AuraGiftService _auraGiftService = AuraGiftService();
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();

  int _selectedPoints = 5;
  bool _isLoading = false;
  String _receiverName = '';

  final List<int> _pointOptions = [1, 2, 5, 10, 20];

  @override
  void initState() {
    super.initState();
    _loadReceiverName();
    _checkPrivacySettings();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadReceiverName() async {
    try {
      final receiver = await _userService.getUserById(widget.receiverId);
      if (receiver != null && mounted) {
        setState(() {
          _receiverName = receiver.displayName ?? 'User';
        });
      }
    } catch (e) {
      debugPrint('Error loading receiver name: $e');
    }
  }

  Future<void> _checkPrivacySettings() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You need to be logged in to give aura points'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if the current user can give aura to the receiver
      final canGiveAura = await _userService.canGiveAuraTo(currentUser.uid, widget.receiverId);
      if (!canGiveAura && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You cannot give aura to $_receiverName due to privacy settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking privacy settings: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _giveAura() async {
    if (_isLoading) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _auraGiftService.giveAura(
        receiverId: widget.receiverId,
        points: _selectedPoints,
        message: _messageController.text.trim().isNotEmpty ? _messageController.text.trim() : null,
        taskId: widget.taskId,
        taskTitle: widget.taskTitle,
      );

      if (mounted) {
        Navigator.of(context).pop();

        // Call the callback if provided
        widget.onAuraGiven?.call();

        // Show a success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully gave $_selectedPoints aura points to $_receiverName!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error giving aura: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: AppTheme.accentColor,
          ),
          const SizedBox(width: 8),
          const Text('Give Aura Points'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Give aura points to $_receiverName',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Points selection
            Text(
              'Select points to give:',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _pointOptions.map((points) => _buildPointChip(points)).toList(),
            ),
            const SizedBox(height: 16),

            // Message input
            Text(
              'Add a message (optional):',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Great job!',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 2,
              maxLength: 100,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _giveAura,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(_isLoading ? 'Giving...' : 'Give $_selectedPoints Points'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPointChip(int points) {
    final isSelected = _selectedPoints == points;

    return ChoiceChip(
      label: Text('$points'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPoints = points;
          });
        }
      },
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.accentColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
