import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/services.dart';
import '../theme/theme_constants.dart';
import '../constants/strings.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const SplashScreen({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _rotationController;
  late AnimationController _starController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _scaleAnimation;
  bool _showSun = false;
  final List<_Star> _stars = [];

  @override
  void initState() {
    super.initState();
    
    // Générer des étoiles
    for (int i = 0; i < 50; i++) {
      _stars.add(_Star(
        x: math.Random().nextDouble() * 400 - 200,
        y: math.Random().nextDouble() * 400 - 200,
        size: math.Random().nextDouble() * 3 + 1,
      ));
    }
    
    // Controller principal pour l'animation complète
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Controller pour la rotation continue
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    
    // Controller pour l'animation des étoiles
    _starController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    ));

    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.easeInOut,
    ));

    _mainController.addListener(() {
      if (_mainController.value > 0.5 && !_showSun) {
        setState(() => _showSun = true);
        
        // Ajouter un léger feedback haptique lors du changement
        HapticFeedback.lightImpact();
      }
    });

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          widget.onComplete();
        });
      }
    });

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rotationController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(
                  ThemeConstants.nightPrimaryGradient.colors.first,
                  ThemeConstants.dayPrimaryGradient.colors.first,
                  _backgroundAnimation.value,
                )!,
                Color.lerp(
                  ThemeConstants.nightPrimaryGradient.colors.last,
                  ThemeConstants.dayPrimaryGradient.colors.last,
                  _backgroundAnimation.value,
                )!,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Stars in background
              if (_backgroundAnimation.value < 0.7)
                AnimatedBuilder(
                  animation: _starController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _StarPainter(
                        stars: _stars,
                        opacity: 1.0 - _backgroundAnimation.value,
                        scale: _scaleAnimation.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
                
              // Clouds in foreground when day appears
              if (_backgroundAnimation.value > 0.5)
                Positioned.fill(
                  child: Opacity(
                    opacity: (_backgroundAnimation.value - 0.5) * 2,
                    child: const _CloudsWidget(),
                  ),
                ),
                
              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_showSun 
                                  ? ThemeConstants.dayAccent 
                                  : ThemeConstants.nightAccent).withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        
                        // Progress circle
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: _progressAnimation.value,
                            strokeWidth: 4,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _showSun ? ThemeConstants.dayAccent : ThemeConstants.nightAccent,
                            ),
                          ),
                        ),
                        
                        // Rotating icon
                        Transform.rotate(
                          angle: _rotationController.value * 2 * math.pi,
                          child: Icon(
                            _showSun ? Icons.wb_sunny : Icons.nightlight_round,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 32,
                        fontFamily: ThemeConstants.fontFamily,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          FadeAnimatedText(
                            Strings.appTitle,
                            duration: const Duration(milliseconds: 2000),
                            fadeOutBegin: 0.8,
                            fadeInEnd: 0.2,
                          ),
                        ],
                        isRepeatingAnimation: false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double size;

  _Star({required this.x, required this.y, required this.size});
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double opacity;
  final double scale;

  _StarPainter({required this.stars, required this.opacity, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    for (var star in stars) {
      canvas.drawCircle(
        center + Offset(star.x, star.y),
        star.size * scale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => 
    opacity != oldDelegate.opacity || scale != oldDelegate.scale;
}

class _CloudsWidget extends StatelessWidget {
  const _CloudsWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CloudsPainter(),
      size: Size.infinite,
    );
  }
}

class _CloudsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    void drawCloud(double x, double y, double scale) {
      final path = Path();
      path.moveTo(x, y);
      path.addOval(Rect.fromCircle(center: Offset(x, y), radius: 20 * scale));
      path.addOval(Rect.fromCircle(center: Offset(x + 15 * scale, y - 10 * scale), radius: 15 * scale));
      path.addOval(Rect.fromCircle(center: Offset(x + 30 * scale, y), radius: 20 * scale));
      canvas.drawPath(path, paint);
    }

    drawCloud(size.width * 0.2, size.height * 0.2, 1.0);
    drawCloud(size.width * 0.6, size.height * 0.3, 1.3);
    drawCloud(size.width * 0.4, size.height * 0.7, 0.8);
    drawCloud(size.width * 0.8, size.height * 0.6, 1.2);
  }

  @override
  bool shouldRepaint(covariant _CloudsPainter oldDelegate) => false;
} 