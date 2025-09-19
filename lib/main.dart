import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const NaPostersApp());
}

class NaPostersApp extends StatelessWidget {
  const NaPostersApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NA Posters',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
