import 'package:flutter/material.dart';
import 'package:app_manager/overlays/alert.dart';
import 'package:app_manager/utils/localization.dart';
import 'package:app_manager/widgets/language_selector.dart';
import 'dart:math' as math;

class IntroductionOverlay extends StatefulWidget {
  final VoidCallback onContinue;

  const IntroductionOverlay({required this.onContinue, super.key});

  @override
  _IntroductionOverlayState createState() => _IntroductionOverlayState();
}

class _IntroductionOverlayState extends State<IntroductionOverlay> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  late AnimationController _contentAnimationController;
  late Animation<Offset> _welcomeSlideAnimation;
  late Animation<Offset> _buttonSlideAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 5),
    )..repeat(reverse: true);
    _backgroundAnimation = CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut);
    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _welcomeSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -2.0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOut,
    ));
    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 2.0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOut,
    ));
    Localization.languageNotifier.addListener(_handleLanguageChange);
    _contentAnimationController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentAnimationController.dispose();
    Localization.languageNotifier.removeListener(_handleLanguageChange);
    super.dispose();
  }

  void _handleLanguageChange() {
    if (mounted) {
      setState(() {});
      _contentAnimationController.forward(from: 0.0);
    }
  }

  Future<void> _selectLanguage(String languageCode) async {
    try {
      await Localization.loadLocale(languageCode);
      if (mounted) {
        setState(() {});
        _contentAnimationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        Alert.showWarning(context, Localization.translate('error_selecting_language'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[850]?.withOpacity(0.9),
        body: SafeArea(
          child: Stack(
            children: [
              AnimatedBackground(animation: _backgroundAnimation),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.9,
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SlideTransition(
                              position: _welcomeSlideAnimation,
                              child: Text(
                                Localization.translate('welcome'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              Localization.translate('welcome_message'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            LanguageSelectorWidget(
                              onLanguageSelected: _selectLanguage,
                              onLanguageChanged: () {
                                if (mounted) {
                                  setState(() {});
                                  _contentAnimationController.forward(from: 0.0);
                                }
                              },
                              titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
                              hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
                              searchFieldFillColor: Colors.white.withOpacity(0.1),
                              iconColor: Colors.white70,
                              borderRadius: BorderRadius.circular(20),
                              listHeight: 200,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            const SizedBox(height: 24),
                            SlideTransition(
                              position: _buttonSlideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (mounted) {
                                      setState(() {});
                                      Future.delayed(const Duration(milliseconds: 400), () {
                                        if (mounted) widget.onContinue();
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: Text(
                                    Localization.translate('continue_button'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  final Animation<double> animation;

  const AnimatedBackground({required this.animation, super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> {
  final List<FloatingShape> _shapes = [];
  final int _shapeCount = 10;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(() => _updatePositions());
  }

  void _updatePositions() {
    setState(() {
      final Size screenSize = MediaQuery.of(context).size;
      final Offset center = Offset(screenSize.width / 2, screenSize.height / 2);
      const double margin = 100;
      const double containerWidth = 400;
      final double exclusionWidth = containerWidth * 0.9;
      final double exclusionHeight = screenSize.height * 0.45;
      final Rect exclusionZone = Rect.fromCenter(
        center: center,
        width: exclusionWidth,
        height: exclusionHeight,
      );

      for (var shape in _shapes) {
        shape.position += shape.velocity;
        bool rebounded = false;

        if (shape.position.dx < -margin || shape.position.dx > screenSize.width + margin) {
          shape.velocity = Offset(-shape.velocity.dx * 0.8, shape.velocity.dy);
          rebounded = true;
        }

        if (shape.position.dy < -margin || shape.position.dy > screenSize.height + margin) {
          shape.velocity = Offset(shape.velocity.dx, -shape.velocity.dy * 0.8);
          rebounded = true;
        }

        if (rebounded) {
          final Offset toCenter = center - shape.position;
          final Offset direction = toCenter / toCenter.distance;
          final Offset nextPos = shape.position + direction * 10;

          if (!exclusionZone.contains(nextPos)) {
            shape.velocity += direction * 0.1;
          } else {
            final double angle = 0.4;
            final double dx = direction.dx * math.cos(angle) - direction.dy * math.sin(angle);
            final double dy = direction.dx * math.sin(angle) + direction.dy * math.cos(angle);
            shape.velocity += Offset(dx, dy) * 0.05;
          }
        }
      }
    });
  }

  void _initializeShapes(Size size) {
    _shapes.clear();

    for (int i = 0; i < _shapeCount; i++) {
      final shapeType = ShapeType.values[_random.nextInt(3)];
      final velocity = Offset(
        (_random.nextDouble() * 0.4 - 0.2),
        (_random.nextDouble() * 0.4 - 0.2),
      );
      int side = i % 4;
      late Offset position;

      switch (side) {
        case 0:
          position = Offset(
            _random.nextDouble() * size.width,
            _random.nextDouble() * 30,
          );
          break;
        case 1:
          position = Offset(
            size.width - _random.nextDouble() * 30,
            _random.nextDouble() * size.height,
          );
          break;
        case 2:
          position = Offset(
            _random.nextDouble() * size.width,
            size.height - _random.nextDouble() * 30,
          );
          break;
        case 3:
          position = Offset(
            _random.nextDouble() * 30,
            _random.nextDouble() * size.height,
          );
          break;
      }

      _shapes.add(FloatingShape(
        position: position,
        velocity: velocity,
        size: 60 + _random.nextDouble() * 120,
        opacity: 0.15 + _random.nextDouble() * 0.2,
        color: Colors.blueAccent.withOpacity(0.3 + _random.nextDouble() * 0.3),
        shape: shapeType,
      ));
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_updatePositions);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_shapes.isEmpty) {
          _initializeShapes(constraints.biggest);
        }
        return CustomPaint(
          painter: _BackgroundPainter(_shapes),
          child: Container(),
        );
      },
    );
  }
}

enum ShapeType { circle, square, rectangle }

class FloatingShape {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  Color color;
  ShapeType shape;

  FloatingShape({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
    required this.color,
    required this.shape,
  });
}

class _BackgroundPainter extends CustomPainter {
  final List<FloatingShape> shapes;

  _BackgroundPainter(this.shapes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var shape in shapes) {
      paint.color = shape.color.withOpacity(shape.opacity);
      switch (shape.shape) {
        case ShapeType.circle:
          canvas.drawCircle(shape.position, shape.size / 2, paint);
          break;
        case ShapeType.square:
          canvas.drawRect(
            Rect.fromCenter(center: shape.position, width: shape.size, height: shape.size),
            paint,
          );
          break;
        case ShapeType.rectangle:
          canvas.drawRect(
            Rect.fromCenter(center: shape.position, width: shape.size * 1.5, height: shape.size * 0.6),
            paint,
          );
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}