import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:app_manager/utils/config.dart';
import 'package:app_manager/utils/localization.dart';
import 'package:app_manager/overlays/alert.dart';

class LanguageSelectorWidget extends StatefulWidget {
  final Future<void> Function(String) onLanguageSelected;
  final VoidCallback? onLanguageChanged;
  final TextStyle? titleStyle;
  final TextStyle? hintStyle;
  final Color? backgroundColor;
  final Color? searchFieldFillColor;
  final Color? iconColor;
  final double? searchFieldHeight;
  final EdgeInsets? padding;
  final double? listHeight;
  final BorderRadius? borderRadius;

  const LanguageSelectorWidget({
    required this.onLanguageSelected,
    this.onLanguageChanged,
    this.titleStyle,
    this.hintStyle,
    this.backgroundColor,
    this.searchFieldFillColor,
    this.iconColor,
    this.searchFieldHeight,
    this.padding,
    this.listHeight,
    this.borderRadius,
    super.key,
  });

  @override
  _LanguageSelectorWidgetState createState() => _LanguageSelectorWidgetState();
}

class _LanguageSelectorWidgetState extends State<LanguageSelectorWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _allLanguages = [];
  List<Map<String, String>> _filteredLanguages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterLanguages);
    _loadAndFilterLanguages();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLanguages);
    _searchController.dispose();
    super.dispose();
  }

  void _filterLanguages() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = List.from(_allLanguages);
      } else {
        _filteredLanguages = _allLanguages
            .where((lang) => lang['name']!.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _loadAndFilterLanguages() {
    setState(() {
      _isLoading = true;
      try {
        _allLanguages = ConfigUtils.availableLanguages.entries
            .map((entry) => {'code': entry.key, 'name': entry.value})
            .toList();
        _filteredLanguages = List.from(_allLanguages);
      } catch (e) {
        _allLanguages = [];
        _filteredLanguages = [];
        if (mounted) {
          Alert.showWarning(context, Localization.translate('error_loading_languages'));
        }
      }
      _isLoading = false;
    });
    _filterLanguages();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeIn(
            duration: const Duration(milliseconds: 400),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: Localization.translate('search_languages_hint'),
                hintStyle: widget.hintStyle ?? const TextStyle(color: Colors.white70, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: widget.searchFieldFillColor ?? Colors.white.withOpacity(0.1),
                prefixIcon: Icon(Icons.search, color: widget.iconColor ?? Colors.white70),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: widget.titleStyle ?? const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: widget.listHeight ?? 150,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.blueAccent,
                    ),
                  )
                : _filteredLanguages.isEmpty
                    ? Center(
                        child: Text(
                          Localization.translate('no_languages_found'),
                          style: widget.titleStyle?.copyWith(color: Colors.white70) ??
                              const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredLanguages.length,
                        itemBuilder: (context, index) {
                          final lang = _filteredLanguages[index];
                          return FadeInUp(
                            duration: Duration(milliseconds: 300 + (index * 100)),
                            child: ListTile(
                              title: Text(
                                lang['name']!,
                                style: widget.titleStyle?.copyWith(
                                      color: ConfigUtils.currentLanguage == lang['code']
                                          ? Colors.blueAccent
                                          : Colors.white,
                                      fontWeight: ConfigUtils.currentLanguage == lang['code']
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ) ??
                                    TextStyle(
                                      color: ConfigUtils.currentLanguage == lang['code']
                                          ? Colors.blueAccent
                                          : Colors.white,
                                      fontWeight: ConfigUtils.currentLanguage == lang['code']
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                              trailing: ConfigUtils.currentLanguage == lang['code']
                                  ? Icon(Icons.check, color: widget.iconColor ?? Colors.blueAccent, size: 20)
                                  : null,
                              onTap: () async {
                                try {
                                  await widget.onLanguageSelected(lang['code']!);
                                  widget.onLanguageChanged?.call();
                                  if (mounted) setState(() {});
                                } catch (e) {
                                  if (mounted) {
                                    Alert.showWarning(context, Localization.translate('error_selecting_language'));
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}