import 'dart:io';
import 'dart:async';
import 'package:app_manager/services/manager.dart';
import 'package:app_manager/utils/file_manager.dart';
import 'package:app_manager/utils/config.dart';
import 'package:app_manager/utils/url.dart';
import 'package:app_manager/services/adb.dart';
import 'package:app_manager/overlays/alert.dart';
import 'package:app_manager/overlays/config.dart';
import 'package:app_manager/overlays/repo.dart';
import 'package:app_manager/overlays/tips.dart';
import 'package:app_manager/overlays/intro.dart';
import 'package:app_manager/utils/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

const defaultIconPath = 'assets/images/default_app_icon.png';
late final String appSupportDir;
late final String iconsDirPath;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigUtils.load();
  await Localization.loadLanguages();
  await Localization.loadLocale(ConfigUtils.currentLanguage ?? 'en');
  appSupportDir = (await getApplicationSupportDirectory()).path;
  iconsDirPath = '$appSupportDir${Platform.pathSeparator}icons${Platform.pathSeparator}'.replaceAll('\\', '/');
  runApp(const MyApp());
  doWhenWindowReady(() {
    const initialSize = Size(900, 650);
    appWindow
      ..minSize = initialSize
      ..size = initialSize
      ..alignment = Alignment.center
      ..title = 'App Manager [1.2.5]'
      ..show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Manager',
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.grey[900],
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.grey[850],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white70, size: 20),
      ),
      initialRoute: ConfigUtils.isFirstLaunch ? '/setup' : '/home',
      routes: {
        '/setup': (context) => IntroductionOverlay(
              onContinue: () {
                Navigator.pushReplacementNamed(context, '/home');
                ConfigUtils.isFirstLaunch = false;
                ConfigUtils.save();
              },
            ),
        '/home': (context) => ValueListenableBuilder<String>(
              valueListenable: Localization.languageNotifier,
              builder: (context, languageCode, child) {
                return const AppManagerPage();
              },
            ),
      },
    );
  }
}

class AnimatedApplyButton extends StatelessWidget {
  final GlobalKey<HintMessageState> hintKey;
  const AnimatedApplyButton({required this.hintKey, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Localization.languageNotifier,
      builder: (context, languageCode, child) {
        return HintMessage(
          key: hintKey,
          hintKey: 'apply_button_tip',
          message: Localization.translate('apply_button_tip'),
          dismissButtonText: Localization.translate('skip'),
          hintWidth: 350.0,
          child: FadeIn(
            duration: const Duration(milliseconds: 300),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 300, maxWidth: 300, minHeight: 40),
              child: ElevatedButton(
                onPressed: () {
                  final state = context.findAncestorStateOfType<_AppManagerPageState>();
                  state?._applyChanges();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  Localization.translate('apply_button'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimatedDonateButton extends StatefulWidget {
  const AnimatedDonateButton({super.key});

  @override
  _AnimatedDonateButtonState createState() => _AnimatedDonateButtonState();
}

class _TippableCheckbox extends StatelessWidget {
  final Map<String, dynamic> app;
  final VoidCallback? onChanged;
  final int index;
  final GlobalKey<HintMessageState>? hintKey;

  const _TippableCheckbox({
    required this.app,
    this.onChanged,
    required this.index,
    this.hintKey,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Localization.languageNotifier,
      builder: (context, languageCode, child) {
        return index == 0
            ? HintMessage(
                key: hintKey,
                hintKey: 'checkbox_tip',
                message: Localization.translate('checkbox_tip'),
                dismissButtonText: Localization.translate('skip'),
                hintWidth: 300.0,
                child: Checkbox(
                  value: app['isChecked'],
                  onChanged: (value) {
                    app['isChecked'] = value;
                    if (onChanged != null) onChanged!();
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  activeColor: Colors.blueAccent,
                  checkColor: Colors.white,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
              )
            : Checkbox(
                value: app['isChecked'],
                onChanged: (value) {
                  app['isChecked'] = value;
                  if (onChanged != null) onChanged!();
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                activeColor: Colors.blueAccent,
                checkColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.padded,
              );
      },
    );
  }
}

class _AnimatedDonateButtonState extends State<AnimatedDonateButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shine;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reset();
          _timer = Timer(const Duration(seconds: 8), () {
            if (mounted) _controller.forward();
          });
        }
      });
    _shine = Tween<double>(begin: -1.5, end: 1.5).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Localization.languageNotifier,
      builder: (context, languageCode, child) {
        return FadeIn(
          duration: const Duration(milliseconds: 300),
          child: AnimatedBuilder(
            animation: _shine,
            builder: (context, child) => Tooltip(
              message: Localization.translate('support_tooltip'),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => UrlUtils.launchUrlOrShow(context, 'https://buymeacoffee.com/blassgo'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      gradient: LinearGradient(
                        begin: Alignment(_shine.value - 1, 0),
                        end: Alignment(_shine.value + 1, 0),
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            Localization.translate('support'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final bool isLoadingApps;
  final bool loadIcons;
  final bool iconsReady;
  final bool isFilteredDataEmpty;

  const LoadingIndicator({
    super.key,
    required this.isLoadingApps,
    required this.loadIcons,
    required this.iconsReady,
    required this.isFilteredDataEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Localization.languageNotifier,
      builder: (context, languageCode, child) {
        if (isLoadingApps || (loadIcons && !iconsReady)) {
          return FadeIn(
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.blueAccent,
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
          );
        } else if (isFilteredDataEmpty) {
          return FadeIn(
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                Localization.translate('no_matches'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class AppManagerPage extends StatefulWidget {
  const AppManagerPage({super.key});

  @override
  _AppManagerPageState createState() => _AppManagerPageState();
}

class _AppManagerPageState extends State<AppManagerPage> {
  final _searchController = TextEditingController();
  String? _stateFilter = 'all';
  String? _systemFilter = 'all';
  String? _checkFilter = 'all';
  double _panelWidth = 300;
  bool _isPanelVisible = true;
  bool _loadIcons = false;
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _iconsReadyNotifier = ValueNotifier(false);
  Timer? _debounceTimer;
  final Map<String, Image> _iconCache = {};
  final GlobalKey<HintMessageState> _applyHintKey = GlobalKey<HintMessageState>();
  final GlobalKey<HintMessageState> _firstCheckboxHintKey = GlobalKey<HintMessageState>();

  final List<Map<String, String>> stateItems = [
    {'value': 'all', 'text': 'all_apps'},
    {'value': '1', 'text': 'enabled'},
    {'value': '0', 'text': 'disabled'},
    {'value': '-1', 'text': 'uninstalled'},
  ];

  final List<Map<String, String>> systemItems = [
    {'value': 'all', 'text': 'system_user'},
    {'value': '1', 'text': 'system'},
    {'value': '0', 'text': 'user'},
  ];

  final List<Map<String, String>> checkItems = [
    {'value': 'all', 'text': 'any'},
    {'value': '1', 'text': 'checked'},
    {'value': '0', 'text': 'unchecked'},
    {'value': 'applicable', 'text': 'applicable'},
  ];

  List<Map<String, dynamic>> get _filteredData => ManagerService.apps.values.where((item) {
        final matchesSearch = (item['name']?.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
            (item['package']?.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
        final matchesState = _stateFilter == 'all' || (item['state']?.toString() == _stateFilter);
        final matchesSystem = _systemFilter == 'all' || (item['isSystem'] == (_systemFilter == '1'));
        final state = item['state'] as int?;
        final isChecked = item['isChecked'] as bool?;
        final action = item['action'] as String?;
        final matchesCheck = _checkFilter == 'all' ? true :
            _checkFilter == '1' ? (item['isChecked'] == true) :
            _checkFilter == '0' ? (item['isChecked'] == false) :
            (state != null && isChecked != null) &&
                (action == 'install-disable' ||
                    (state > 0 && isChecked == false) ||
                    (state == 0 && isChecked == true) ||
                    (state < 0 && isChecked == true));
        return matchesSearch && matchesState && matchesSystem && matchesCheck;
      }).toList();

  void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(Localization.translate('copied_to_clipboard'), overflow: TextOverflow.ellipsis),
      ),
    );
  }

  void _triggerApplyHint() {
    _applyHintKey.currentState?.showHint();
  }

  void _onLanguageChanged() {
    setState(() {
      _stateFilter = _translateFilter(_stateFilter, stateItems);
      _systemFilter = _translateFilter(_systemFilter, systemItems);
      _checkFilter = _translateFilter(_checkFilter, checkItems);
    });
  }

  String _translateFilter(String? currentValue, List<Map<String, String>> items) {
    if (currentValue == null) return items[0]['value']!;
    for (var item in items) {
      if (item['value'] == currentValue) return currentValue;
    }
    return items[0]['value']!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAppsFromDevice();   
    });
    _searchController.addListener(() => setState(() {}));
    Localization.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _isLoadingNotifier.dispose();
    _iconsReadyNotifier.dispose();
    _searchController.dispose();
    _iconCache.clear();
    Localization.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          title: FadeIn(
            duration: const Duration(milliseconds: 300),
            child: Text(
              'App Manager',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            color: Colors.grey[850]!.withOpacity(0.8),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: FadeInRight(
                duration: const Duration(milliseconds: 350),
                child: const AnimatedDonateButton(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ValueListenableBuilder<String>(
                valueListenable: Localization.languageNotifier,
                builder: (context, languageCode, child) {
                  return FadeInRight(
                    duration: const Duration(milliseconds: 300),
                    child: Tooltip(
                      message: Localization.translate('view_source'),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => UrlUtils.launchUrlOrShow(context, 'https://github.com/BlassGO/AppManager-GUI'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Text(
                              '@BlassGO',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 160),
                      child: Column(
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: _isLoadingNotifier,
                            builder: (context, isLoading, child) => LoadingIndicator(
                              isLoadingApps: isLoading,
                              loadIcons: _loadIcons,
                              iconsReady: _iconsReadyNotifier.value,
                              isFilteredDataEmpty: _filteredData.isEmpty,
                            ),
                          ),
                          Expanded(
                            child: (_loadIcons && _iconsReadyNotifier.value)
                                ? _buildIconGrid(constraints.maxWidth)
                                : _buildAppList(),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
  top: 8,
  left: 12,
  right: 12,
  child: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey[850]!.withOpacity(0.8),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          spreadRadius: 2,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeIn(
          duration: const Duration(milliseconds: 300),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: Localization.translate('search_hint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<String>(
          valueListenable: Localization.languageNotifier,
          builder: (context, languageCode, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: _buildIOSToggleButton(
                      label: Localization.translate('state_label'),
                      value: _stateFilter,
                      items: stateItems,
                      onChanged: (value) => setState(() => _stateFilter = value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: _buildIOSToggleButton(
                      label: Localization.translate('system_label'),
                      value: _systemFilter,
                      items: systemItems,
                      onChanged: (value) => setState(() => _systemFilter = value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: _buildIOSToggleButton(
                      label: Localization.translate('check_label'),
                      value: _checkFilter,
                      items: checkItems,
                      onChanged: (value) => setState(() => _checkFilter = value),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth * 0.8;
            return FadeIn(
              duration: const Duration(milliseconds: 300),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: availableWidth, minHeight: 36),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                for (var app in _filteredData) {
                                  app['isChecked'] = true;
                                }
                                ManagerService.updateActionCounters();
                                _triggerApplyHint();
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withOpacity(0.6),
                              backgroundColor: Colors.blueGrey[900],
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                              ),
                            ),
                            child: Text(
                              Localization.translate('check_all'),
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        Expanded(
                          flex: 1,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                for (var app in _filteredData) {
                                  app['isChecked'] = false;
                                }
                                ManagerService.updateActionCounters();
                                _triggerApplyHint();
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withOpacity(0.6),
                              backgroundColor: Colors.blueGrey[900],
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Text(
                              Localization.translate('uncheck_all'),
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        Expanded(
                          flex: 1,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                for (var app in _filteredData) {
                                  app['isChecked'] = app['state'] == 1;
                                }
                                ManagerService.updateActionCounters();
                                _triggerApplyHint();
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withOpacity(0.6),
                              backgroundColor: Colors.blueGrey[900],
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                            ),
                            child: Text(
                              Localization.translate('restore_all'),
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  ),
)
                  ],
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => setState(() {
                    _panelWidth -= details.delta.dx;
                    _panelWidth = _panelWidth.clamp(250, constraints.maxWidth * 0.5);
                    _isPanelVisible = _panelWidth > 50;
                  }),
                  child: Container(
                    width: 4,
                    color: Colors.grey[800]!.withOpacity(0.8),
                    child: Center(
                      child: Container(
                        width: 2,
                        height: 40,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isPanelVisible ? _panelWidth : 0,
                constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.5),
                decoration: BoxDecoration(
                  color: Colors.grey[850]!.withOpacity(0.9),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: _isPanelVisible
                    ? SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: ValueListenableBuilder<String>(
                                valueListenable: Localization.languageNotifier,
                                builder: (context, languageCode, child) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[900],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              alignment: WrapAlignment.center,
                                              children: [
                                                _buildActionButton(
                                                  label: Localization.translate('reload'),
                                                  icon: Icons.refresh,
                                                  tooltip: Localization.translate('reload_tooltip'),
                                                  onPressed: _loadAppsFromDevice,
                                                  delay: 300,
                                                ),
                                                _buildActionButton(
                                                  label: Localization.translate('device'),
                                                  icon: Icons.usb,
                                                  tooltip: Localization.translate('device_tooltip'),
                                                  onPressed: () async {
                                                    if (await AdbService.selectDevice(context, showSelector: true, loadAppsCallback: _loadAppsFromDevice)) {
                                                      setState(() {
                                                        _loadIcons = false;
                                                        _iconsReadyNotifier.value = false;
                                                      });
                                                    }
                                                  },
                                                  delay: 350,
                                                ),
                                                _buildActionButton(
                                                  label: Localization.translate('log'),
                                                  icon: Icons.article,
                                                  tooltip: Localization.translate('log_tooltip'),
                                                  onPressed: () => AdbService.lastLog != null ? Alert.showLog(context, AdbService.lastLog!) : null,
                                                  delay: 400,
                                                ),
                                                _buildActionButton(
                                                  label: Localization.translate('browse'),
                                                  icon: Icons.add_circle,
                                                  tooltip: Localization.translate('browse_tooltip'),
                                                  onPressed: () => showDialog(
                                                    context: context,
                                                    builder: (_) => ReposOverlay(refreshUI: () => setState(() {})),
                                                  ),
                                                  delay: 450,
                                                ),
                                                _buildActionButton(
                                                  label: Localization.translate('settings'),
                                                  icon: Icons.settings,
                                                  tooltip: Localization.translate('settings_tooltip'),
                                                  onPressed: () => showDialog(
                                                    context: context,
                                                    builder: (_) => ConfigOverlay(
                                                      onConnect: _loadAppsFromDevice,
                                                      refreshUI: () => setState(() {}),
                                                    ),
                                                  ),
                                                  delay: 500,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                                              ),
                                              child: FadeIn(
                                                duration: const Duration(milliseconds: 550),
                                                child: Tooltip(
                                                  message: Localization.translate('icon_view_tooltip'),
                                                  child: SwitchListTile(
                                                    title: Text(Localization.translate('icon_view'), style: const TextStyle(fontSize: 13, color: Colors.white70), overflow: TextOverflow.ellipsis),
                                                    value: _loadIcons,
                                                    onChanged: (newValue) async {
                                                      _iconsReadyNotifier.value = ManagerService.iconsLoaded;
                                                      if (newValue && !ManagerService.iconsLoaded && !await _loadAppIcons()) return;
                                                      setState(() => _loadIcons = newValue);
                                                    },
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                                    activeTrackColor: Colors.blueAccent.withOpacity(0.5),
                                                    inactiveTrackColor: Colors.grey[700],
                                                    inactiveThumbColor: Colors.white70,
                                                    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                FadeIn(
                                                  duration: const Duration(milliseconds: 600),
                                                  child: Tooltip(
                                                    message: Localization.translate('import_tooltip'),
                                                    child: ConstrainedBox(
                                                      constraints: const BoxConstraints(minWidth: 80, maxWidth: 100),
                                                      child: ElevatedButton(
                                                        onPressed: _importAppActions,
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.grey[800],
                                                          foregroundColor: Colors.white,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                        ),
                                                        child: Text(Localization.translate('import'), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                FadeIn(
                                                  duration: const Duration(milliseconds: 650),
                                                  child: Tooltip(
                                                    message: Localization.translate('export_tooltip'),
                                                    child: ConstrainedBox(
                                                      constraints: const BoxConstraints(minWidth: 80, maxWidth: 100),
                                                      child: ElevatedButton(
                                                        onPressed: _exportAppActions,
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.grey[800],
                                                          foregroundColor: Colors.white,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                        ),
                                                        child: Text(Localization.translate('export'), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      FadeIn(
                                        duration: const Duration(milliseconds: 300),
                                        child: Center(child: AnimatedApplyButton(hintKey: _applyHintKey)),
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: FadeIn(
                                          duration: const Duration(milliseconds: 500),
                                          child: DataTable(
                                            dataRowHeight: 32,
                                            headingRowHeight: 36,
                                            columns: [
                                              DataColumn(label: Text(Localization.translate('action'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                              DataColumn(label: Text(Localization.translate('count'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                            ],
                                            rows: [
                                              DataRow(cells: [
                                                DataCell(Text(Localization.translate('activate'), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                                DataCell(Text(ManagerService.activateCount.toString(), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                              ]),
                                              DataRow(cells: [
                                                DataCell(Text(Localization.translate('install'), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                                DataCell(Text(ManagerService.installCount.toString(), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                              ]),
                                              DataRow(cells: [
                                                DataCell(Text(Localization.translate('uninstall'), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                                DataCell(Text(ManagerService.uninstallCount.toString(), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                              ]),
                                              DataRow(cells: [
                                                DataCell(Text(Localization.translate('deactivate'), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                                DataCell(Text(ManagerService.deactivateCount.toString(), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                              ]),
                                              DataRow(cells: [
                                                DataCell(Text(Localization.translate('total'), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                                DataCell(Text(
                                                  (ManagerService.activateCount + ManagerService.installCount + ManagerService.uninstallCount + ManagerService.deactivateCount).toString(),
                                                  style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                )),
                                              ]),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required int delay,
  }) =>
      FadeIn(
        duration: Duration(milliseconds: delay),
        child: Tooltip(
          message: tooltip,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onPressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[900]!.withOpacity(0.8),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: Colors.white70),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildAppList() => ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _filteredData.length,
        itemBuilder: (context, index) {
          final app = _filteredData[index];
          final isExpanded = app['isExpanded'] ?? false;

          return FadeIn(
            duration: const Duration(milliseconds: 150),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: _TippableCheckbox(
                      app: app,
                      onChanged: () {
                        setState(() {
                          ManagerService.updateActionCounters();
                          _triggerApplyHint();
                        });
                      },
                      index: index,
                      hintKey: index == 0 ? _firstCheckboxHintKey : null,
                    ),
                    title: Text(
                      app['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      app['package'],
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: TextButton.icon(
                      onPressed: () => setState(() => app['isExpanded'] = !isExpanded),
                      icon: Icon(
                        isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      label: Text(
                        isExpanded ? Localization.translate('hide') : Localization.translate('info'),
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  if (isExpanded)
                    FadeIn(
                      duration: const Duration(milliseconds: 150),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(100),
                                1: FlexColumnWidth(),
                                2: FixedColumnWidth(70),
                              },
                              children: [
                                _buildInfoRow(Localization.translate('name'), app['name']),
                                _buildInfoRow(Localization.translate('id'), app['id']),
                                _buildInfoRow(Localization.translate('package'), app['package']),
                                _buildInfoRow(Localization.translate('type'), app['isSystem'] ? Localization.translate('system') : Localization.translate('user')),
                                _buildInfoRow(Localization.translate('path'), app['path']),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );

  Widget _buildIconGrid(double availableWidth) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filteredData.length,
      itemBuilder: (context, index) {
        final app = _filteredData[index];
        final label = app['name'].length > 18 ? '${app['name'].substring(0, 16)}…' : app['name'];
        final iconPath = app['iconPath'] as String;

        if (!_iconCache.containsKey(iconPath)) {
          _iconCache[iconPath] = Image.file(
            File(iconPath),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            cacheWidth: 112,
          );
        }

        return FadeIn(
          duration: const Duration(milliseconds: 100),
          child: Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    value: app['isChecked'],
                    onChanged: (value) => setState(() {
                      app['isChecked'] = value;
                      ManagerService.updateActionCounters();
                      _triggerApplyHint();
                    }),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    activeColor: Colors.blue,
                    checkColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(height: 4),
                  MouseRegion(
                    onEnter: (_) => setState(() => app['isHovering'] = true),
                    onExit: (_) => setState(() => app['isHovering'] = false),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _iconCache[iconPath],
                        ),
                        AnimatedOpacity(
                          opacity: app['isHovering'] == true ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 56,
                              height: 56,
                              color: const Color.fromRGBO(0, 0, 0, 0.45),
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
                                  tooltip: Localization.translate('export_icon'),
                                  onPressed: () async => await FileManager.exportAppIcon(context, app['package'], app['iconPath']),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIOSToggleButton({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) =>
      FadeIn(
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850]!.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    ...items.map(
                      (item) => ListTile(
                        title: Text(
                          Localization.translate(item['text']!),
                          style: TextStyle(
                            color: item['value'] == value ? Colors.blueAccent : Colors.white,
                            fontWeight: item['value'] == value ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: item['value'] == value
                            ? const Icon(Icons.check, color: Colors.blueAccent, size: 20)
                            : null,
                        onTap: () {
                          onChanged(item['value']);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    Localization.translate(items.firstWhere((item) => item['value'] == value, orElse: () => {'text': label})['text']!),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      );

  TableRow _buildInfoRow(String key, String value) => TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                value,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
                softWrap: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: ElevatedButton(
              onPressed: () => _copyToClipboard(value),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(60, 28),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.grey[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(Localization.translate('copy'), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      );

  Future<void> _loadAppsFromDevice() async {
    _isLoadingNotifier.value = true;
    _iconsReadyNotifier.value = false;
    _iconCache.clear();
    await ManagerService.loadAppsFromDevice(context, refreshUI: () {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _firstCheckboxHintKey.currentState?.showHint();
      });
    });
    if (_loadIcons) await _loadAppIcons();
    _isLoadingNotifier.value = false;
    setState(() {});
  }

  Future<bool> _loadAppIcons() async {
    final success = await ManagerService.loadAppIcons(context, iconsDirPath, defaultIconPath);
    if (success) {
      for (var app in ManagerService.apps.values) {
        final iconPath = app['iconPath'] as String;
        if (!_iconCache.containsKey(iconPath)) {
          _iconCache[iconPath] = Image.file(
            File(iconPath),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            cacheWidth: 112,
          );
        }
      }
    }
    _iconsReadyNotifier.value = success;
    _isLoadingNotifier.value = false;
    return success;
  }

  Future<void> _importAppActions() async {
    await FileManager.importAppActions(context);
    setState(() {});
  }

  Future<void> _exportAppActions() async => await FileManager.exportAppActions(context);

  Future<void> _applyChanges() async {
    await ManagerService.applyChanges(context);
    setState(() {});
  }
}