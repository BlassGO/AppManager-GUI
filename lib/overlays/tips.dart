import 'package:flutter/material.dart';
import 'package:app_manager/utils/config.dart';

class HintMessage extends StatefulWidget {
  final String hintKey;
  final Widget child;
  final String message;
  final RelativeRect Function(RenderBox box)? getPosition;
  final String dismissButtonText;
  final double? hintWidth;

  const HintMessage({
    required this.hintKey,
    required this.child,
    required this.message,
    this.hintWidth,
    this.getPosition,
    this.dismissButtonText = 'SKIP',
    Key? key,
  }) : super(key: key);

  @override
  State<HintMessage> createState() => HintMessageState();
}

class HintMessageState extends State<HintMessage> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _widgetKey = GlobalKey();
  bool _hasBeenDismissed = false;

  @override
  void initState() {
    super.initState();
    _hasBeenDismissed = ConfigUtils.firstSteps.contains(widget.hintKey);
  }

  void showHint() {
    if (!_hasBeenDismissed && _overlayEntry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showHint());
    }
  }

  void _showHint() {
    if (_hasBeenDismissed || !mounted) return;

    final RenderBox renderBox = _widgetKey.currentContext?.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    RelativeRect hintPosition = widget.getPosition != null
        ? widget.getPosition!(renderBox)
        : RelativeRect.fromLTRB(
            offset.dx + size.width / 2 - 150,
            offset.dy + size.height + 10,
            screenSize.width - (offset.dx + size.width / 2 + 150),
            screenSize.height - (offset.dy + size.height + 10 + 100),
          );

    double adjustedTop = hintPosition.top;
    double adjustedLeft = hintPosition.left;
    const hintWidth = 350.0;
    const maxHintHeight = 150.0;

    if (adjustedTop + maxHintHeight > screenSize.height) {
      adjustedTop = offset.dy - maxHintHeight - 10;
    }
    if (adjustedLeft + hintWidth > screenSize.width) {
      adjustedLeft = screenSize.width - hintWidth;
    }
    if (adjustedLeft < 0) {
      adjustedLeft = 0;
    }
    if (adjustedTop < 0) {
      adjustedTop = offset.dy + size.height + 10;
    }

    hintPosition = RelativeRect.fromLTRB(
      adjustedLeft,
      adjustedTop,
      screenSize.width - (adjustedLeft + hintWidth),
      screenSize.height - (adjustedTop + maxHintHeight),
    );

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fromRelativeRect(
          rect: hintPosition,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.grey[900],
            child: Container(
              width: hintWidth,
              constraints: BoxConstraints(maxHeight: maxHintHeight),
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.message,
                      style: const TextStyle(color: Colors.white, fontSize: 16.0),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12.0),
                    ElevatedButton(
                      onPressed: _dismissHint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(widget.dismissButtonText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _dismissHint() {
    ConfigUtils.firstSteps.add(widget.hintKey);
    ConfigUtils.save();
    setState(() {
      _hasBeenDismissed = true;
    });
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(key: _widgetKey, child: widget.child);
  }
}