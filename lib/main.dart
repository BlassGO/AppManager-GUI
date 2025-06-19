import 'dart:io';
import 'dart:async';
import 'package:app_manager/services/manager.dart';
import 'package:app_manager/utils/file_manager.dart';
import 'package:app_manager/utils/config.dart';
import 'package:app_manager/utils/url.dart';
import 'package:app_manager/services/adb.dart';
import 'package:app_manager/overlays/alert.dart';
import 'package:app_manager/overlays/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

const defaultIconPath = 'assets/images/default_app_icon.png';
late final String appSupportDir;
late final String iconsDirPath;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigUtils.load();
  appSupportDir = (await getApplicationSupportDirectory()).path;
  iconsDirPath = '$appSupportDir${Platform.pathSeparator}icons${Platform.pathSeparator}'.replaceAll('\\', '/');
  runApp(const MyApp());
  doWhenWindowReady(() {
    const initialSize = Size(700, 550);
    appWindow
      ..minSize = initialSize
      ..size = initialSize
      ..alignment = Alignment.center
      ..title = 'App Manager [1.1.0]'
      ..show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'App Manager',
        theme: ThemeData.dark().copyWith(textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme)),
        home: const AppManagerPage(),
      );
}

class AnimatedApplyButton extends StatefulWidget {
  const AnimatedApplyButton({super.key});

  @override
  _AnimatedApplyButtonState createState() => _AnimatedApplyButtonState();
}

class _AnimatedApplyButtonState extends State<AnimatedApplyButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(Colors.cyan, Colors.blue, _controller.value)!,
                Color.lerp(Colors.blue, Colors.deepPurpleAccent, _controller.value)!,
                Color.lerp(Colors.green, Colors.cyan, _controller.value)!,
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
          child: Tooltip(
            message: 'Apply changes made',
            child: TextButton(
              onPressed: () => context.findAncestorStateOfType<_AppManagerPageState>()?._applyChanges(),
              child: const Text('APPLY', style: TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
            ),
          ),
        ),
      );
}

class AnimatedDonateButton extends StatefulWidget {
  const AnimatedDonateButton({super.key});

  @override
  _AnimatedDonateButtonState createState() => _AnimatedDonateButtonState();
}

class _AnimatedDonateButtonState extends State<AnimatedDonateButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shine;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reset();
          _timer = Timer(const Duration(seconds: 10), () {
            if (mounted) _controller.forward();
          });
        }
      });
    _shine = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _shine,
        builder: (context, child) => Tooltip(
          message: 'Buy me a coffee ☕',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => UrlUtils.launchUrlOrShow(context, 'https://paypal.me/blassgohuh?country.x=EC&locale.x=es_XC'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color.fromRGBO(107, 107, 107, 0.7), width: 2),
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment(_shine.value - 1, 0),
                    end: Alignment(_shine.value + 1, 0),
                    colors: [
                      Colors.transparent,
                      const Color.fromRGBO(255, 255, 255, 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_money, color: Color(0xFFE0E0E0), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Support',
                      style: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 12,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class LoadingIndicator extends StatelessWidget {
  final bool isLoadingApps;
  final bool loadIcons;
  final bool iconsReady;

  const LoadingIndicator({
    super.key,
    required this.isLoadingApps,
    required this.loadIcons,
    required this.iconsReady,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingApps || (loadIcons && !iconsReady)) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
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
  double _panelHeight = 220;
  bool _isPanelVisible = true;
  bool _loadIcons = false;
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _iconsReadyNotifier = ValueNotifier(false);
  Timer? _debounceTimer;

  final List<Map<String, String>> stateItems = [
    {'value': 'all', 'text': 'All apps'},
    {'value': '1', 'text': 'Enabled'},
    {'value': '0', 'text': 'Disabled'},
    {'value': '-1', 'text': 'Uninstalled'},
  ];

  final List<Map<String, String>> systemItems = [
    {'value': 'all', 'text': 'System-User'},
    {'value': '1', 'text': 'System'},
    {'value': '0', 'text': 'User'},
  ];

  List<Map<String, dynamic>> get _filteredData => ManagerService.apps.values
      .where((item) =>
          (item['name'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
              item['package'].toLowerCase().contains(_searchController.text.toLowerCase())) &&
          (_stateFilter == 'all' || item['state'].toString() == _stateFilter) &&
          (_systemFilter == 'all' || item['isSystem'] == (_systemFilter == '1')))
      .toList();

  void _togglePanel() => setState(() {
        _isPanelVisible = !_isPanelVisible;
        _panelHeight = _isPanelVisible ? 220 : 0;
      });

  void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await _loadAppsFromDevice());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _isLoadingNotifier.dispose();
    _iconsReadyNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('App Manager'),
          actions: [
            IconButton(tooltip: 'Reload app list from device', icon: const Icon(Icons.refresh), onPressed: _loadAppsFromDevice),
            IconButton(
              tooltip: 'Device selector',
              icon: const Icon(Icons.usb),
              onPressed: () async {
                if (await AdbService.selectDevice(context, showSelector: true, loadAppsCallback: _loadAppsFromDevice)) {
                  setState(() {
                    _loadIcons = false;
                    _iconsReadyNotifier.value = false;
                  });
                }
              },
            ),
            IconButton(
              tooltip: 'View last log',
              icon: const Icon(Icons.article),
              onPressed: () => AdbService.lastLog != null ? Alert.showLog(context, AdbService.lastLog!) : null,
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings),
              onPressed: () => showDialog(context: context, builder: (_) => ConfigOverlay(
                onConnect: _loadAppsFromDevice,
                refreshUI: () => setState(() {})
              )),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: AnimatedDonateButton(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: 'View source code',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => UrlUtils.launchUrlOrShow(context, 'https://github.com/BlassGO/AppManager-GUI'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(33, 149, 243, 0.684),
                        border: Border.all(color: Color.fromARGB(255, 52, 87, 138), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'By @BlassGO',
                        style: TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 12,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by name or package...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownButton(
                    label: 'State',
                    value: _stateFilter,
                    items: stateItems,
                    onChanged: (value) => setState(() => _stateFilter = value),
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownButton(
                    label: 'System',
                    value: _systemFilter,
                    items: systemItems,
                    onChanged: (value) => setState(() => _systemFilter = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 0,
                    bottom: _panelHeight + 20,
                    child: Column(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _isLoadingNotifier,
                          builder: (context, isLoading, child) => LoadingIndicator(
                            isLoadingApps: isLoading,
                            loadIcons: _loadIcons,
                            iconsReady: _iconsReadyNotifier.value,
                          ),
                        ),
                        Expanded(
                          child: (_loadIcons && _iconsReadyNotifier.value) ? _buildIconGrid() : _buildAppList(),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: _panelHeight,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) => setState(() {
                        _panelHeight -= details.delta.dy;
                        _panelHeight = _panelHeight.clamp(0, MediaQuery.of(context).size.height / 2);
                      }),
                      onTap: _togglePanel,
                      child: Container(
                        height: 20,
                        color: Colors.grey[800],
                        child: Center(
                          child: Icon(_isPanelVisible ? Icons.arrow_drop_down : Icons.arrow_drop_up, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _panelHeight,
                      color: Colors.grey[850],
                      child: _isPanelVisible
                          ? Row(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    const Expanded(child: Center(child: AnimatedApplyButton())),
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          LayoutBuilder(
                                                            builder: (context, constraints) => Wrap(
                                                              direction: Axis.horizontal,
                                                              spacing: 12,
                                                              runSpacing: 8,
                                                              alignment: WrapAlignment.center,
                                                              children: [
                                                                Tooltip(
                                                                  message: 'Import actions',
                                                                  child: ConstrainedBox(
                                                                    constraints: const BoxConstraints(minWidth: 150, maxWidth: 160),
                                                                    child: ElevatedButton(onPressed: _importAppActions, child: const Text('IMPORT')),
                                                                  ),
                                                                ),
                                                                Tooltip(
                                                                  message: 'Export current actions',
                                                                  child: ConstrainedBox(
                                                                    constraints: const BoxConstraints(minWidth: 150, maxWidth: 160),
                                                                    child: ElevatedButton(onPressed: _exportAppActions, child: const Text('EXPORT')),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(height: 10),
                                                          Tooltip(
                                                            message: 'Switch between icon mode',
                                                            child: SwitchListTile(
                                                              title: const Text('App Icons', style: TextStyle(fontSize: 13)),
                                                              value: _loadIcons,
                                                              onChanged: (newValue) async {
                                                                _iconsReadyNotifier.value = ManagerService.iconsLoaded;
                                                                if (newValue && !ManagerService.iconsLoaded && !await _loadAppIcons()) return;
                                                                setState(() => _loadIcons = newValue);
                                                              },
                                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                                              activeTrackColor: Colors.grey[300],
                                                              inactiveThumbColor: Colors.grey[400],
                                                              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              Expanded(
                                                child: DataTable(
                                                  dataRowHeight: 36,
                                                  headingRowHeight: 40,
                                                  columns: const [
                                                    DataColumn(label: Text('Action')),
                                                    DataColumn(label: Text('Count')),
                                                  ],
                                                  rows: [
                                                    DataRow(cells: [const DataCell(Text('Activate')), DataCell(Text(ManagerService.activateCount.toString()))]),
                                                    DataRow(cells: [const DataCell(Text('Install')), DataCell(Text(ManagerService.installCount.toString()))]),
                                                    DataRow(cells: [const DataCell(Text('Uninstall')), DataCell(Text(ManagerService.uninstallCount.toString()))]),
                                                    DataRow(cells: [const DataCell(Text('Deactivate')), DataCell(Text(ManagerService.deactivateCount.toString()))]),
                                                    DataRow(cells: [
                                                      const DataCell(Text('Total', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold))),
                                                      DataCell(Text(
                                                        (ManagerService.activateCount + ManagerService.installCount + ManagerService.uninstallCount + ManagerService.deactivateCount).toString(),
                                                        style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
                                                      )),
                                                    ]),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildAppList() => ListView.builder(
        itemCount: _filteredData.length,
        itemBuilder: (context, index) {
          final app = _filteredData[index];
          final isExpanded = app['isExpanded'];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(4),
                    child: Checkbox(
                      value: app['isChecked'],
                      onChanged: (value) => setState(() {
                        app['isChecked'] = value;
                        ManagerService.updateActionCounters();
                      }),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      activeColor: Colors.blue,
                      checkColor: Colors.white,
                    ),
                  ),
                  title: Text(app['name']),
                  subtitle: Text(app['package']),
                  trailing: TextButton.icon(
                    onPressed: () => setState(() => app['isExpanded'] = !isExpanded),
                    icon: Icon(isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                    label: Text(isExpanded ? 'Hide info' : 'Show info'),
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Table(
                          columnWidths: const {
                            0: FixedColumnWidth(120),
                            1: FlexColumnWidth(),
                            2: FixedColumnWidth(60),
                          },
                          children: [
                            _buildInfoRow('Name', app['name']),
                            _buildInfoRow('ID', app['id']),
                            _buildInfoRow('Package', app['package']),
                            _buildInfoRow('Type', app['isSystem'] ? 'System' : 'User'),
                            _buildInfoRow('Path', app['path']),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );

  Widget _buildIconGrid() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = (width / 120).floor().clamp(3, 12);

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 120 / 170,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filteredData.length,
      itemBuilder: (context, index) {
        final app = _filteredData[index];
        final label = app['name'].length > 18 ? '${app['name'].substring(0, 16)}…' : app['name'];

        return Card(
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
                        child: Image.file(File(app['iconPath']), width: 56, height: 56, fit: BoxFit.cover),
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
                                tooltip: 'Export icon',
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
                Text(label, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownButton({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) =>
      PopupMenuButton<String>(
        onSelected: onChanged,
        itemBuilder: (context) => items.map((item) => PopupMenuItem<String>(value: item['value'], child: Text(item['text']!))).toList(),
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(25)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(items.firstWhere((item) => item['value'] == value, orElse: () => {'text': label})['text']!, style: const TextStyle(color: Colors.white)),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
      );

  TableRow _buildInfoRow(String key, String value) => TableRow(
        children: [
          Padding(padding: const EdgeInsets.all(8), child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: const EdgeInsets.all(8), child: Text(value)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: () => _copyToClipboard(value),
              style: ElevatedButton.styleFrom(minimumSize: const Size(50, 30), padding: EdgeInsets.zero, backgroundColor: Colors.grey[800]),
              child: const Text('Copy', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );

  Future<void> _loadAppsFromDevice() async {
    _isLoadingNotifier.value = true;
    _iconsReadyNotifier.value = false;
    await ManagerService.loadAppsFromDevice(context, refreshUI: () => setState(() {}));
    if (_loadIcons) await _loadAppIcons();
    _isLoadingNotifier.value = false;
    setState(() {});
  }

  Future<bool> _loadAppIcons() async {
    final success = await ManagerService.loadAppIcons(context, iconsDirPath, defaultIconPath);
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