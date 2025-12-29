import 'package:flutter/material.dart';

void main() {
  runApp(const NanoBananaApp());
}

class NanoBananaApp extends StatelessWidget {
  const NanoBananaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nano Banana Comic',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Nano Banana Mobile App - Coming Soon'),
        ),
      ),
    );
  }
}
