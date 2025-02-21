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
        selectedTheme = availableThemes.isNotEmpty ? availableThemes.first : null;
      });
    } catch (e) {
      debugPrint('Error loading themes: $e');
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

  @override
  Widget build(BuildContext context) {
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
                    });
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _selectRandomTextFromTheme,
                  child: const Text('Give me a Cipher!'),
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