import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:autilog/core/theme/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutiLog',
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: Text('AutiLog'),
        ),
      ),
    );
  }
}