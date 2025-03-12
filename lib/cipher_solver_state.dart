import 'dart:convert';
import 'dart:math'; // Import for Random class
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/cipher_key_manager.dart';
import 'utils/pdf_generator.dart';

mixin CipherSolverStateBase<T extends StatefulWidget> on State<T> {
  // Cipher-related state variables
  final Map<String, String> substitutionMap = {};
  final Map<int, TextEditingController> solutionControllers = {};
  
  List<String> cipheredCharacters = [];
  List<String> availableEncodings = [];
  
  // Default text - now empty, will be set by theme selection
  String originalText = "";
  String? selectedEncoding;
  
  // Scoring variables
  double scorePercentage = 0.0;
  int correctLetters = 0;
  int totalLetters = 0;
  bool showScore = false;
  
  // Auto-substitution feature - enabled by default
  bool autoSubstitutionEnabled = true;
  
  // Key display feature
  bool keyAvailable = false;
  bool keyVisible = false;
  final _keyManager = CipherKeyManager();

  @override
  void initState() {
    super.initState();
    loadAvailableEncodings();
    
    // Note: We don't create a default substitution or encipher text here anymore
    // That will be handled by CipherSolverPage after loading the theme
    checkKeyAvailability();
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
  Future<void> loadAvailableEncodings() async {
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

  // Create a deterministic substitution cipher based on text content
  void createRandomSubstitution() {
    substitutionMap.clear();
    final alphabet = List.generate(26, (index) => String.fromCharCode(65 + index));
    
    // Create a deterministic seed based on the text
    int seed = _generateSeedFromText(originalText);
    final random = Random(seed);
    
    // Create a shuffled list using the seeded random generator
    final shuffled = List<String>.from(alphabet);
    for (int i = shuffled.length - 1; i > 0; i--) {
      // Fisher-Yates shuffle with seeded random
      int j = random.nextInt(i + 1);
      String temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    
    // Create the substitution map, ensuring no letter maps to itself
    for (int i = 0; i < alphabet.length; i++) {
      String original = alphabet[i];
      String substitution = shuffled[i];
      
      // Ensure no letter represents itself
      if (original == substitution) {
        // Find the next letter that isn't itself
        for (int j = 0; j < alphabet.length; j++) {
          int idx = (i + j + 1) % alphabet.length;
          if (alphabet[idx] != shuffled[idx]) {
            // Swap with this letter
            String temp = shuffled[i];
            shuffled[i] = shuffled[idx];
            shuffled[idx] = temp;
            substitution = shuffled[i];
            break;
          }
        }
      }
      
      substitutionMap[original] = substitution;
    }
  }
  
  // Generate a deterministic seed from text content
  int _generateSeedFromText(String text) {
    // If text is empty, use a default seed
    if (text.isEmpty) return 42;
    
    // Simple hash function - djb2 algorithm
    int hash = 5381;
    
    // Only use letters to calculate the hash (ignore case, spaces, and punctuation)
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      // Check if it's a letter
      if (char.isNotEmpty) {
        int code = char.toUpperCase().codeUnitAt(0);
        if (code >= 65 && code <= 90) { // ASCII for A-Z
          // djb2 hash algorithm: hash * 33 + character code
          hash = ((hash << 5) + hash) + code;
        }
      }
    }
    
    return hash.abs(); // Use absolute value to avoid negative seeds
  }

  // Toggle auto-substitution feature
  void toggleAutoSubstitution(bool value) {
    setState(() {
      autoSubstitutionEnabled = value;
    });
  }
  
  // Check key availability
  Future<void> checkKeyAvailability() async {
    final isAvailable = await _keyManager.isKeyAvailable(selectedEncoding);
    setState(() {
      keyAvailable = isAvailable;
      // If key is not available, make sure it's not visible
      if (!isAvailable) {
        keyVisible = false;
      }
    });
  }
  
  // Toggle key visibility
  void toggleKeyVisibility(bool value) {
    setState(() {
      // Only set key to visible if it's available
      if (value && !keyAvailable) {
        // Don't allow showing an unavailable key
        return;
      }
      keyVisible = value;
    });
  }
  
  // Generate and download PDF
  Future<void> generateAndDownloadPdf() async {
    try {
      await CipherPdfGenerator.downloadCipherPdf(
        originalText: originalText,
        cipheredCharacters: cipheredCharacters,
        selectedEncoding: selectedEncoding,
        substitutionMap: substitutionMap,
        showKey: keyVisible,
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
  Map<int, int> buildPositionMapping() {
    Map<int, int> positionMap = {};
    int originalPos = 0;
    
    // Build mapping between ciphered positions and original text positions
    for (int i = 0; i < cipheredCharacters.length; i++) {
      // Check if character is a letter using ASCII code
      String upperChar = cipheredCharacters[i].toUpperCase();
      bool isLetter = upperChar.isNotEmpty && upperChar.codeUnitAt(0) >= 65 && upperChar.codeUnitAt(0) <= 90;
      
      if (isLetter) {
        // Find corresponding position in original text
        while (originalPos < originalText.length) {
          // Check if originalText character is a letter
          String origUpperChar = originalText[originalPos].toUpperCase();
          bool origIsLetter = origUpperChar.isNotEmpty && 
                              origUpperChar.codeUnitAt(0) >= 65 && 
                              origUpperChar.codeUnitAt(0) <= 90;
          
          if (origIsLetter) {
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

  // Handle text changed in input fields with improved auto-substitution
  void handleTextChanged(String value, String cipherChar, TextEditingController controller, int position) {
    if (value.isEmpty) return;
    
    // Store the current input value to prevent recursion
    String inputValue = value.toUpperCase();
    
    // Set the controller text directly only if it's different
    if (controller.text != inputValue) {
      controller.text = inputValue;
      
      // Make sure controller selection is at the end to avoid cursor jumping
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: inputValue.length),
      );
    }
    
    // Only apply auto-substitution when enabled
    if (autoSubstitutionEnabled) {
      // Create a list to store all controllers that need to be updated
      final List<MapEntry<int, String>> updatesToApply = [];
      
      if (selectedEncoding == null) {
        // For substitution cipher: match by cipher character
        for (int i = 0; i < cipheredCharacters.length; i++) {
          if (i == position) continue; // Skip the current position
          if (cipheredCharacters[i] == cipherChar) {
            updatesToApply.add(MapEntry(i, inputValue));
          }
        }
      } else {
        // For image encodings: match by original character
        // Get mapping from ciphered positions to original text positions
        final positionMap = buildPositionMapping();
        
        // Find this position in original text
        if (positionMap.containsKey(position)) {
          int originalPos = positionMap[position]!;
          String originalChar = originalText[originalPos].toUpperCase();
          
          // Add all positions of the same original character to the update list
          for (final entry in positionMap.entries) {
            int cipherPos = entry.key;
            int origPos = entry.value;
            
            // Skip this position and non-matching characters
            if (cipherPos == position) continue;
            if (originalText[origPos].toUpperCase() != originalChar) continue;
            
            updatesToApply.add(MapEntry(cipherPos, inputValue));
          }
        }
      }
      
      // Apply all updates in a single pass after collecting them
      if (updatesToApply.isNotEmpty) {
        // Use a microtask to ensure UI updates first
        Future.microtask(() {
          for (var update in updatesToApply) {
            if (solutionControllers.containsKey(update.key)) {
              final targetController = solutionControllers[update.key]!;
              // Only update if different to avoid loops
              if (targetController.text != update.value) {
                targetController.text = update.value;
                // Ensure proper selection
                targetController.selection = TextSelection.fromPosition(
                  TextPosition(offset: update.value.length),
                );
              }
            }
          }
        });
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
  void encipherText() {
    // Clear existing controllers
    for (var controller in solutionControllers.values) {
      controller.dispose();
    }
    solutionControllers.clear();
    cipheredCharacters.clear();

    // Encipher based on encoding type
    if (selectedEncoding == null) {
      for (String char in originalText.split('')) {
        // Check if it's a letter
        bool isLetter = false;
        if (char.isNotEmpty) {
          int code = char.toUpperCase().codeUnitAt(0);
          isLetter = (code >= 65 && code <= 90); // ASCII for A-Z
        }
        
        if (isLetter) {
          // Only apply substitution to letters
          String upperChar = char.toUpperCase();
          cipheredCharacters.add(substitutionMap[upperChar] ?? upperChar);
        } else {
          // Keep punctuation and spaces as-is
          cipheredCharacters.add(char);
        }
      }
    } else {
      cipheredCharacters.addAll(originalText.split(''));
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
  Future<bool> isImageAvailable(String letter) async {
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
  void checkAnswer() {
    var correctAnswers = <int, bool>{};
    int correct = 0;
    int total = 0;

    // Create a filtered list of letters from the original text
    final originalLetters = <String>[];
    for (int i = 0; i < originalText.length; i++) {
      String char = originalText[i];
      // Check if it's a letter
      if (char.isNotEmpty) {
        int code = char.toUpperCase().codeUnitAt(0);
        if (code >= 65 && code <= 90) { // ASCII for A-Z
          originalLetters.add(char.toUpperCase());
        }
      }
    }

    for (int i = 0; i < cipheredCharacters.length; i++) {
      // Check if it's a letter
      String char = cipheredCharacters[i];
      bool isLetter = false;
      if (char.isNotEmpty) {
        int code = char.toUpperCase().codeUnitAt(0);
        isLetter = (code >= 65 && code <= 90);
      }
      
      if (isLetter) {
        // Only check letters, skip punctuation
        if (total < originalLetters.length) {
          total++;
          final userInput = solutionControllers[i]?.text.toUpperCase() ?? '';
          final correctChar = originalLetters[total - 1];
          
          correctAnswers[i] = userInput == correctChar;
          if (correctAnswers[i]!) correct++;
        }
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
  void showCreateDialog() {
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
                  originalText = newText.toUpperCase();
                  // Create a new random substitution for custom text
                  createRandomSubstitution();
                  encipherText();
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
  void selectThemeText(String text) {
    setState(() {
      // Keep only letters, spaces, and common punctuation
      // Create a pattern manually with simple replacement approach
      String filtered = text;
      
      // Remove any characters that aren't letters, spaces or basic punctuation
      for (int i = 0; i < filtered.length; i++) {
        String char = filtered[i];
        if (!_isAllowedCharacter(char)) {
          filtered = filtered.replaceAll(char, '');
        }
      }
      
      // Convert to uppercase for processing
      originalText = filtered.toUpperCase();
      
      // Reset cipher with new random substitution
      createRandomSubstitution();
      encipherText();
    });
  }
  
  // Helper to check if character is allowed
  bool _isAllowedCharacter(String char) {
    // Check if it's a letter (ASCII A-Z or a-z)
    if (char.isNotEmpty) {
      int code = char.codeUnitAt(0);
      if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) {
        return true;
      }
    }
    
    // Allow spaces
    if (char == ' ') {
      return true;
    }
    
    // Allow basic punctuation
    const allowedPunctuation = '.,;:!?\'"-(){}[]';
    return allowedPunctuation.contains(char);
  }
}
