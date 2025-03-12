import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
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
    // Show theme selection dialog
    _showThemeSelectionDialog();
  }
  
  // Load theme names from the assets directory
  Future<List<String>> _loadThemeNames() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    
    final List<String> themeNames = [];
    
    // Filter for .txt files in the themes directory
    for (String key in manifestMap.keys) {
      if (key.startsWith('assets/themes/') && key.endsWith('.txt')) {
        // Extract the filename without extension
        final filename = key.split('/').last.replaceAll('.txt', '');
        themeNames.add(filename);
      }
    }
    
    // Sort the theme names alphabetically
    themeNames.sort();
    return themeNames;
  }
  
  void _showThemeSelectionDialog() async {
    // Load available themes
    final List<String> themeNames = await _loadThemeNames();
    
    if (themeNames.isEmpty) {
      // If no themes are found, show an error and use a default
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No theme files found. Using default theme.')),
      );
      
      _navigateWithTheme('Default');
      return;
    }
    
    // Show the dialog with available themes
    showDialog(
      context: context,
      barrierDismissible: false, // User must pick a theme
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.category, color: Colors.indigo.shade600),
              const SizedBox(width: 10),
              const Text('Choose a Theme'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: themeNames.length,
              itemBuilder: (context, index) {
                final theme = themeNames[index];
                // Select an appropriate icon based on theme name
                IconData themeIcon = _getThemeIcon(theme);
                
                return ListTile(
                  leading: Icon(themeIcon, color: Colors.indigo),
                  title: Text(theme),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateWithTheme(theme);
                  },
                );
              },
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }
  
  // Helper method to get an appropriate icon for each theme
  IconData _getThemeIcon(String theme) {
    final lowercaseTheme = theme.toLowerCase();
    
    if (lowercaseTheme.contains('animal')) return Icons.pets;
    if (lowercaseTheme.contains('space') || 
        lowercaseTheme.contains('planet') || 
        lowercaseTheme.contains('star')) return Icons.rocket;
    if (lowercaseTheme.contains('sport') || 
        lowercaseTheme.contains('game')) return Icons.sports_soccer;
    if (lowercaseTheme.contains('food') || 
        lowercaseTheme.contains('fruit') || 
        lowercaseTheme.contains('meal')) return Icons.restaurant;
    if (lowercaseTheme.contains('history') || 
        lowercaseTheme.contains('ancient')) return Icons.history_edu;
    if (lowercaseTheme.contains('science') || 
        lowercaseTheme.contains('tech')) return Icons.science;
    if (lowercaseTheme.contains('music') || 
        lowercaseTheme.contains('song')) return Icons.music_note;
    
    // Default icon
    return Icons.category;
  }
  
  void _navigateWithTheme(String theme) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CipherSolverPage(
          showInstructions: true,
          selectedTheme: theme,
        ),
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
                  
                  // Button to play
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
}
