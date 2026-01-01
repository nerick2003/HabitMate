import 'package:flutter/material.dart';

class NoteDialog extends StatefulWidget {
  final String? initialNote;
  final String habitName;

  const NoteDialog({
    super.key,
    this.initialNote,
    required this.habitName,
  });

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Note - ${widget.habitName}'),
      content: TextField(
        controller: _noteController,
        decoration: const InputDecoration(
          hintText: 'How did it go? What did you learn?',
          border: OutlineInputBorder(),
        ),
        maxLines: 5,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _noteController.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

