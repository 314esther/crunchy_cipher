import 'dart:convert';
import 'package:flutter/services.dart';

class CipherKeyManager {
  // Singleton pattern
  static final CipherKeyManager _instance = CipherKeyManager._internal();
  factory CipherKeyManager() => _instance;
  CipherKeyManager._internal();
  
  // Cache of available keys
  final Map<String, bool> _keyAvailabilityCache = {};
  
  // Check if a key is available for a given encoding type
  Future<bool> isKeyAvailable(String? encodingType) async {
    // Substitution cipher always has a key available (generated)
    if (encodingType == null) return true;
    
    // Check cache first
    if (_keyAvailabilityCache.containsKey(encodingType)) {
      return _keyAvailabilityCache[encodingType]!;
    }
    
    // Check for image key
    final bool hasImageKey = await _checkImageKeyExists(encodingType);
    
    // Cache the result
    _keyAvailabilityCache[encodingType] = hasImageKey;
    
    return hasImageKey;
  }
  
  // Check if an image key exists for the encoding type
  Future<bool> _checkImageKeyExists(String encodingType) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final keyPath = 'assets/key/${encodingType}_key.png';
      return manifestMap.containsKey(keyPath);
    } catch (e) {
      return false;
    }
  }
  
  // Clear cache (useful when new assets might have been added)
  void clearCache() {
    _keyAvailabilityCache.clear();
  }
}