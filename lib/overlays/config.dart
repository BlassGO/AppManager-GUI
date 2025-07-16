import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_manager/services/adb.dart';
import 'package:app_manager/services/manager.dart';
import 'package:app_manager/overlays/alert.dart';
import 'package:app_manager/utils/config.dart';
import 'package:app_manager/utils/file_manager.dart';
import 'package:animate_do/animate_do.dart';
import 'package:app_manager/utils/localization.dart';
import 'package:app_manager/widgets/language_selector.dart';

class ConfigOverlay extends StatefulWidget {
  final VoidCallback? onConnect;
  final VoidCallback? refreshUI;
  const ConfigOverlay({this.onConnect, this.refreshUI, super.key});

  @override
  State<ConfigOverlay> createState() => ConfigOverlayState();
}

class ConfigOverlayState extends State<ConfigOverlay> with TickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '5555');
  bool _connecting = false;
  bool _disconnecting = false;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showScrollHint = ValueNotifier(false);

  late AnimationController _optionsAnimationController;
  late Animation<double> _optionsAnimation;
  bool _optionsExpanded = false;

  late AnimationController _actionsAnimationController;
  late Animation<double> _actionsAnimation;
  bool _actionsExpanded = false;

  late AnimationController _languageAnimationController;
  late Animation<double> _languageAnimation;
  bool _languageExpanded = false;

  @override
  void initState() {
    super.initState();
    _ipController.text = ConfigUtils.lastWirelessIp ?? '';
    _portController.text = ConfigUtils.lastWirelessPort ?? '5555';
    _scrollController.addListener(_handleScroll);

    _optionsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _optionsAnimation = CurvedAnimation(
      parent: _optionsAnimationController,
      curve: Curves.easeInOut,
    );

    _actionsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _actionsAnimation = CurvedAnimation(
      parent: _actionsAnimationController,
      curve: Curves.easeInOut,
    );

    _languageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _languageAnimation = CurvedAnimation(
      parent: _languageAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _showScrollHint.dispose();
    _ipController.dispose();
    _portController.dispose();
    _optionsAnimationController.dispose();
    _actionsAnimationController.dispose();
    _languageAnimationController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.hasClients) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final pixels = _scrollController.position.pixels;
      if (pixels > 0 && _showScrollHint.value) {
        _showScrollHint.value = false;
      } else if (maxScrollExtent > 30 && pixels == 0) {
        _showScrollHint.value = true;
      }
    }
  }

  void _toggleSection(String section) {
    setState(() {
      if (section == 'options') {
        _optionsExpanded = !_optionsExpanded;
        if (_optionsExpanded) {
          _optionsAnimationController.forward();
        } else {
          _optionsAnimationController.reverse();
        }
      } else if (section == 'actions') {
        _actionsExpanded = !_actionsExpanded;
        if (_actionsExpanded) {
          _actionsAnimationController.forward();
        } else {
          _actionsAnimationController.reverse();
        }
      } else if (section == 'language') {
        _languageExpanded = !_languageExpanded;
        if (_languageExpanded) {
          _languageAnimationController.forward();
        } else {
          _languageAnimationController.reverse();
        }
      }
    });
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    if (ip.isEmpty || port.isEmpty) {
      Alert.showWarning(context, Localization.translate('connect_error_empty'));
      setState(() => _connecting = false);
      return;
    }
    try {
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
          '${Localization.translate('connect_error_network')} $ip:$port.\n\n${Localization.translate('connect_error_network_check')}',
        );
      }
    } catch (e) {
      setState(() => _connecting = false);
      Alert.showWarning(context, Localization.translate('connect_error'));
    }
  }

  Future<void> _disconnect() async {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    setState(() => _disconnecting = true);
    try {
      final ok = await AdbService.disconnectTcp(ip, port);
      setState(() => _disconnecting = false);
      if (ok) {
        Navigator.of(context).pop();
      } else {
        Alert.showWarning(context, Localization.translate('disconnect_error'));
      }
    } catch (e) {
      setState(() => _disconnecting = false);
      Alert.showWarning(context, Localization.translate('disconnect_error'));
    }
  }

  Future<void> _selectLanguage(String languageCode) async {
    try {
      await Localization.loadLocale(languageCode);
      if (mounted) {
        setState(() {});
        widget.refreshUI?.call();
      }
    } catch (e) {
      if (mounted) {
        Alert.showWarning(context, Localization.translate('error_selecting_language'));
      }
    }
  }

  Widget _buildExpandableSection({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    required Widget child,
    required Animation<double> animation,
  }) {
    return Card(
      elevation: 2.0,
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more, color: Colors.white70, size: 20),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: AnimatedOpacity(
              opacity: expanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Offstage(
                offstage: !expanded && animation.value == 0.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double padding = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dialogWidth = constraints.maxWidth * 0.7;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: dialogWidth, maxWidth: dialogWidth),
            child: AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: FadeIn(
                duration: const Duration(milliseconds: 300),
                child: Text(Localization.translate('settings'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
              ),
              content: SizedBox(
                width: dialogWidth,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExpandableSection(
                        title: Localization.translate('options'),
                        expanded: _optionsExpanded,
                        onTap: () => _toggleSection('options'),
                        child: Column(
                          children: [
                            OptionItem(
                              title: Localization.translate('never_uninstall'),
                              tooltip: Localization.translate('never_uninstall_tooltip'),
                              value: ConfigUtils.neverUninstallApps,
                              onChanged: (value) {
                                setState(() {});
                                ConfigUtils.neverUninstallApps = value ?? false;
                                ConfigUtils.save();
                                ManagerService.updateActionCounters();
                                widget.refreshUI?.call();
                              },
                            ),
                            OptionItem(
                              title: Localization.translate('export_all_apps'),
                              tooltip: Localization.translate('export_all_apps_tooltip'),
                              value: ConfigUtils.exportAllApps,
                              onChanged: (value) {
                                setState(() {});
                                ConfigUtils.exportAllApps = value ?? false;
                                ConfigUtils.save();
                              },
                            ),
                            OptionItem(
                              title: Localization.translate('refresh_icons'),
                              tooltip: Localization.translate('refresh_icons_tooltip'),
                              value: ConfigUtils.refreshIcons,
                              onChanged: (value) {
                                setState(() {});
                                ConfigUtils.refreshIcons = value ?? false;
                                ConfigUtils.save();
                              },
                            ),
                          ],
                        ),
                        animation: _optionsAnimation,
                      ),
                      SizedBox(height: padding),
                      _buildExpandableSection(
                        title: Localization.translate('actions'),
                        expanded: _actionsExpanded,
                        onTap: () => _toggleSection('actions'),
                        child: Tooltip(
                          message: Localization.translate('select_adb_tooltip'),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => FileManager.selectAdbFolder(context),
                            child: Text(Localization.translate('select_adb'), style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                        animation: _actionsAnimation,
                      ),
                      SizedBox(height: padding),
                      _buildExpandableSection(
                        title: Localization.translate('language'),
                        expanded: _languageExpanded,
                        onTap: () => _toggleSection('language'),
                        child: LanguageSelectorWidget(
                          onLanguageSelected: _selectLanguage,
                          onLanguageChanged: widget.refreshUI,
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
                          hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
                          searchFieldFillColor: Colors.white.withOpacity(0.1),
                          iconColor: Colors.white70,
                          borderRadius: BorderRadius.circular(12),
                          listHeight: 150,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        animation: _languageAnimation,
                      ),
                      SizedBox(height: padding),
                      Card(
                        elevation: 2.0,
                        color: Colors.grey[850],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(padding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(Localization.translate('tcp_ip'), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(height: 8),
                              TextField(
                                controller: _ipController,
                                decoration: InputDecoration(
                                  labelText: Localization.translate('device_ip'),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  hintText: Localization.translate('ip_hint'),
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: _portController,
                                decoration: InputDecoration(
                                  labelText: Localization.translate('port'),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  hintText: Localization.translate('port_hint'),
                                ),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    icon: _connecting
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.wifi, size: 16),
                                    label: Text(Localization.translate('connect'), style: const TextStyle(fontSize: 14)),
                                    onPressed: _connecting ? null : _connect,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    icon: _disconnecting
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                                        : const Icon(Icons.link_off, color: Colors.red, size: 16),
                                    label: Text(Localization.translate('disconnect'), style: const TextStyle(fontSize: 14, color: Colors.red)),
                                    onPressed: _disconnecting ? null : _disconnect,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[800],
                                      foregroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                ValueListenableBuilder<bool>(
                  valueListenable: _showScrollHint,
                  builder: (context, show, child) {
                    return AnimatedOpacity(
                      opacity: show ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
                          const SizedBox(width: 4),
                          Text(Localization.translate('swipe_down'), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w300)),
                        ],
                      ),
                    );
                  },
                ),
                FadeIn(
                  duration: const Duration(milliseconds: 300),
                  child: TextButton(
                    child: Text(Localization.translate('close'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OptionItem extends StatelessWidget {
  final String title;
  final String tooltip;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const OptionItem({required this.title, required this.tooltip, required this.value, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        value: value,
        onChanged: onChanged,
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        controlAffinity: ListTileControlAffinity.leading,
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        activeColor: Colors.blueAccent,
        checkColor: Colors.white,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -4),
      ),
    );
  }
}