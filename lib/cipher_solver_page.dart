import 'dart:math';
import 'package:flutter/material.dart';
import 'package:selector_wheel/selector_wheel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'widgets/cipher_drawer.dart';
import 'widgets/cipher_key_display.dart';
import 'widgets/right_drawer.dart';
import 'utils/pdf_generator.dart';
import 'cipher_solver_state.dart';
import 'widgets/minimal_letter_wheel.dart';
import 'dart:async';

class CipherSolverPage extends StatefulWidget {
  final bool showInstructions;
  
  const CipherSolverPage({
    super.key, 
    this.showInstructions = false
  });

  @override
  State<CipherSolverPage> createState() => CipherSolverPageState();
}

class CipherSolverPageState extends State<CipherSolverPage> with CipherSolverStateBase {
  // List to store saved puzzles
  final List<String> _savedPuzzles = [];
  final Map<String, Map<String, dynamic>> _savedPuzzleData = {};
  
  @override
  void initState() {
    super.initState();
    
    // Show instruction dialog after the page is built
    if (widget.showInstructions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInstructionsDialog();
      });
    }
    
    // Add this section to explain the new wheel selector
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Show a one-time tooltip about the wheel selector
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tap on letter boxes to use the letter wheel selector'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Got it',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
    
    // Load saved puzzles from persistent storage
    _loadSavedPuzzles();
  }
  
  // Load saved puzzles from SharedPreferences
  Future<void> _loadSavedPuzzles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNames = prefs.getStringList('savedPuzzleNames') ?? [];
      
      for (String name in savedNames) {
        final puzzleDataJson = prefs.getString('puzzle_$name');
        if (puzzleDataJson != null) {
          try {
            final Map<String, dynamic> puzzleData = json.decode(puzzleDataJson);
            
            // Ensure proper structure of loaded data
            if (!puzzleData.containsKey('originalText') || 
                !puzzleData.containsKey('substitutionMap') || 
                !puzzleData.containsKey('userAnswers')) {
              print("Invalid puzzle data format for $name");
              continue;
            }
            
            // Convert substitutionMap values
            final Map<String, dynamic> subMap = puzzleData['substitutionMap'];
            final convertedSubMap = <String, String>{};
            subMap.forEach((key, value) {
              convertedSubMap[key.toString()] = value.toString();
            });
            puzzleData['substitutionMap'] = convertedSubMap;
            
            // Convert userAnswers values
            final Map<String, dynamic> userAnswers = puzzleData['userAnswers'];
            final convertedAnswers = <String, String>{};
            userAnswers.forEach((key, value) {
              convertedAnswers[key.toString()] = value.toString();
            });
            puzzleData['userAnswers'] = convertedAnswers;
            
            // Add to saved puzzles list and data
            setState(() {
              _savedPuzzles.add(name);
              _savedPuzzleData[name] = puzzleData;
            });
          } catch (e) {
            print("Error parsing puzzle data for $name: $e");
          }
        }
      }
      
      print("Loaded ${_savedPuzzles.length} puzzles from storage");
    } catch (e) {
      print("Error loading saved puzzles: $e");
    }
  }
  
  // Save all puzzles to SharedPreferences
  Future<void> _savePuzzlesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save the list of puzzle names
      await prefs.setStringList('savedPuzzleNames', _savedPuzzles);
      
      // Save each puzzle's data
      for (String name in _savedPuzzles) {
        final puzzleData = _savedPuzzleData[name];
        if (puzzleData != null) {
          final jsonData = json.encode(puzzleData);
          await prefs.setString('puzzle_$name', jsonData);
        }
      }
      
      print("Saved ${_savedPuzzles.length} puzzles to storage");
    } catch (e) {
      print("Error saving puzzles to storage: $e");
    }
  }
  
  // Methods for right drawer functionality
  void _savePuzzle() {
    // Generate a timestamp-based name for the puzzle
    final now = DateTime.now();
    final puzzleName = "Puzzle ${now.month}/${now.day} at ${now.hour}:${now.minute}";
    
    // Collect current puzzle state
    Map<String, dynamic> puzzleData = {
      'originalText': originalText,
      'selectedEncoding': selectedEncoding,
      'substitutionMap': Map<String, String>.from(substitutionMap),
      'userAnswers': {},
    };
    
    // Store user's inputs
    for (var entry in solutionControllers.entries) {
      puzzleData['userAnswers'][entry.key.toString()] = entry.value.text;
    }
    
    // Add to saved puzzles list and save the data
    setState(() {
      _savedPuzzles.add(puzzleName);
      _savedPuzzleData[puzzleName] = puzzleData;
    });
    
    // Save to SharedPreferences
    _savePuzzlesToStorage();
    
    // Print debug info
    print("Saved puzzle: $puzzleName");
    print("Saved data keys: ${_savedPuzzleData.keys.toList()}");
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Puzzle saved as "$puzzleName"')),
    );
  }
  
  void _loadPuzzle(String puzzleName) {
    // Print debug info
    print("Attempting to load puzzle: $puzzleName");
    print("Available puzzles: ${_savedPuzzleData.keys.toList()}");
    
    // Check if puzzle exists
    if (!_savedPuzzleData.containsKey(puzzleName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Could not find data for $puzzleName')),
      );
      return;
    }
    
    // Get the saved puzzle data
    final puzzleData = _savedPuzzleData[puzzleName]!;
    print("Found puzzle data: ${puzzleData.keys.toList()}");
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loading puzzle...')),
    );
    
    // Completely recreate the puzzle state from scratch
    try {
      // 1. Clear all existing controllers
      for (var controller in solutionControllers.values) {
        controller.dispose();
      }
      solutionControllers.clear();
      
      // 2. Update the state properties
      setState(() {
        originalText = puzzleData['originalText'] as String;
        selectedEncoding = puzzleData['selectedEncoding'] as String?;
        
        // Restore substitution map
        substitutionMap.clear();
        final savedMap = puzzleData['substitutionMap'];
        if (savedMap is Map) {
          savedMap.forEach((key, value) {
            substitutionMap[key.toString()] = value.toString();
          });
        }
      });
      
      // 3. Force a rebuild of the cipher text with a slight delay
      Future.delayed(const Duration(milliseconds: 50), () {
        // Call the original encipherText method
        encipherText();
        
        // 4. Now restore the user's answers after the cipher is rebuilt
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            // Get saved answers and restore them
            final userAnswers = puzzleData['userAnswers'];
            if (userAnswers is Map) {
              userAnswers.forEach((posKey, value) {
                try {
                  int pos = int.parse(posKey.toString());
                  if (solutionControllers.containsKey(pos) && value != null) {
                    solutionControllers[pos]!.text = value.toString();
                  }
                } catch (e) {
                  print("Error restoring answer at position $posKey: $e");
                }
              });
            }
            
            // Force a final update
            setState(() {
              // Reset score display
              showScore = false;
              scorePercentage = 0.0;
              correctLetters = 0;
              totalLetters = 0;
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Puzzle loaded successfully')),
            );
          } catch (e) {
            print("Error in final restore phase: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error restoring answers: $e')),
            );
          }
        });
      });
    } catch (e) {
      print("Error loading puzzle: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading puzzle: $e')),
      );
    }
  }
  
  void _clearPuzzle() {
    // Clear all solution controllers
    for (var controller in solutionControllers.values) {
      controller.clear();
    }
    
    // Reset score display
    setState(() {
      showScore = false;
      scorePercentage = 0.0;
      correctLetters = 0;
      totalLetters = 0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Puzzle cleared')),
    );
  }
  
  // Handle selection of a specific puzzle by number
  void _selectSpecificPuzzle(String text, int puzzleNumber) {
    setState(() {
      // Process the text using the same method as in the base class
      String filtered = text;
      
      // Remove any characters that aren't letters, spaces or basic punctuation
      // Note: We need to use a similar filtering method as in CipherSolverStateBase
      for (int i = 0; i < filtered.length; i++) {
        String char = filtered[i];
        
        // Check if character is allowed (copied from _isAllowedCharacter in CipherSolverStateBase)
        bool isAllowed = false;
        
        // Check if it's a letter (ASCII A-Z or a-z)
        if (char.isNotEmpty) {
          int code = char.codeUnitAt(0);
          if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) {
            isAllowed = true;
          }
        }
        
        // Allow spaces
        if (char == ' ') {
          isAllowed = true;
        }
        
        // Allow basic punctuation
        const allowedPunctuation = '.,;:!?\'"-(){}[]';
        if (allowedPunctuation.contains(char)) {
          isAllowed = true;
        }
        
        // Remove character if not allowed
        if (!isAllowed) {
          filtered = filtered.replaceAll(char, '');
        }
      }
      
      // Convert to uppercase for processing
      originalText = filtered.toUpperCase();
      
      // Reset cipher with new random substitution
      createRandomSubstitution();
      encipherText();
      
      // Show confirmation with puzzle number
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded puzzle #${puzzleNumber + 1}')),
      );
    });
  }

  // Display the instructions dialog
  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text('How to Play'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInstructionItem(
                  '1. Decipher the message',
                  'Each letter has been replaced with another letter. Your goal is to figure out the original message.',
                ),
                _buildInstructionItem(
                  '2. Enable the Key for beginners',
                  'Tap the settings icon and toggle the "Show Cipher Key" to ON.',
                ),
                _buildInstructionItem(
                  '3. Fill in your guesses',
                  'Tap on a box and use the letter wheel to select your guess. Example: If you think "J" represents "A", select "A" for all "J" boxes.',
                ),
                _buildInstructionItem(
                  '4. Use patterns to help',
                  'Look for common patterns like "THE", "AND", or short words like "A" or "I".',
                ),
                _buildInstructionItem(
                  '5. Auto-substitution',
                  'When enabled, selecting a letter for one box will automatically fill all matching boxes.',
                ),
                _buildInstructionItem(
                  '6. Check your answer',
                  "Press the \"Check Answer\" button to see how many letters you solved correctly.",
                ),
                _buildInstructionItem(
                  '7. Have fun creating your own worksheets!',
                  "Tap the settings icon. Choose \"Create My Own\" and enter any text. Choose your settings and click \"Print Current Cipher\"",
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Got it!'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
  
  // Helper to build each instruction item
  Widget _buildInstructionItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crazy Crunchy Ciphers'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: 'Settings',
            );
          },
        ),
        actions: [
          // Add help button to show instructions again
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showInstructionsDialog,
            tooltip: 'How to Play',
          ),
          // Add button to open right drawer
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
                tooltip: 'Puzzle Menu',
              );
            },
          ),
        ],
      ),
      drawer: CipherDrawer(
        availableEncodings: availableEncodings,
        selectedEncoding: selectedEncoding,
        onEncodingChanged: (String? newValue) {
          setState(() {
            selectedEncoding = newValue;
            if (selectedEncoding == null) {
              createRandomSubstitution();
            }
            encipherText();
            checkKeyAvailability();
          });
        },
        onCreateCipher: showCreateDialog,
        onThemeTextSelected: selectThemeText,
        onSpecificPuzzleSelected: _selectSpecificPuzzle,
        autoSubstitutionEnabled: autoSubstitutionEnabled,
        onAutoSubstitutionToggled: toggleAutoSubstitution,
        keyAvailable: keyAvailable,
        keyVisible: keyVisible,
        onKeyVisibilityToggled: toggleKeyVisibility,
        onPrintCipher: generateAndDownloadPdf,
      ),
      // Add right drawer
      endDrawer: RightDrawer(
        savedPuzzles: _savedPuzzles,
        onSave: _savePuzzle,
        onLoadPuzzle: _loadPuzzle,
        onClear: _clearPuzzle,
      ),
      // Use Stack as the root widget to properly layer the UI elements
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                /*
                // Current text display
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Current Text: $originalText',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),*/
                
                // Feature indicators row
                _buildFeatureIndicators(),
                
                // Responsive cipher layout
                Expanded(
                  child: _buildResponsiveCipherLayout(),
                ),
                
                const SizedBox(height: 16),
                
                // Check Answer button
                ElevatedButton.icon(
                  onPressed: checkAnswer,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Check Answer'),
                ),
                
                // Score display
                if (showScore) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Score: $correctLetters/$totalLetters (${(scorePercentage * 100).toStringAsFixed(1)}%)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: scorePercentage,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        scorePercentage == 1.0 ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                  if (scorePercentage == 1.0) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Congratulations! You solved it!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          
          // Key overlay - positioned properly in the stack
          if (keyVisible)
            Positioned.fill(
              child: CipherKeyDisplay(
                selectedEncoding: selectedEncoding,
                substitutionMap: substitutionMap,
                isVisible: keyVisible,
                onClose: () => toggleKeyVisibility(false),
              ),
            ),
        ],
      ),
    );
  }
  
  // Helper method to build feature indicators
  Widget _buildFeatureIndicators() {
    final List<Widget> indicators = [];
    
    // Auto-substitution indicator - now works for all encoding types
    if (autoSubstitutionEnabled) {
      indicators.add(
        Chip(
          label: const Text('Auto-Substitution'),
          labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
          backgroundColor: Colors.blue,
          visualDensity: VisualDensity.compact,
        ),
      );
    }
    
    // Key visibility indicator
    if (keyVisible) {
      indicators.add(
        Chip(
          label: const Text('Key Visible'),
          labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
          backgroundColor: Colors.purple,
          visualDensity: VisualDensity.compact,
        ),
      );
    }
    
    // Return row of indicators or empty container if none
    if (indicators.isEmpty) {
      return const SizedBox(height: 0);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: indicators,
      ),
    );
  }
  
  // Build responsive cipher layout
  Widget _buildResponsiveCipherLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate adaptive box size based on available width
        final maxWidth = constraints.maxWidth;
        // Increase base size while maintaining overflow prevention
        final double baseSize = min(maxWidth / 18, 75.0); // Larger base size (was /24, 60.0)
        final double boxSize = max(baseSize, 30.0); // Larger minimum size (was 24.0)
        final double spacing = min(6.0, boxSize / 8); // Slightly larger spacing
        final double effectiveBoxWidth = boxSize * 0.8; // Wider effective width (was 0.7)
        
        // Add margin around the content area
        final contentWidth = maxWidth - 20.0; // Slightly larger margins for better appearance
        
        // Organize ciphered characters into words
        List<List<String>> words = [];
        List<String> currentWord = [];
        
        for (String char in cipheredCharacters) {
          if (char == ' ' || char == '\n') {
            if (currentWord.isNotEmpty) {
              words.add(List<String>.from(currentWord));
              currentWord = [];
            }
            // Add space as a separate "word"
            words.add([char]);
          } else {
            currentWord.add(char);
          }
        }
        
        // Add the last word if it exists
        if (currentWord.isNotEmpty) {
          words.add(List<String>.from(currentWord));
        }

        // Calculate line breaks with word preservation
        List<List<List<String>>> lines = [];
        List<List<String>> currentLine = [];
        double currentLineWidth = 0;

        for (List<String> word in words) {
          // Handle line breaks
          if (word.length == 1 && word[0] == '\n') {
            if (currentLine.isNotEmpty) {
              lines.add(List<List<String>>.from(currentLine));
              currentLine = [];
              currentLineWidth = 0;
            }
            continue;
          }
          
          // Calculate word width with safety margin
          double wordWidth = word.length * effectiveBoxWidth * 1.05; // Smaller safety margin
          
          // Check if adding this word would exceed the content width
          if (currentLineWidth + wordWidth > contentWidth && currentLine.isNotEmpty) {
            // Complete the current line and start a new one
            lines.add(List<List<String>>.from(currentLine));
            currentLine = [List<String>.from(word)];
            currentLineWidth = wordWidth;
          } else {
            // Add word to current line
            currentLine.add(List<String>.from(word));
            currentLineWidth += wordWidth;
          }
        }
        
        // Add the final line if not empty
        if (currentLine.isNotEmpty) {
          lines.add(List<List<String>>.from(currentLine));
        }

        // Build the layout with center alignment
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0), // Slightly larger side margins
            child: Column(
              children: lines.asMap().entries.map((lineEntry) {
                int lineIndex = lineEntry.key;
                List<List<String>> line = lineEntry.value;
                
                // Calculate absolute position for controller tracking
                int absolutePosition = 0;
                for (int i = 0; i < lineIndex; i++) {
                  for (var word in lines[i]) {
                    absolutePosition += word.length;
                  }
                }
                
                // Build the line with centered alignment
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center alignment
                    mainAxisSize: MainAxisSize.min, // Take only needed space
                    children: line.asMap().entries.map((wordEntry) {
                      int wordIndex = wordEntry.key;
                      List<String> word = wordEntry.value;
                      
                      // Create a row for this word
                      return Row(
                        mainAxisSize: MainAxisSize.min, // Take only needed space
                        children: word.asMap().entries.map((charEntry) {
                          int charIndex = charEntry.key;
                          String char = charEntry.value;
                          
                          int charPosition = absolutePosition + charIndex;
                          for (int i = 0; i < wordIndex; i++) {
                            charPosition += line[i].length;
                          }
                          
                          // Get or create controller
                          TextEditingController? controller;
                          
                          // Check if character is a letter
                          String upperChar = char.toUpperCase();
                          bool isLetter = upperChar.isNotEmpty && 
                                          upperChar.codeUnitAt(0) >= 65 && 
                                          upperChar.codeUnitAt(0) <= 90;
                          
                          if (isLetter) {
                            if (!solutionControllers.containsKey(charPosition)) {
                              solutionControllers[charPosition] = TextEditingController();
                            }
                            controller = solutionControllers[charPosition];
                          }
                          
                          return _buildAdaptiveCharacterDisplay(
                            char,
                            controller: controller,
                            size: boxSize,
                            position: charPosition
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Build an adaptive character display widget
  Widget _buildAdaptiveCharacterDisplay(
    String char, 
    {TextEditingController? controller, double size = 40.0, int position = -1}
  ) {
    // Check if character is a letter
    String upperChar = char.toUpperCase();
    bool isLetter = upperChar.isNotEmpty && 
                    upperChar.codeUnitAt(0) >= 65 && 
                    upperChar.codeUnitAt(0) <= 90;
    
    // Non-letter characters (spaces, punctuation)
    if (!isLetter) {
      // Adjust space width for better word spacing
      double charWidth = char == ' ' ? size * 0.4 : size * 0.5;
      return SizedBox(
        width: charWidth,
        child: Text(
          char,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size * 0.5),
        ),
      );
    }

    return SizedBox(
      width: size * 0.8, // Wider container (was 0.7)
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Input box ABOVE the cipher character
          InkWell(
            borderRadius: BorderRadius.circular(2),
            onTap: controller != null && position >= 0 ? () {
              showLetterWheel(
                context: context,
                controller: controller,
                char: char,
                position: position,
                onLetterSelected: handleTextChanged,
                forceRefresh: () {
                  setState(() {});
                },
              );
            } : null,
            child: Container(
              height: size * 0.4, // Larger height (was 0.35)
              width: size * 0.4,  // Larger width (was 0.35)
              decoration: BoxDecoration(
                border: Border.all(
                  color: controller?.text.isNotEmpty == true 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade400,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(2),
                color: controller?.text.isNotEmpty == true
                    ? Theme.of(context).primaryColor.withOpacity(0.15)
                    : Colors.grey.shade200.withOpacity(0.5),
              ),
              margin: const EdgeInsets.only(bottom: 2),
              alignment: Alignment.center,
              child: Text(
                controller?.text.toUpperCase() ?? '',
                style: TextStyle(
                  fontSize: size * 0.3, // Larger text (was 0.25)
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          
          // Display cipher character BELOW the input box
          if (selectedEncoding != null) 
            FutureBuilder<bool>(
              future: isImageAvailable(char),
              builder: (context, snapshot) {
                if (snapshot.data ?? false) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: size * 0.9,  // Larger constraint (was 0.7)
                      maxHeight: size * 0.9,  // Larger constraint (was 0.7)
                    ),
                    child: Image.asset(
                      'assets/$selectedEncoding/${char.toLowerCase()}/${char.toUpperCase()}.png',
                      width: size * 0.9,  // Larger image (was 0.7)
                      height: size * 0.9,  // Larger image (was 0.7)
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, _) => const SizedBox.shrink(),
                    ),
                  );
                }
                return SizedBox(
                  height: size * 0.75, // Larger size (was 0.6)
                  width: size * 0.75,  // Larger size (was 0.6)
                  child: Center(
                    child: Text(
                      char.toUpperCase(),
                      style: TextStyle(
                        fontSize: size * 0.5,  // Larger text (was 0.4)
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            )
          else
            // For standard substitution cipher, show the cipher character
            SizedBox(
              height: size * 0.75, // Larger height (was 0.6)
              width: size * 0.75,  // Larger width (was 0.6)
              child: Center(
                child: Text(
                  char.toUpperCase(),
                  style: TextStyle(
                    fontSize: size * 0.5,  // Larger text (was 0.4)
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

}