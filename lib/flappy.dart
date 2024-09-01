import 'dart:async';
import 'package:flutter/material.dart';
import 'firebase/firebase_service.dart';
import 'bird.dart';
import 'barrier.dart';
import '../services/firestore_service.dart';

class Flappy extends StatefulWidget {
  final String userId;
  const Flappy({Key? key, required this.userId}) : super(key: key);

  @override
  State<Flappy> createState() => _FlappyState();
}

class _FlappyState extends State<Flappy> {
  //bird variables
  static double birdY = 0;
  double initialPos = birdY;
  double height = 0;
  double time = 0;
  double gravity = -9.8;
  double velocity = 3.50;
  double birdWidth = 0.1;
  double birdHeight = 0.1;
  int score = 0;
  int highScore = 0;
  List<bool> scoreBarriers = [false, false];
  //game settings
  bool gameHasStarted = false;
  final FirebaseService _firebaseService = FirebaseService();
  final FirestoreService _firestoreService = FirestoreService();

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
    int fetchedHighScore =
        await _firebaseService.getHighScore(widget.userId, 'flappy_bird');
    setState(() {
      highScore = fetchedHighScore;
    });
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

  void _showDialogue() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.brown,
            title: Center(
              child: Text(
                "G A M E  O V E R",
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
                        child: Text(
                          "PLAY AGAIN",
                          style: TextStyle(
                            color: Colors.brown,
                          ),
                        ),
                      )))
            ],
          );
        });
  }

  void startGame() {
    gameHasStarted = true;
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      height = gravity * time * time + velocity * time;

      setState(() {
        birdY = initialPos - height;
      });

      for (int i = 0; i < barrierX.length; i++) {
        barrierX[i] -= 0.05;

        if (barrierX[i] < -1.5) {
          barrierX[i] += 3;
          scoreBarriers[i] = false;
        }

        if (barrierX[i] < -birdWidth && !scoreBarriers[i]) {
          score++;
          scoreBarriers[i] = true;
        }
      }

      //check if bird is dead
      if (birdIsDead()) {
        timer.cancel();
        _updateHighScore();
        gameHasStarted = false;
        _showDialogue();
      }

      //print(birdY);
      //keep time going
      time += 0.01;
    });
  }

  Future<void> _updateHighScore() async {
    if (score > highScore) {
      setState(() {
        highScore = score;
      });
      await _firebaseService.updateHighScore(
          widget.userId, 'flappy_bird', highScore);
      await _firestoreService.xpIncrease(widget.userId, highScore);
    }
  }

  void jump() {
    setState(() {
      time = 0;
      initialPos = birdY;
    });
  }

//check bird is hitting top or bottom of the screen
  bool birdIsDead() {
    if (birdY < -1 || birdY > 1) {
      return true;
    }

    for (int i = 0; i < barrierX.length; i++) {
      if (barrierX[i] <= birdWidth &&
          barrierX[i] + barrierWidth >= -birdWidth &&
          (birdY <= -1 + barrierHeight[i][0] ||
              birdY + birdHeight >= 1 - barrierHeight[i][1])) {
        return true;
      }
    }
    return false;
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
                    Text('High Score: $highScore',
                        style: TextStyle(fontSize: 20)),
                  ],
                ),
              ),
            ),
          ),
        ])));
  }
}
