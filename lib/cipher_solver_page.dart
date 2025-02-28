import 'dart:math';
import 'package:flutter/material.dart';
import 'widgets/cipher_drawer.dart';
import 'widgets/cipher_key_display.dart';
import 'widgets/right_drawer.dart';
import 'utils/pdf_generator.dart';
import 'cipher_solver_state.dart';

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
                  '2. Fill in your guesses',
                  'Example: If you think "J" represents "A", type "A" in all the boxes under "J".',
                ),
                _buildInstructionItem(
                  '3. Use patterns to help',
                  'Look for common patterns like "THE", "AND", or short words like "A" or "I".',
                ),
                _buildInstructionItem(
                  '4. Auto-substitution',
                  'When enabled, filling in one letter will automatically fill all matching letters.',
                ),
                _buildInstructionItem(
                  '5. Check your answer',
                  "Press the \"Check Answer\" button to see how many letters you solved correctly.",
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
                ),
                
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
        final double boxSize = min(40.0, maxWidth / 12); // Responsive size calculation
        final double spacing = min(8.0, boxSize / 5);
        final double effectiveBoxWidth = boxSize + spacing;

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
          double wordWidth = word.length * effectiveBoxWidth;
          
          // Check if adding this word would exceed the line width
          if (currentLineWidth + wordWidth > maxWidth && currentLine.isNotEmpty) {
            // Check if the word is too long for a single line and needs hyphenation
            if (wordWidth > maxWidth && word.length > 3 && word[0] != ' ' && word[0] != '\n') {
              // Find a good hyphenation point (around half)
              int splitPoint = max(2, word.length ~/ 2);
              
              // Add first part with hyphen to current line
              List<String> firstPart = word.sublist(0, splitPoint);
              firstPart.add('-');
              currentLine.add(List<String>.from(firstPart));
              lines.add(List<List<String>>.from(currentLine));
              
              // Start a new line with the second part
              List<String> secondPart = word.sublist(splitPoint);
              currentLine = [List<String>.from(secondPart)];
              currentLineWidth = secondPart.length * effectiveBoxWidth;
            } else {
              // Complete the current line and start a new one
              lines.add(List<List<String>>.from(currentLine));
              currentLine = [List<String>.from(word)];
              currentLineWidth = wordWidth;
            }
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

        // Now flatten words into character lists for each line to build the UI
        List<List<String>> characterLines = lines.map((line) {
          return line.expand((word) => word).toList();
        }).toList();

        // Build scrollable column of lines
        return SingleChildScrollView(
          child: Column(
            children: characterLines.asMap().entries.map((lineEntry) {
              int lineIndex = lineEntry.key;
              List<String> line = lineEntry.value;
              
              // For each line, create a row of character displays
              return Padding(
                padding: EdgeInsets.symmetric(vertical: spacing),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: spacing,
                  children: line.asMap().entries.map((charEntry) {
                    int charPositionInLine = charEntry.key;
                    String char = charEntry.value;
                    
                    // Calculate absolute position in the original ciphered text
                    int absolutePosition = 0;
                    for (int i = 0; i < lineIndex; i++) {
                      absolutePosition += characterLines[i].length;
                    }
                    absolutePosition += charPositionInLine;
                    
                    // Get or create controller with absolute position as key
                    TextEditingController? controller;
                    
                    // Check if character is a letter
                    String upperChar = char.toUpperCase();
                    bool isLetter = upperChar.isNotEmpty && 
                                    upperChar.codeUnitAt(0) >= 65 && 
                                    upperChar.codeUnitAt(0) <= 90;
                    
                    if (isLetter) {
                      if (!solutionControllers.containsKey(absolutePosition)) {
                        solutionControllers[absolutePosition] = TextEditingController();
                      }
                      controller = solutionControllers[absolutePosition];
                    }
                    
                    return _buildAdaptiveCharacterDisplay(
                      char, 
                      controller: controller,
                      size: boxSize,
                      position: absolutePosition
                    );
                  }).toList(),
                ),
              );
            }).toList(),
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
      return SizedBox(
        width: size,
        child: Text(
          char,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size * 0.4),
        ),
      );
    }

    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display image for selected encoding
          if (selectedEncoding != null) 
            FutureBuilder<bool>(
              future: isImageAvailable(char),
              builder: (context, snapshot) {
                if (snapshot.data ?? false) {
                  return Image.asset(
                    'assets/$selectedEncoding/${char.toLowerCase()}/${char.toUpperCase()}.png',
                    width: size,
                    height: size,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, _) => const SizedBox.shrink(),
                  );
                }
                return SizedBox(
                  height: size,
                  child: Center(
                    child: Text(
                      char.toUpperCase(),
                      style: TextStyle(
                        fontSize: size * 0.6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          
          // Input text field
          SizedBox(
            height: size * 1.5,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              maxLength: 1,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(fontSize: size * 0.4),
              decoration: InputDecoration(
                // Show label only for random letter substitution
                labelText: selectedEncoding == null ? char.toUpperCase() : null,
                labelStyle: TextStyle(fontSize: size * 0.3),
                counterText: '',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.all(size * 0.2),
              ),
              onChanged: controller != null && position >= 0
                ? (value) => handleTextChanged(value, char, controller, position)
                : null,
            ),
          ),
        ],
      ),
    );
  }
}