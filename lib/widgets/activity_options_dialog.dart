import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/models/activity_model.dart';
import 'package:taskswap/services/activity_service.dart';

class ActivityOptionsDialog extends StatefulWidget {
  final Activity activity;
  final VoidCallback onActivityUpdated;

  const ActivityOptionsDialog({
    super.key,
    required this.activity,
    required this.onActivityUpdated,
  });

  @override
  State<ActivityOptionsDialog> createState() => _ActivityOptionsDialogState();
}

class _ActivityOptionsDialogState extends State<ActivityOptionsDialog> {
  final ActivityService _activityService = ActivityService();
  bool _isLoading = false;
  bool _isDisposed = false;

  // Controllers for editing
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.activity.title);
    _descriptionController = TextEditingController(text: widget.activity.description);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _hideActivityFromFeed() async {
    if (_isLoading || _isDisposed) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Hiding activity with ID: ${widget.activity.id}');
      await _activityService.hideActivityFromFeed(widget.activity.id!);
      debugPrint('Activity hidden successfully');

      if (mounted) {
        Navigator.pop(context);
        // Force immediate UI update
        widget.onActivityUpdated();
        _showSnackBar('Activity hidden from your feed');
      }
    } catch (e) {
      debugPrint('Error hiding activity: $e');
      if (mounted) {
        _showSnackBar('Error hiding activity: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteActivity() async {
    if (_isLoading || _isDisposed) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Deleting activity with ID: ${widget.activity.id}');
      await _activityService.deleteActivity(widget.activity.id!);
      debugPrint('Activity deleted successfully');

      if (mounted) {
        Navigator.pop(context);
        // Force immediate UI update
        widget.onActivityUpdated();
        _showSnackBar('Activity deleted successfully');
      }
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      if (mounted) {
        _showSnackBar('Error deleting activity: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted || _isDisposed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              Navigator.pop(context);
              // Use a microtask to ensure the dialog is fully closed before proceeding
              Future.microtask(() => _deleteActivity());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showHideConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hide from Feed'),
        content: const Text('This activity will be hidden from your feed, but will still be visible to others. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              Navigator.pop(context);
              // Use a microtask to ensure the dialog is fully closed before proceeding
              Future.microtask(() => _hideActivityFromFeed());
            },
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Hide'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SimpleDialog(
      title: const Text('Activity Options'),
      children: [
        ListTile(
          leading: Icon(Icons.visibility_off, color: colorScheme.tertiary),
          title: const Text('Hide from Feed'),
          subtitle: const Text('Only you won\'t see this activity'),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
            _showHideConfirmation();
          },
        ),
        ListTile(
          leading: Icon(Icons.delete, color: Colors.red),
          title: const Text('Delete Activity'),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
            _showDeleteConfirmation();
          },
        ),
        ListTile(
          leading: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
          title: const Text('Cancel'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
