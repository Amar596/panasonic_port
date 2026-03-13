import 'package:flutter/material.dart';
import 'package:panasonic_port/MyHome_Page.dart';
import 'wauly_monitor_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panasonic Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Panasoic Monitor App'),
      debugShowCheckedModeBanner: false,
    );
  }
}
