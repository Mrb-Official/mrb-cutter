import 'package:flutter/material.dart';

void main() {
  runApp(const MyChatApp());
}

class MyChatApp extends StatelessWidget {
  const MyChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Abhi ke liye ek dummy screen de rahe hain
      home: const Scaffold(
        body: Center(
          child: Text("Welcome to Chat App!"),
        ),
      ),
    );
  }
}