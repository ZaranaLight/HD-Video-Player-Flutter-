import 'package:flutter/material.dart';

class EaseCleanerScreen extends StatelessWidget {
  const EaseCleanerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Ease Cleaner Screen',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
