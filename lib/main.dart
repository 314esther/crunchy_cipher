import 'package:flutter/material.dart';
import 'splash_page.dart';

void main() {
  runApp(const CipherApp());
}

class CipherApp extends StatelessWidget {
  const CipherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crazy Crunchy Ciphers',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}