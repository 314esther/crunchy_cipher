import 'package:flutter/material.dart';

class RightDrawer extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onClear;
  final List<String> savedPuzzles;
  final Function(String) onLoadPuzzle;

  const RightDrawer({
    Key? key,
    required this.onSave,
    required this.onClear,
    required this.savedPuzzles,
    required this.onLoadPuzzle,
  }) : super(key: key);

  @override
  State<RightDrawer> createState() => _RightDrawerState();
}

class _RightDrawerState extends State<RightDrawer> {
  bool _showSavedPuzzles = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.indigo,
            width: double.infinity,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30), // Add space for status bar
                Text(
                  'Puzzle Actions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Save, load, or clear puzzles',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Save button
                ListTile(
                  leading: const Icon(Icons.save_outlined),
                  title: const Text('Save Puzzle'),
                  subtitle: const Text('Save your current progress'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    widget.onSave();
                  },
                ),

                // Load button with expandable menu
                ExpansionTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: const Text('Load Puzzle'),
                  subtitle: const Text('Restore a saved puzzle'),
                  initiallyExpanded: _showSavedPuzzles,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _showSavedPuzzles = expanded;
                    });
                  },
                  children: widget.savedPuzzles.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No saved puzzles yet',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        ]
                      : widget.savedPuzzles.map((puzzle) {
                          return ListTile(
                            contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
                            title: Text(puzzle),
                            trailing: const Icon(Icons.play_arrow),
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              widget.onLoadPuzzle(puzzle);
                            },
                          );
                        }).toList(),
                ),

                const Divider(),

                // Clear button
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined, color: Colors.red),
                  title: const Text('Clear Puzzle'),
                  subtitle: const Text('Reset all your answers'),
                  textColor: Colors.red,
                  onTap: () {
                    // Ask for confirmation before clearing
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Clear Puzzle'),
                          content: const Text(
                            'Are you sure you want to clear all your answers?'
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: const Text('Clear'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () {
                                Navigator.of(context).pop(); // Close dialog
                                Navigator.pop(context); // Close drawer
                                widget.onClear();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}