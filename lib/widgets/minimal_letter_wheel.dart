// Minimal Letter Wheel with forced UI refresh
// Add this to a new file or directly in cipher_solver_page.dart

import 'package:flutter/material.dart';

class SimpleLetterWheel extends StatefulWidget {
  final Function(String) onLetterSelected;
  final String? initialValue;
  final Function() forceRefresh; // Add callback to force UI refresh

  const SimpleLetterWheel({
    Key? key,
    required this.onLetterSelected,
    required this.forceRefresh,
    this.initialValue,
  }) : super(key: key);

  @override
  State<SimpleLetterWheel> createState() => _SimpleLetterWheelState();
}

class _SimpleLetterWheelState extends State<SimpleLetterWheel> {
  late FixedExtentScrollController _controller;
  final List<String> alphabet = List.generate(
    26, (index) => String.fromCharCode(65 + index)
  );

  @override
  void initState() {
    super.initState();
    // Set initial position based on provided value or default to 'A'
    String initialLetter = widget.initialValue?.toUpperCase() ?? '';
    int initialIndex = 0; // Default to 'A'
    
    if (initialLetter.isNotEmpty) {
      int foundIndex = alphabet.indexOf(initialLetter);
      if (foundIndex >= 0) {
        initialIndex = foundIndex;
      }
    }
    
    _controller = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Column(
        children: [
          // Header with Done button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    // Get currently selected letter
                    int selectedIndex = _controller.selectedItem;
                    String letter = alphabet[selectedIndex];
                    
                    // Return the selected letter
                    widget.onLetterSelected(letter);
                    
                    // Close the modal
                    Navigator.of(context).pop();
                    
                    // Force UI refresh
                    widget.forceRefresh();
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Letter wheel
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: ListWheelScrollView(
                controller: _controller,
                itemExtent: 40,
                useMagnifier: true,
                magnification: 1.5,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                children: alphabet.map((letter) {
                  return Container(
                    alignment: Alignment.center,
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to show the letter wheel
void showLetterWheel({
  required BuildContext context,
  required TextEditingController controller,
  required String char,
  required int position,
  required Function(String, String, TextEditingController, int) onLetterSelected,
  required Function() forceRefresh,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => SimpleLetterWheel(
      initialValue: controller.text,
      onLetterSelected: (letter) {
        // Update the controller with the selected letter
        controller.text = letter;
        
        // Call handleTextChanged for any additional logic
        onLetterSelected(letter, char, controller, position);
      },
      forceRefresh: forceRefresh,
    ),
  );
}