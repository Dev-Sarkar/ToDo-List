import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FireworksAnimation extends StatelessWidget {
  final bool showFireworks;
  final String animationPath;

  const FireworksAnimation({Key? key, required this.showFireworks,required this.animationPath,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return showFireworks
        ? Positioned.fill(
      child: Lottie.asset(
        animationPath, // Ensure correct asset path
        fit: BoxFit.cover,
      ),
    )
        : const SizedBox.shrink();
  }
}
