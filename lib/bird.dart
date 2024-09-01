// lib/bird.dart

import 'package:flutter/material.dart';

class MyBird extends StatelessWidget {
  final double birdY;

  MyBird({required this.birdY});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment(0, birdY),
      child: Image.asset(
        'android/assets/images/bird2.png',
        width: 50,
        height: 50,
      ),
    );
  }
}
