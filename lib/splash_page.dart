import 'dart:math';
import 'package:flutter/material.dart';
import 'cipher_solver_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  
  // For the splash cipher
  final String _splashText = "CRANKIN' CRUNCHY CIPHERS CRISS-CROSSES YOUR CRANIUM!";
  List<String> _cipheredCharacters = [];
  
  // Fixed substitution map for consistency
  final Map<String, String> _substitutionMap = {
    'A': 'J',
    'B': 'V',
    'C': 'I',
    'D': 'L',
    'E': 'W',
    'F': 'Z',
    'G': 'S',
    'H': 'X',
    'I': 'G',
    'J': 'Y',
    'K': 'Q',
    'L': 'B',
    'M': 'D',
    'N': 'F',
    'O': 'K',
    'P': 'E',
    'Q': 'R',
    'R': 'U',
    'S': 'M',
    'T': 'O',
    'U': 'N',
    'V': 'H',
    'W': 'A',
    'X': 'P',
    'Y': 'C',
    'Z': 'T',
  };
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    
    // Encipher the splash text with our fixed substitution
    _encipherSplashText();
    
    // Start the animation
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _encipherSplashText() {
    _cipheredCharacters = [];
    
    for (String char in _splashText.split('')) {
      if (RegExp(r'[A-Z]').hasMatch(char)) {
        _cipheredCharacters.add(_substitutionMap[char]!);
      } else {
        _cipheredCharacters.add(char);
      }
    }
  }
  
  void _navigateToCipherPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const CipherSolverPage(showInstructions: true),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Icon(
                    Icons.lock_outlined,
                    size: isSmallScreen ? 80 : 120,
                    color: Colors.indigo.shade700,
                  ),
                  const SizedBox(height: 32),
                  
                  // App Title
                  Text(
                    'Crazy Crunchy Ciphers',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Ciphered Text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 12,
                      children: _cipheredCharacters.map((char) {
                        return Text(
                          char,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: isSmallScreen ? 18 : 24,
                            fontWeight: FontWeight.bold,
                            color: RegExp(r'[A-Z]').hasMatch(char) 
                              ? Colors.indigo.shade700 
                              : Colors.indigo.shade500,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 64),
                  
                  // Changed button text from "Get a Cipher" to "Play"
                  ElevatedButton.icon(
                    onPressed: _navigateToCipherPage,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32, 
                        vertical: 16,
                      ),
                      textStyle: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  // Footer text
                  const Spacer(),
                  Text(
                    'Can you decipher the message?',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.indigo.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to check if the message is properly encrypted
  // Only for debugging - can be removed in production
  void _verifyEncryption() {
    final String originalText = _splashText;
    final String encryptedText = _cipheredCharacters.join('');
    
    print('Original: $originalText');
    print('Encrypted: $encryptedText');
    
    // Check for consistent substitution
    final Map<String, String> reverseMap = {};
    bool isConsistent = true;
    
    for (int i = 0; i < originalText.length; i++) {
      final originalChar = originalText[i];
      final encryptedChar = encryptedText[i];
      
      if (RegExp(r'[A-Z]').hasMatch(originalChar)) {
        if (reverseMap.containsKey(originalChar)) {
          if (reverseMap[originalChar] != encryptedChar) {
            isConsistent = false;
            print('Inconsistency found: $originalChar maps to both ${reverseMap[originalChar]} and $encryptedChar');
          }
        } else {
          reverseMap[originalChar] = encryptedChar;
        }
      } else if (originalChar != encryptedChar) {
        isConsistent = false;
        print('Punctuation mismatch: $originalChar became $encryptedChar');
      }
    }
    
    print('Encryption is ${isConsistent ? 'consistent' : 'inconsistent'}');
  }
}