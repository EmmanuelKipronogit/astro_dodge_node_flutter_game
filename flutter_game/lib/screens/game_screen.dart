import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  double playerX = 0; // -1.0 left, 1.0 right
  int score = 0;
  int coins = 0;
  bool isGameOver = false;
  Timer? gameTimer;
  List<Point<double>> meteorites = [];
  List<Point<double>> stars = [];
  Random random = Random();

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    score = 0;
    coins = 0;
    isGameOver = false;
    meteorites.clear();
    stars.clear();

    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        score += 1;

        // Spawn meteorites
        if (random.nextDouble() < 0.15) {
          meteorites.add(Point((random.nextDouble() * 2) - 1, -1.2));
        }

        // Spawn stars
        if (random.nextDouble() < 0.08) {
          stars.add(Point((random.nextDouble() * 2) - 1, -1.2));
        }

        // Update positions
        for (int i = 0; i < meteorites.length; i++) {
          meteorites[i] = Point(meteorites[i].x, meteorites[i].y + 0.04);
        }
        for (int i = 0; i < stars.length; i++) {
          stars[i] = Point(stars[i].x, stars[i].y + 0.03);
        }

        // Collision Check - Meteorites
        for (var m in meteorites) {
          if ((m.x - playerX).abs() < 0.2 && m.y > 0.7 && m.y < 0.9) {
            endGame();
            break;
          }
        }

        // Collection Check - Stars
        stars.removeWhere((s) {
          if ((s.x - playerX).abs() < 0.2 && s.y > 0.7 && s.y < 0.9) {
            coins += 1;
            return true;
          }
          return s.y > 1.2;
        });

        // Cleanup out-of-screen meteorites
        meteorites.removeWhere((m) => m.y > 1.2);
      });
    });
  }

  void endGame() {
    gameTimer?.cancel();
    setState(() {
      isGameOver = true;
    });
    AuthService.submitScore(score, coins);
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            playerX += details.delta.dx / (MediaQuery.of(context).size.width / 2);
            playerX = playerX.clamp(-1.0, 1.0);
          });
        },
        child: Stack(
          children: [
            // Game canvas
            Container(color: const Color(0xFF0F172A)),
            
            // Meteorites
            ...meteorites.map((m) => Align(
                  alignment: Alignment(m.x, m.y),
                  child: const Icon(Icons.shield, color: Colors.redAccent, size: 36),
                )),

            // Stars / Coins
            ...stars.map((s) => Align(
                  alignment: Alignment(s.x, s.y),
                  child: const Icon(Icons.star, color: Colors.amber, size: 28),
                )),

            // Player Ship
            Align(
              alignment: Alignment(playerX, 0.8),
              child: const Icon(Icons.navigation, color: Colors.cyanAccent, size: 48),
            ),

            // Top Overlay (Score & Coins)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SCORE: $score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('COINS: $coins', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
                ],
              ),
            ),

            // Game Over Dialog
            if (isGameOver)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('GAME OVER', style: TextStyle(fontSize: 28, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text('Final Score: $score', style: const TextStyle(fontSize: 18, color: Colors.white)),
                      Text('Coins Collected: $coins', style: const TextStyle(fontSize: 18, color: Colors.amber)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: startGame,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                        child: const Text('PLAY AGAIN'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          await AuthService.logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text('Logout', style: TextStyle(color: Colors.grey)),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
