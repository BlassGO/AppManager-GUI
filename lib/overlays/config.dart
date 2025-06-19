import 'package:flutter/material.dart';
import 'package:app_manager/services/adb.dart';
import 'package:app_manager/services/manager.dart';
import 'package:app_manager/overlays/alert.dart';
import 'package:app_manager/utils/config.dart';

class ConfigOverlay extends StatefulWidget {
  final VoidCallback? onConnect;
  final VoidCallback? refreshUI;
  const ConfigOverlay({this.onConnect, this.refreshUI, super.key});
  @override
  State<ConfigOverlay> createState() => _ConfigOverlayState();
}

class _ConfigOverlayState extends State<ConfigOverlay> with TickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '5555');
  bool _connecting = false;
  bool _disconnecting = false;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showScrollHint = ValueNotifier(false);
  bool _optionsExpanded = false;
  late AnimationController _introAnimationController;
  late Animation<double> _introAnimation;
  late AnimationController _expandAnimationController;

  @override
  void initState() {
    super.initState();
    _ipController.text = ConfigUtils.lastWirelessIp ?? '';
    _portController.text = ConfigUtils.lastWirelessPort ?? '5555';
    _scrollController.addListener(_handleScroll);

    _introAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _introAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(CurvedAnimation(
      parent: _introAnimationController,
      curve: Curves.easeInOut,
    ))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _introAnimationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _introAnimationController.stop();
        }
      });

    _expandAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
          _handleScroll();
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _introAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _showScrollHint.dispose();
    _introAnimationController.dispose();
    _expandAnimationController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.hasClients) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final pixels = _scrollController.position.pixels;
      if (pixels > 0 && _showScrollHint.value) {
        _showScrollHint.value = false;
      } else if (maxScrollExtent > 50 && pixels == 0) {
        _showScrollHint.value = true;
      }
    }
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    if (ip.isEmpty || port.isEmpty) {
      Alert.showWarning(context, 'Please enter both IP and port.');
      setState(() => _connecting = false);
      return;
    }
    ConfigUtils.lastWirelessIp = ip;
    ConfigUtils.lastWirelessPort = port;
    await ConfigUtils.save();
    final ok = await AdbService.connectTcp(ip, port);
    setState(() => _connecting = false);
    if (ok) {
      Navigator.of(context).pop();
      widget.onConnect?.call();
    } else {
      Alert.showWarning(
        context,
        'Could not connect to $ip:$port.\n\nMake sure the device is on the same network'
      );
    }
  }

  Future<void> _disconnect() async {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    setState(() => _disconnecting = true);
    final ok = await AdbService.disconnectTcp(ip, port);
    setState(() => _disconnecting = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      Alert.showWarning(context, 'Could not disconnect. See log for details.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const double optionItemHeight = 44.0;
    const double padding = 8.0;
    const double expandedOptionsMaxHeight = optionItemHeight * 3 + padding;

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text('Settings', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _optionsExpanded = !_optionsExpanded;
                  if (_optionsExpanded) {
                    _expandAnimationController.forward(from: 0.0);
                  } else {
                    _expandAnimationController.reverse(from: 1.0);
                  }
                });
              },
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OPTIONS',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Icon(
                          _optionsExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _introAnimation,
              builder: (context, child) {
                return AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: SizedBox(
                    height: _introAnimationController.isDismissed ? 0.0 : null,
                    child: _introAnimationController.isDismissed || _optionsExpanded
                        ? const SizedBox.shrink()
                        : Container(
                            height: _introAnimation.value,
                            color: Colors.grey[800]?.withOpacity(0.5),
                          ),
                ),
              );
              }
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                child: SizedBox(
                  height: _optionsExpanded ? expandedOptionsMaxHeight : 0.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: OptionItem(
                          title: 'Never uninstall, only deactivate',
                          tooltip: 'Deactivate uninstallable apps and clear their data',
                          value: ConfigUtils.neverUninstallApps,
                          onChanged: (value) {
                            setState(() {});
                            ConfigUtils.neverUninstallApps = value ?? false;
                            ConfigUtils.save();
                            ManagerService.updateActionCounters();
                            widget.refreshUI?.call();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: OptionItem(
                          title: 'Export all apps list',
                          tooltip: 'Export all apps, even if there are no changes',
                          value: ConfigUtils.exportAllApps,
                          onChanged: (value) {
                            setState(() {});
                            ConfigUtils.exportAllApps = value ?? false;
                            ConfigUtils.save();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: OptionItem(
                          title: 'Refresh all icons',
                          tooltip: 'Always clear the icon cache to refresh all app icons',
                          value: ConfigUtils.refreshIcons,
                          onChanged: (value) {
                            setState(() {});
                            ConfigUtils.refreshIcons = value ?? false;
                            ConfigUtils.save();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text('TCP/IP', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 8),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'Device IP',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'e.g. 192.168.1.100',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _portController,
              decoration: InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'e.g. 5555',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: _connecting
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(Icons.wifi),
                  label: Text('Connect'),
                  onPressed: _connecting ? null : _connect,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: _disconnecting
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                      : Icon(Icons.link_off, color: Colors.red),
                  label: Text('Disconnect', style: TextStyle(color: Colors.red)),
                  onPressed: _disconnecting ? null : _disconnect,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ScrollHintWidget(showHint: _showScrollHint),
        TextButton(
          child: Text('Close', style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class OptionItem extends StatelessWidget {
  final String title;
  final String tooltip;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const OptionItem({
    required this.title,
    required this.tooltip,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        value: value,
        onChanged: onChanged,
        tileColor: null,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        visualDensity: VisualDensity(horizontal: -2, vertical: -4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
    );
  }
}

class ScrollHintWidget extends StatefulWidget {
  final ValueNotifier<bool> showHint;

  const ScrollHintWidget({required this.showHint, super.key});

  @override
  State<ScrollHintWidget> createState() => _ScrollHintWidgetState();
}

class _ScrollHintWidgetState extends State<ScrollHintWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.showHint,
      builder: (context, show, child) {
        return AnimatedOpacity(
          opacity: show ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _rotationAnimation,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.7,
                    child: Text(
                      'Swipe down',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}