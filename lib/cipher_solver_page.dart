import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/cipher_drawer.dart';
import 'widgets/cipher_key_display.dart';
import 'utils/cipher_key_manager.dart';
import 'utils/pdf_generator.dart';

class CipherSolverPage extends StatefulWidget {
  const CipherSolverPage({super.key});

  @override
  State<CipherSolverPage> createState() => _CipherSolverPageState();
}

class _CipherSolverPageState extends State<CipherSolverPage> {
  // Cipher-related state variables
  final Map<String, String> substitutionMap = {};
  final Map<int, TextEditingController> solutionControllers = {};
  
  List<String> cipheredCharacters = [];
  List<String> availableEncodings = [];
  
  String originalText = "CRANKIN' CRUNCHY CIPHERS CRISS-CROSSES YOUR CRANIUM!";
  String? selectedEncoding;
  
  // Scoring variables
  double scorePercentage = 0.0;
  int correctLetters = 0;
  int totalLetters = 0;
  bool showScore = false;
  
  // Auto-substitution feature
  bool autoSubstitutionEnabled = false;
  
  // Key display feature
  bool _keyAvailable = false;
  bool _keyVisible = false;
  final _keyManager = CipherKeyManager();

  @override
  void initState() {
    super.initState();
    _loadAvailableEncodings();
    _createRandomSubstitution();
    _encipherText();
    _checkKeyAvailability();
  }

  @override
  void dispose() {
    // Dispose of all text controllers to prevent memory leaks
    for (var controller in solutionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Load available encoding types from asset manifest
  Future<void> _loadAvailableEncodings() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final encodings = <String>{};
      for (String key in manifestMap.keys) {
        if (key.startsWith('assets/') && key.endsWith('.png')) {
          final parts = key.split('/');
          if (parts.length == 4) {
            encodings.add(parts[1]);
          }
        }
      }
      
      setState(() {
        availableEncodings = encodings.toList()..sort();
      });
    } catch (e) {
      debugPrint('Error loading encodings: $e');
    }
  }

  // Create a random substitution cipher
  void _createRandomSubstitution() {
    substitutionMap.clear();
    final alphabet = List.generate(26, (index) => String.fromCharCode(65 + index));
    final shuffled = List.from(alphabet)..shuffle();
    
    for (int i = 0; i < alphabet.length; i++) {
      String original = alphabet[i];
      String substitution = shuffled[i];
      
      // Ensure no letter represents itself
      if (original == substitution) {
        int nextIndex = (i + 1) % alphabet.length;
        shuffled[i] = shuffled[nextIndex];
        shuffled[nextIndex] = substitution;
        substitution = shuffled[i];
      }
      
      substitutionMap[original] = substitution;
    }
  }

  // Toggle auto-substitution feature
  void _toggleAutoSubstitution(bool value) {
    setState(() {
      autoSubstitutionEnabled = value;
    });
  }
  
  // Check key availability
  Future<void> _checkKeyAvailability() async {
    final isAvailable = await _keyManager.isKeyAvailable(selectedEncoding);
    setState(() {
      _keyAvailable = isAvailable;
      // If key is not available, make sure it's not visible
      if (!isAvailable) {
        _keyVisible = false;
      }
    });
  }
  
  // Toggle key visibility
  void _toggleKeyVisibility(bool value) {
    setState(() {
      _keyVisible = value;
    });
  }
  
  // Generate and download PDF
  Future<void> _generateAndDownloadPdf() async {
    try {
      await CipherPdfGenerator.downloadCipherPdf(
        originalText: originalText,
        cipheredCharacters: cipheredCharacters,
        selectedEncoding: selectedEncoding,
        substitutionMap: substitutionMap,
        showKey: _keyVisible,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Maps position in cipheredCharacters to position in original text
  Map<int, int> _buildPositionMapping() {
    Map<int, int> positionMap = {};
    int cipherPos = 0;
    int originalPos = 0;
    
    // Build mapping between ciphered positions and original text positions
    for (int i = 0; i < cipheredCharacters.length; i++) {
      if (RegExp(r'[A-Z]').hasMatch(cipheredCharacters[i])) {
        // Find corresponding position in original text
        while (originalPos < originalText.length) {
          if (RegExp(r'[A-Z]').hasMatch(originalText[originalPos].toUpperCase())) {
            positionMap[i] = originalPos;
            originalPos++;
            break;
          }
          originalPos++;
        }
      }
    }
    
    return positionMap;
  }

  // Handle text changed in input fields with auto-substitution
  void _handleTextChanged(String value, String cipherChar, TextEditingController controller, int position) {
    if (value.isEmpty) return;
    
    // Convert to uppercase
    String upperValue = value.toUpperCase();
    controller.text = upperValue;
    
    // Only apply auto-substitution when enabled
    if (autoSubstitutionEnabled) {
      if (selectedEncoding == null) {
        // For substitution cipher: match by cipher character
        for (int i = 0; i < cipheredCharacters.length; i++) {
          if (i == position) continue;
          if (cipheredCharacters[i] == cipherChar && solutionControllers.containsKey(i)) {
            solutionControllers[i]!.text = upperValue;
          }
        }
      } else {
        // For image encodings: match by original character
        // Get mapping from ciphered positions to original text positions
        final positionMap = _buildPositionMapping();
        
        // Find this position in original text
        if (positionMap.containsKey(position)) {
          int originalPos = positionMap[position]!;
          String originalChar = originalText[originalPos].toUpperCase();
          
          // Update all controllers that represent the same original character
          for (final entry in positionMap.entries) {
            int cipherPos = entry.key;
            int origPos = entry.value;
            
            // Skip this position and non-matching characters
            if (cipherPos == position) continue;
            if (originalText[origPos].toUpperCase() != originalChar) continue;
            
            // Update controller if it exists
            if (solutionControllers.containsKey(cipherPos)) {
              solutionControllers[cipherPos]!.text = upperValue;
            }
          }
        }
      }
    }
    
    // Reset score when user changes answers
    if (showScore) {
      setState(() {
        showScore = false;
        scorePercentage = 0.0;
        correctLetters = 0;
        totalLetters = 0;
      });
    }
  }

  // Encipher the text based on current encoding
  void _encipherText() {
    // Clear existing controllers
    for (var controller in solutionControllers.values) {
      controller.dispose();
    }
    solutionControllers.clear();
    cipheredCharacters.clear();

    // Encipher based on encoding type
    if (selectedEncoding == null) {
      for (String char in originalText.toUpperCase().split('')) {
        if (RegExp(r'[A-Z]').hasMatch(char)) {
          cipheredCharacters.add(substitutionMap[char]!);
        } else {
          cipheredCharacters.add(char);
        }
      }
    } else {
      cipheredCharacters.addAll(originalText.toUpperCase().split(''));
    }

    // Reset scoring
    setState(() {
      showScore = false;
      scorePercentage = 0.0;
      correctLetters = 0;
      totalLetters = 0;
    });
  }

  // Check if an image is available for a specific letter
  Future<bool> _isImageAvailable(String letter) async {
    if (selectedEncoding == null) return false;
    final path = 'assets/$selectedEncoding/${letter.toLowerCase()}/${letter.toUpperCase()}.png';
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Check the user's answer
  void _checkAnswer() {
    var correctAnswers = <int, bool>{};
    int correct = 0;
    int total = 0;

    // Create a filtered list of letters from the original text
    final originalLetters = originalText.toUpperCase().split('')
      .where((char) => RegExp(r'[A-Z]').hasMatch(char))
      .toList();

    for (int i = 0; i < cipheredCharacters.length; i++) {
      if (RegExp(r'[A-Z]').hasMatch(cipheredCharacters[i])) {
        total++;
        final userInput = solutionControllers[i]?.text.toUpperCase() ?? '';
        final correctChar = originalLetters[total - 1];
        
        correctAnswers[i] = userInput == correctChar;
        if (correctAnswers[i]!) correct++;
      }
    }

    setState(() {
      correctLetters = correct;
      totalLetters = total;
      scorePercentage = total > 0 ? (correct / total) : 0.0;
      showScore = true;
    });
  }

  // Create a dialog to input custom cipher text
  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newText = '';
        return AlertDialog(
          title: const Text('Create New Crazy Cipher'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Enter text to encrypt',
            ),
            onChanged: (value) => newText = value,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                setState(() {
                  originalText = newText;
                  _createRandomSubstitution();
                  _encipherText();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Select a theme text
  void _selectThemeText(String text) {
    setState(() {
      // Remove non-alphabetic characters and convert to uppercase
      originalText = text.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').toUpperCase();
      
      // Reset cipher
      _createRandomSubstitution();
      _encipherText();
    });
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
              words.add(currentWord);
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
          words.add(currentWord);
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
            if (wordWidth > maxWidth && word.length > 3 && word[0] != ' ') {
              // Find a good hyphenation point (around half)
              int splitPoint = max(2, word.length ~/ 2);
              
              // Add first part with hyphen to current line
              List<String> firstPart = word.sublist(0, splitPoint);
              firstPart.add('-');
              currentLine.add(firstPart);
              lines.add(currentLine);
              
              // Start a new line with the second part
              List<String> secondPart = word.sublist(splitPoint);
              currentLine = [secondPart];
              currentLineWidth = secondPart.length * effectiveBoxWidth;
            } else {
              // Complete the current line and start a new one
              lines.add(currentLine);
              currentLine = [word];
              currentLineWidth = wordWidth;
            }
          } else {
            // Add word to current line
            currentLine.add(word);
            currentLineWidth += wordWidth;
          }
        }
        
        // Add the final line if not empty
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
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
                    if (RegExp(r'[A-Z]').hasMatch(char)) {
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
    // Non-letter characters (spaces, punctuation)
    if (!RegExp(r'[A-Z]').hasMatch(char)) {
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
              future: _isImageAvailable(char),
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
                return const SizedBox.shrink();
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
                labelText: selectedEncoding == null ? char : null,
                labelStyle: TextStyle(fontSize: size * 0.3),
                counterText: '',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.all(size * 0.2),
              ),
              onChanged: controller != null && position >= 0
                ? (value) => _handleTextChanged(value, char, controller, position)
                : null,
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
    /*if (_keyVisible) {
      indicators.add(
        Chip(
          label: const Text('Key Visible'),
          labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
          backgroundColor: Colors.purple,
          visualDensity: VisualDensity.compact,
        ),
      );
    }*/
    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crazy Crunchy Ciphers'),
      ),
      drawer: CipherDrawer(
        availableEncodings: availableEncodings,
        selectedEncoding: selectedEncoding,
        onEncodingChanged: (String? newValue) {
          setState(() {
            selectedEncoding = newValue;
            if (selectedEncoding == null) {
              _createRandomSubstitution();
            }
            _encipherText();
            _checkKeyAvailability();
          });
        },
        onCreateCipher: _showCreateDialog,
        onThemeTextSelected: _selectThemeText,
        autoSubstitutionEnabled: autoSubstitutionEnabled,
        onAutoSubstitutionToggled: _toggleAutoSubstitution,
        keyAvailable: _keyAvailable,
        keyVisible: _keyVisible,
        onKeyVisibilityToggled: _toggleKeyVisibility,
        onPrintCipher: _generateAndDownloadPdf,
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
                /*Padding(
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
                  onPressed: _checkAnswer,
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
          if (_keyVisible)
            Positioned.fill(
              child: CipherKeyDisplay(
                selectedEncoding: selectedEncoding,
                substitutionMap: substitutionMap,
                isVisible: _keyVisible,
                onClose: () => _toggleKeyVisibility(false),
              ),
            ),
        ],
      ),
    );
  }
}