import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'dart:convert';

class CipherDrawer extends StatefulWidget {
  final List<String> availableEncodings;
  final String? selectedEncoding;
  final void Function(String?) onEncodingChanged;
  final VoidCallback onCreateCipher;
  final void Function(String) onThemeTextSelected;
  final void Function(String, int) onSpecificPuzzleSelected; // New callback for puzzle selection
  final bool autoSubstitutionEnabled;
  final void Function(bool) onAutoSubstitutionToggled;
  final bool keyAvailable;
  final bool keyVisible;
  final void Function(bool) onKeyVisibilityToggled;
  final VoidCallback onPrintCipher;

  const CipherDrawer({
    super.key,
    required this.availableEncodings,
    required this.selectedEncoding,
    required this.onEncodingChanged,
    required this.onCreateCipher,
    required this.onThemeTextSelected,
    required this.onSpecificPuzzleSelected, // Added new parameter
    required this.autoSubstitutionEnabled,
    required this.onAutoSubstitutionToggled,
    required this.keyAvailable,
    required this.keyVisible,
    required this.onKeyVisibilityToggled,
    required this.onPrintCipher,
  });

  @override
  _CipherDrawerState createState() => _CipherDrawerState();
}

class _CipherDrawerState extends State<CipherDrawer> {
  List<String> availableThemes = [];
  String? selectedTheme;
  int selectedPuzzleNumber = 0; // Default puzzle number
  Map<String, int> themePuzzleCounts = {}; // Stores number of puzzles per theme
  
  @override
  void initState() {
    super.initState();
    _loadAvailableThemes();
  }

  Future<void> _loadAvailableThemes() async {
    try {
      // Load the list of theme files from assets/themes/
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      Set<String> themes = {};
      for (String key in manifestMap.keys) {
        if (key.startsWith('assets/themes/') && key.endsWith('.txt')) {
          final parts = key.split('/');
          if (parts.length == 3) {
            themes.add(parts[2].replaceAll('.txt', ''));
          }
        }
      }
      
      setState(() {
        availableThemes = themes.toList()..sort();
        // Set first theme as default if available
        if (availableThemes.isNotEmpty) {
          selectedTheme = availableThemes.first;
          _loadPuzzleCountForTheme(selectedTheme!);
        }
      });
    } catch (e) {
      debugPrint('Error loading themes: $e');
    }
  }

  // Load puzzle count for the selected theme
  Future<void> _loadPuzzleCountForTheme(String theme) async {
    try {
      if (themePuzzleCounts.containsKey(theme)) {
        // Already loaded, set selected puzzle to first one
        setState(() {
          selectedPuzzleNumber = 0;
        });
        return;
      }
      
      final String themeContent = await rootBundle.loadString('assets/themes/$theme.txt');
      final List<String> textBlocks = themeContent.split('\n')
          .where((block) => block.trim().isNotEmpty)
          .toList();
      
      setState(() {
        themePuzzleCounts[theme] = textBlocks.length;
        selectedPuzzleNumber = 0; // Reset to first puzzle when theme changes
      });
    } catch (e) {
      debugPrint('Error counting puzzles in theme: $e');
      setState(() {
        themePuzzleCounts[theme] = 0;
        selectedPuzzleNumber = 0;
      });
    }
  }

  Future<void> _selectRandomTextFromTheme() async {
    if (selectedTheme == null) return;

    try {
      // Load the content of the selected theme file
      final String themeContent = await rootBundle.loadString('assets/themes/$selectedTheme.txt');
      
      // Split the content into text blocks
      final List<String> textBlocks = themeContent.split('\n');
      
      // Remove any empty blocks
      textBlocks.removeWhere((block) => block.trim().isEmpty);
      
      if (textBlocks.isNotEmpty) {
        // Select a random text block
        final Random random = Random();
        final String selectedText = textBlocks[random.nextInt(textBlocks.length)];
        
        // Call the callback to set the selected text
        widget.onThemeTextSelected(selectedText);
        
        // Close the drawer
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error selecting text from theme: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load text from $selectedTheme')),
      );
    }
  }

  // Load specific puzzle by index
  Future<void> _selectSpecificPuzzle() async {
    if (selectedTheme == null) return;

    try {
      // Load the content of the selected theme file
      final String themeContent = await rootBundle.loadString('assets/themes/$selectedTheme.txt');
      
      // Split the content into text blocks
      final List<String> textBlocks = themeContent.split('\n');
      
      // Remove any empty blocks
      textBlocks.removeWhere((block) => block.trim().isEmpty);
      
      if (textBlocks.isNotEmpty && selectedPuzzleNumber < textBlocks.length) {
        // Get the selected puzzle
        final String selectedText = textBlocks[selectedPuzzleNumber];
        
        // Call the callback to set the selected text with the puzzle number
        widget.onSpecificPuzzleSelected(selectedText, selectedPuzzleNumber);
        
        // Close the drawer
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid puzzle number: $selectedPuzzleNumber')),
        );
      }
    } catch (e) {
      debugPrint('Error selecting specific puzzle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load puzzle from $selectedTheme')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate puzzle numbers based on loaded theme
    final int puzzleCount = themePuzzleCounts[selectedTheme] ?? 0;
    final List<int> puzzleNumbers = List.generate(puzzleCount, (index) => index);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Crazy Crunchy Ciphers',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          
          // Encoding Type Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              value: widget.selectedEncoding,
              decoration: const InputDecoration(
                labelText: 'Encoding Type',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Random Letters'),
                ),
                ...widget.availableEncodings.map((String encoding) {
                  return DropdownMenuItem<String>(
                    value: encoding,
                    child: Text(encoding),
                  );
                }),
              ],
              onChanged: widget.onEncodingChanged,
            ),
          ),
          const SizedBox(height: 16),
          
          // Feature toggles section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Auto-Substitution Toggle Switch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Auto-Substitute Letters',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Fill matching letters automatically',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.autoSubstitutionEnabled,
                  onChanged: widget.onAutoSubstitutionToggled,
                ),
              ],
            ),
          ),
          
          // Key visibility toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Show Cipher Key',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Display the solution key',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.keyVisible,
                  onChanged: widget.keyAvailable ? widget.onKeyVisibilityToggled : null,
                  activeColor: widget.keyAvailable ? null : Colors.grey,
                ),
              ],
            ),
          ),
          
          const Divider(),

          // Print button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.print, color: Colors.white),
              label: const Text(
                'Print Current Cipher',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: widget.onPrintCipher,
            ),
          ),

          const Divider(),

          // Get A Cipher Text Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Get A Cipher Text',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Theme dropdown
                DropdownButtonFormField<String>(
                  value: selectedTheme,
                  decoration: const InputDecoration(
                    labelText: 'Theme',
                    border: OutlineInputBorder(),
                  ),
                  items: availableThemes.map((String theme) {
                    return DropdownMenuItem<String>(
                      value: theme,
                      child: Text(theme),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedTheme = newValue;
                      if (newValue != null) {
                        _loadPuzzleCountForTheme(newValue);
                      }
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // New puzzle selection dropdown
                DropdownButtonFormField<int>(
                  value: puzzleNumbers.contains(selectedPuzzleNumber) ? selectedPuzzleNumber : null,
                  decoration: const InputDecoration(
                    labelText: 'Puzzle Number',
                    border: OutlineInputBorder(),
                    hintText: 'Select a specific puzzle',
                  ),
                  items: puzzleNumbers.map((int index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text('Puzzle ${index + 1}'),
                    );
                  }).toList(),
                  onChanged: puzzleNumbers.isEmpty 
                      ? null 
                      : (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedPuzzleNumber = newValue;
                            });
                          }
                        },
                ),
                
                const SizedBox(height: 12),
                
                // Row of buttons for random vs specific puzzle
                Row(
                  children: [
                    // Load specific puzzle button
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.filter_1),
                        label: const Text('Load Selected'),
                        onPressed: puzzleNumbers.isEmpty ? null : _selectSpecificPuzzle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Random puzzle button
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shuffle),
                        label: const Text('Random'),
                        onPressed: _selectRandomTextFromTheme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Create My Own'),
            onTap: () {
              Navigator.pop(context);
              widget.onCreateCipher();
            },
          ),
        ],
      ),
    );
  }
}