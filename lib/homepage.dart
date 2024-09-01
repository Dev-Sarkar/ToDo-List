// lib/homepage.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'firebase/firebase_service.dart';
import 'bird.dart';
import 'barrier.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static double birdY = 0;
  double initialPos = birdY;
  double height = 0;
  double time = 0;
  double gravity = -4.9;
  double velocity = 3;
  int score = 0;
  int highScore = 0;
  List<bool> scoreBarriers = [false, false];
  bool gameHasStarted = false;
  final FirebaseService _firebaseService = FirebaseService();
  final String userId = "exampleUserId"; // Replace with actual user ID

  // barrier varibales
  static List<double> barrierX = [2, 2 + 1.5];
  static double barrierWidth = 0.5;
  List<List<double>> barrierHeight = [
    // [topheight,bottomHeight]
    [0.6, 0.4],
    [0.4, 0.6],
  ];
  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    int fetchedHighScore = await _firebaseService.getHighScore(userId,'flappy_bird');
    setState(() {
      highScore = fetchedHighScore;
    });
  }

  void startGame() {
    gameHasStarted = true;
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      height = gravity * time * time + velocity * time;

      setState(() {
        birdY = initialPos - height;
      });

      if (birdIsDead()) {
        timer.cancel();
        gameHasStarted = false;
        _showGameOverDialog();
        _updateHighScore();
      }

      time += 0.01;
    });
  }

  void jump() {
    setState(() {
      time = 0;
      initialPos = birdY;
      score++;
    });
  }

  bool birdIsDead() {
    return birdY < -1 || birdY > 1;
  }

  void resetGame() {
    Navigator.pop(context);
    setState(() {
      birdY = 0;
      gameHasStarted = false;
      time = 0;
      initialPos = birdY;
      score = 0;
    });
  }

  Future<void> _updateHighScore() async {
    if (score > highScore) {
      setState(() {
        highScore = score;
      });
      await _firebaseService.updateHighScore(userId,'flappy_bird', highScore);
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.brown,
          title: Center(
            child: Text(
              "GAME OVER",
              style: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: resetGame,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  padding: EdgeInsets.all(7),
                  color: Colors.white,
                  child: Text("PLAY AGAIN", style: TextStyle(color: Colors.brown)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }



@override
Widget build(BuildContext context) {
  return GestureDetector(
      onTap: gameHasStarted ? jump : startGame,
      child: Scaffold(
          body: Column(children: [
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.lightBlue,
                child: Center(
                  child: Stack(
                    children: [
                      MyBird(
                        birdY: birdY,

                      ),
                      MyBarrier(
                        barrierX: barrierX[0],
                        barrierWidth: barrierWidth,
                        barrierHeight: barrierHeight[0][0],
                        isThisBottomBarrier: false,
                      ),
                      MyBarrier(
                        barrierX: barrierX[0],
                        barrierWidth: barrierWidth,
                        barrierHeight: barrierHeight[0][1],
                        isThisBottomBarrier: true,
                      ),
                      MyBarrier(
                        barrierX: barrierX[0],
                        barrierWidth: barrierWidth,
                        barrierHeight: barrierHeight[1][0],
                        isThisBottomBarrier: true,
                      ),
                      MyBarrier(
                        barrierX: barrierX[0],
                        barrierWidth: barrierWidth,
                        barrierHeight: barrierHeight[1][1],
                        isThisBottomBarrier: false,
                      ),
                      Container(
                        alignment: Alignment(0, -0.5),
                        child: Text(
                          gameHasStarted ? '' : 'T A P  T O  P L A Y',
                          style: TextStyle(color: Colors.black, fontSize: 25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.brown,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Score: $score', style: TextStyle(fontSize: 40)),
                      Text('High Score: $highScore', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
            ),
          ])));
}
}