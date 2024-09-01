import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class PongGame extends StatefulWidget {
  @override
  _PongGameState createState() => _PongGameState();
}

class _PongGameState extends State<PongGame> {
  // Constants
  final double paddleWidth = 100.0;
  final double paddleHeight = 20.0;
  final double ballSize = 20.0;

  // Game variables
  double playerX = 0;
  double aiX = 0;
  double ballX = 0;
  double ballY = 0;
  double ballSpeedX = 3;
  double ballSpeedY = 3;

  // Screen dimensions
  double screenWidth = 0;
  double screenHeight = 0;

  // Scores
  int playerScore = 0;
  int aiScore = 0;

  // Timer for game loop
  late Timer gameTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize screen dimensions and start the game loop
      screenWidth = MediaQuery.of(context).size.width;
      screenHeight = MediaQuery.of(context).size.height;
      resetGame();
      startGameLoop();
    });
  }

  void resetGame() {
    setState(() {
      playerX = 0;
      aiX = 0;
      ballX = 0;
      ballY = 0;
      ballSpeedX = Random().nextBool() ? 3 : -3;
      ballSpeedY = Random().nextBool() ? 3 : -3;
    });
  }

  void startGameLoop() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      updateGame();
    });
  }

  void updateGame() {
    setState(() {
      // Move the ball
      ballX += ballSpeedX;
      ballY += ballSpeedY;

      // Calculate boundaries
      double halfWidth = screenWidth / 2;
      double halfHeight = screenHeight / 2;

      // Ball collision with left and right walls
      if (ballX.abs() + ballSize / 2 >= halfWidth - 10) {
        ballSpeedX *= -1;
      }

      // Scoring conditions
      if (ballY + ballSize / 2 >= halfHeight - 10) {
        aiScore++;
        resetGame();
      } else if (ballY - ballSize / 2 <= -halfHeight + 10) {
        playerScore++;
        resetGame();
      }

      // Player paddle collision
      double playerPaddleY = halfHeight - paddleHeight - 30;
      if (ballY + ballSize / 2 >= playerPaddleY &&
          (ballX - playerX).abs() <= paddleWidth / 2) {
        ballSpeedY *= -1;
        ballSpeedX = ((ballX - playerX) / (paddleWidth / 2)) * 5;
      }

      // AI paddle collision
      double aiPaddleY = -halfHeight + paddleHeight + 30;
      if (ballY - ballSize / 2 <= aiPaddleY &&
          (ballX - aiX).abs() <= paddleWidth / 2) {
        ballSpeedY *= -1;
        ballSpeedX = ((ballX - aiX) / (paddleWidth / 2)) * 5;
      }

      // AI paddle movement
      if (aiX < ballX && aiX + paddleWidth / 2 < halfWidth - 10) {
        aiX += 4;
      } else if (aiX > ballX && aiX - paddleWidth / 2 > -halfWidth + 10) {
        aiX -= 4;
      }

      // Clamp player paddle position
      playerX = playerX.clamp(
        -halfWidth + paddleWidth / 2 + 10,
        halfWidth - paddleWidth / 2 - 10,
      );

      // Clamp AI paddle position
      aiX = aiX.clamp(
        -halfWidth + paddleWidth / 2 + 10,
        halfWidth - paddleWidth / 2 - 10,
      );

      // Limit ball speed
      double maxSpeed = 8;
      ballSpeedX = ballSpeedX.clamp(-maxSpeed, maxSpeed);
      ballSpeedY = ballSpeedY.clamp(-maxSpeed, maxSpeed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            playerX += details.delta.dx;
          });
        },
        child: Stack(
          children: [
            // Player paddle
            Positioned(
              bottom: 30,
              left: (screenWidth / 2) + playerX - paddleWidth / 2,
              child: _buildPaddle(Colors.blueAccent),
            ),
            // AI paddle
            Positioned(
              top: 30,
              left: (screenWidth / 2) + aiX - paddleWidth / 2,
              child: _buildPaddle(Colors.redAccent),
            ),
            // Ball
            Positioned(
              top: (screenHeight / 2) + ballY - ballSize / 2,
              left: (screenWidth / 2) + ballX - ballSize / 2,
              child: _buildBall(),
            ),
            // Scores
            Positioned(
              top: 50,
              left: screenWidth / 2 - 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildScore('Player', playerScore),
                  const SizedBox(width: 50),
                  _buildScore('AI', aiScore),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaddle(Color color) {
    return Container(
      width: paddleWidth,
      height: paddleHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildBall() {
    return Container(
      width: ballSize,
      height: ballSize,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildScore(String label, int score) {
    return Text(
      '$label: $score',
      style: const TextStyle(color: Colors.white, fontSize: 18),
    );
  }

  @override
  void dispose() {
    gameTimer.cancel();
    super.dispose();
  }
}
