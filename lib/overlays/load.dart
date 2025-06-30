import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, String message) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (_) => Material(
        color: Color.fromRGBO(0, 0, 0, 0.5),
        child: Center(
          child: Card(
            elevation: 2.0,
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeIn(
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  FadeIn(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      message,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation({super.key});

  @override
  _LoadingAnimationState createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final start = index * 0.2;
        final end = start + 0.6;

        final offsetTween = Tween<Offset>(
          begin: Offset(0.15 * (1 - index), 0),
          end: Offset(-0.15 * (1 - index), 0),
        );

        return SlideTransition(
          position: offsetTween.animate(CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeInOut),
          )),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(
              parent: _controller,
              curve: Interval(start, end, curve: Curves.easeInOut),
            )),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        );
      }),
    );
  }
}