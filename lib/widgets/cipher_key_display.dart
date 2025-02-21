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
  
  // Track if the widget should be built at all
  bool _shouldBuild = false;

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
        // Show the key
        setState(() {
          _shouldBuild = true;
        });
        _animationController.forward();
      } else {
        // Hide the key
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
  
  @override
  Widget build(BuildContext context) {
    if (!_shouldBuild) {
      return const SizedBox.shrink();
    }
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildKeyContent(context),
          ),
        );
      }
    );
  }
  
  Widget _buildKeyContent(BuildContext context) {
    // Get screen size for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
        width: min(screenWidth * 0.9, 500),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cipher Key',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 16.0 : 18.0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  constraints: BoxConstraints.tight(
                    Size(isSmallScreen ? 32.0 : 40.0, isSmallScreen ? 32.0 : 40.0)
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            widget.selectedEncoding != null
              ? _buildImageKey(context)
              : _buildSubstitutionKey(context, isSmallScreen),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageKey(BuildContext context) {
    return FutureBuilder(
      future: _checkKeyImageExists(),
      builder: (context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.data == true) {
          // Image key exists
          return Image.asset(
            'assets/key/${widget.selectedEncoding}_key.png',
            fit: BoxFit.contain,
            height: 200,
            errorBuilder: (context, error, stackTrace) => 
              _buildErrorWidget('Could not load key image'),
          );
        } else {
          // No image key exists, generate one if possible
          return _buildGeneratedImageKey(context);
        }
      },
    );
  }
  
  Widget _buildGeneratedImageKey(BuildContext context) {
    // This would be an automatically generated key for image-based ciphers
    // For now, showing a placeholder with instructions
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No key available for ${widget.selectedEncoding}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubstitutionKey(BuildContext context, bool isSmallScreen) {
    final alphabet = List.generate(26, (index) => String.fromCharCode(65 + index));
    
    // Determine grid layout based on screen size
    final crossAxisCount = isSmallScreen ? 4 : 6;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: alphabet.length,
      itemBuilder: (context, index) {
        final letter = alphabet[index];
        final substitution = widget.substitutionMap[letter] ?? '?';
        
        return Container(
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
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward,
                  size: isSmallScreen ? 12 : 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                substitution,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        );
      },
    );
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
  
  Future<bool> _checkKeyImageExists() async {
    if (widget.selectedEncoding == null) return false;
    
    try {
      // This is a simplified check - in a real app you would use AssetManifest
      // or another method to check if the asset exists
      await DefaultAssetBundle.of(context).load('assets/key/${widget.selectedEncoding}_key.png');
      return true;
    } catch (_) {
      return false;
    }
  }
}