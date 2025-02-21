import 'dart:math';
import 'package:flutter/material.dart';

class CipherKeyDisplay extends StatefulWidget {
  final String? selectedEncoding;
  final Map<String, String> substitutionMap;
  final bool isVisible;
  final VoidCallback onClose;

  const CipherKeyDisplay({
    Key? key,
    required this.selectedEncoding,
    required this.substitutionMap,
    required this.isVisible,
    required this.onClose,
  }) : super(key: key);

  @override
  State<CipherKeyDisplay> createState() => _CipherKeyDisplayState();
}

class _CipherKeyDisplayState extends State<CipherKeyDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _shouldBuild = false;
  bool _isMinimized = false;
  bool _isDragging = false;
  Offset _position = const Offset(20, 100); // Initial position
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Define animations
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)
    );
    
    // Check if we should show the key
    _shouldBuild = widget.isVisible;
    if (_shouldBuild) {
      _animationController.forward();
    }
  }
  
  @override
  void didUpdateWidget(CipherKeyDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle visibility changes
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        setState(() {
          _shouldBuild = true;
          _isMinimized = false;
        });
        _animationController.forward();
      } else {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _shouldBuild = false;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _position += details.delta;
      // Add some resistance near screen edges
      if (_position.dx < 0) _position = Offset(0, _position.dy);
      if (_position.dy < 0) _position = Offset(_position.dx, 0);
    });
  }
  
  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _opacity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldBuild) {
      return const SizedBox.shrink();
    }

    // Get screen size for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isSmallScreen = screenWidth < 600;
    
    // Calculate maximum position to keep key on screen
    final maxWidth = screenWidth - (isSmallScreen ? 150 : 200);
    final maxHeight = screenHeight - keyboardHeight - (isSmallScreen ? 100 : 150);
    _position = Offset(
      _position.dx.clamp(0, maxWidth),
      _position.dy.clamp(0, maxHeight),
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Semi-transparent overlay to allow touches outside the key
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            
            // Draggable key display
            Positioned(
              left: _position.dx,
              top: _position.dy,
              child: GestureDetector(
                onPanUpdate: _onDragUpdate,
                onPanEnd: _onDragEnd,
                child: Opacity(
                  opacity: _isDragging ? 0.7 : 1.0,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isSmallScreen ? 150 : 200,
                      maxHeight: isSmallScreen ? 200 : 300,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with minimize/close buttons
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(_isMinimized ? Icons.expand_more : Icons.expand_less),
                                onPressed: () {
                                  setState(() {
                                    _isMinimized = !_isMinimized;
                                  });
                                },
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                              ),
                              const Text(
                                'Key',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: widget.onClose,
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Key content
                        if (!_isMinimized)
                          Flexible(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildKeyContent(context, isSmallScreen),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildKeyContent(BuildContext context, bool isSmallScreen) {
    if (widget.selectedEncoding == null) {
      // Build substitution cipher key grid
      final alphabet = List.generate(26, (index) => String.fromCharCode(65 + index));
      
      return Wrap(
        spacing: isSmallScreen ? 4 : 6,
        runSpacing: isSmallScreen ? 4 : 6,
        children: alphabet.map((letter) {
          final substitution = widget.substitutionMap[letter] ?? '?';
          return Container(
            width: isSmallScreen ? 32 : 40,
            height: isSmallScreen ? 24 : 30,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  letter,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: isSmallScreen ? 10 : 12,
                  color: Colors.grey[600],
                ),
                Text(
                  substitution,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      // Image-based key - Show image at top if available
      return FutureBuilder<bool>(
        future: _isImageAvailable(widget.selectedEncoding!),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.asset(
              'assets/key/${widget.selectedEncoding}_key.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => 
                _buildErrorWidget('Could not load key image'),
            );
          } else {
            return _buildErrorWidget('No key available');
          }
        },
      );
    }
  }
  
  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[200]),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
  
  Future<bool> _isImageAvailable(String encoding) async {
    try {
      await DefaultAssetBundle.of(context).load('assets/key/${encoding}_key.png');
      return true;
    } catch (_) {
      return false;
    }
  }
}
