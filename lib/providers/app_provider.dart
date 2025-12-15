import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../themes/app_themes.dart';

class AppProvider extends ChangeNotifier {
  // Theme
  String _themeName = 'cyberpunk';
  AppTheme get theme => AppThemes.get(_themeName);
  String get themeName => _themeName;

  // Stats
  AppStats _stats = AppStats();
  AppStats get stats => _stats;

  // Favorites
  List<Favorite> _favorites = [];
  List<Favorite> get favorites => _favorites;

  // Settings
  String _testMode = 'deep';
  String _format = 'm3u8';
  bool _removeDuplicates = true;
  int _timeout = 12;

  String get testMode => _testMode;
  String get format => _format;
  bool get removeDuplicates => _removeDuplicates;
  int get timeout => _timeout;

  // Current operation data
  List<Channel> _channels = [];
  Map<String, ChannelGroup> _groups = {};
  String? _expire;
  String? _sourceUrl;

  List<Channel> get channels => _channels;
  Map<String, ChannelGroup> get groups => _groups;
  String? get expire => _expire;
  String? get sourceUrl => _sourceUrl;

  // Test results
  List<String> _workingLinks = [];
  List<LinkTestResult> _failedLinks = [];

  List<String> get workingLinks => _workingLinks;
  List<LinkTestResult> get failedLinks => _failedLinks;

  // Auto process data
  Set<String> _selectedCountries = {};
  List<ExportedFile> _exportedFiles = [];
  int _totalFiltered = 0;
  int _totalChannels = 0;

  Set<String> get selectedCountries => _selectedCountries;
  List<ExportedFile> get exportedFiles => _exportedFiles;
  int get totalFiltered => _totalFiltered;
  int get totalChannels => _totalChannels;

  // Link editor
  String? _editingLink;
  int _editingIndex = 0;

  String? get editingLink => _editingLink;
  int get editingIndex => _editingIndex;

  // Loading states
  bool _isLoading = false;
  String _loadingMessage = '';
  double _loadingProgress = 0;

  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  double get loadingProgress => _loadingProgress;

  // ==================== INITIALIZATION ====================
  Future<void> init() async {
    _themeName = await PreferencesService.getTheme();
    _testMode = await PreferencesService.getTestMode();
    _format = await PreferencesService.getFormat();
    _removeDuplicates = await PreferencesService.getRemoveDuplicates();
    _timeout = await PreferencesService.getTimeout();
    
    await loadStats();
    await loadFavorites();
    
    notifyListeners();
  }

  // ==================== THEME ====================
  Future<void> setTheme(String themeName) async {
    _themeName = themeName;
    await PreferencesService.setTheme(themeName);
    notifyListeners();
  }

  // ==================== SETTINGS ====================
  Future<void> setTestMode(String mode) async {
    _testMode = mode;
    await PreferencesService.setTestMode(mode);
    notifyListeners();
  }

  Future<void> setFormat(String format) async {
    _format = format;
    await PreferencesService.setFormat(format);
    notifyListeners();
  }

  Future<void> setRemoveDuplicates(bool value) async {
    _removeDuplicates = value;
    await PreferencesService.setRemoveDuplicates(value);
    notifyListeners();
  }

  Future<void> setTimeout(int value) async {
    _timeout = value;
    await PreferencesService.setTimeout(value);
    notifyListeners();
  }

  // ==================== STATS ====================
  Future<void> loadStats() async {
    _stats = await DatabaseService.instance.getStats();
    notifyListeners();
  }

  Future<void> updateStats({int tests = 0, int working = 0, int channels = 0, int files = 0}) async {
    await DatabaseService.instance.updateStats(
      tests: tests,
      working: working,
      channels: channels,
      files: files,
    );
    await loadStats();
  }

  // ==================== FAVORITES ====================
  Future<void> loadFavorites() async {
    _favorites = await DatabaseService.instance.getFavorites();
    notifyListeners();
  }

  Future<void> addFavorite(String url, {String? name, String? expire, int channelCount = 0}) async {
    final fav = Favorite(
      url: url,
      name: name ?? FileService.shortDomain(url),
      expire: expire ?? '',
      channelCount: channelCount,
    );
    await DatabaseService.instance.addFavorite(fav);
    await loadFavorites();
  }

  Future<void> deleteFavorite(String url) async {
    await DatabaseService.instance.deleteFavorite(url);
    await loadFavorites();
  }

  // ==================== LOADING STATE ====================
  void setLoading(bool loading, {String message = '', double progress = 0}) {
    _isLoading = loading;
    _loadingMessage = message;
    _loadingProgress = progress;
    notifyListeners();
  }

  void updateProgress(double progress, {String? message}) {
    _loadingProgress = progress;
    if (message != null) _loadingMessage = message;
    notifyListeners();
  }

  // ==================== CHANNEL DATA ====================
  Future<void> loadPlaylist(String url) async {
    setLoading(true, message: 'Bağlanıyor...', progress: 0);
    
    try {
      updateProgress(0.2, message: 'İçerik indiriliyor...');
      final content = await HttpService.fetchContent(url, timeout: _timeout + 10);
      
      updateProgress(0.5, message: 'Ayrıştırılıyor...');
      final result = M3UParser.parse(content, url);
      
      updateProgress(0.8, message: 'İşleniyor...');
      
      var channels = result.channels;
      var groups = result.groups;
      
      if (_removeDuplicates) {
        channels = M3UParser.removeDuplicates(channels);
        // Rebuild groups
        groups = {};
        for (final ch in channels) {
          if (!groups.containsKey(ch.group)) {
            groups[ch.group] = ChannelGroup(
              name: ch.group,
              channels: [],
              logo: ch.logo,
              countryId: Countries.detect(ch.group)?.id ?? 'other',
            );
          }
          groups[ch.group]!.channels.add(ch);
        }
      }
      
      _channels = channels;
      _groups = groups;
      _expire = result.expire;
      _sourceUrl = url;
      
      updateProgress(1.0, message: 'Tamamlandı!');
      setLoading(false);
      notifyListeners();
      
    } catch (e) {
      setLoading(false);
      rethrow;
    }
  }

  void clearPlaylistData() {
    _channels = [];
    _groups = {};
    _expire = null;
    _sourceUrl = null;
    notifyListeners();
  }

  void toggleGroupSelection(String groupName) {
    if (_groups.containsKey(groupName)) {
      _groups[groupName]!.isSelected = !_groups[groupName]!.isSelected;
      notifyListeners();
    }
  }

  void selectAllGroups() {
    for (final group in _groups.values) {
      group.isSelected = true;
    }
    notifyListeners();
  }

  List<Channel> getSelectedChannels() {
    final selected = <Channel>[];
    for (final group in _groups.values) {
      if (group.isSelected) {
        selected.addAll(group.channels);
      }
    }
    return selected;
  }

  int getSelectedChannelCount() {
    int count = 0;
    for (final group in _groups.values) {
      if (group.isSelected) {
        count += group.channels.length;
      }
    }
    return count;
  }

  // ==================== LINK TESTING ====================
  void setLinksForTest(List<String> links) {
    _workingLinks = [];
    _failedLinks = [];
    notifyListeners();
  }

  void addWorkingLink(String url) {
    _workingLinks.add(url);
    notifyListeners();
  }

  void addFailedLink(LinkTestResult result) {
    _failedLinks.add(result);
    notifyListeners();
  }

  void clearTestResults() {
    _workingLinks = [];
    _failedLinks = [];
    notifyListeners();
  }

  // ==================== COUNTRY SELECTION ====================
  void toggleCountry(String countryId) {
    if (_selectedCountries.contains(countryId)) {
      _selectedCountries.remove(countryId);
    } else {
      _selectedCountries.add(countryId);
    }
    notifyListeners();
  }

  void clearSelectedCountries() {
    _selectedCountries.clear();
    notifyListeners();
  }

  // ==================== EXPORT ====================
  void setExportResults({
    required List<ExportedFile> files,
    required int filtered,
    required int total,
  }) {
    _exportedFiles = files;
    _totalFiltered = filtered;
    _totalChannels = total;
    notifyListeners();
  }

  void clearExportResults() {
    _exportedFiles = [];
    _totalFiltered = 0;
    _totalChannels = 0;
    notifyListeners();
  }

  // ==================== LINK EDITOR ====================
  void setEditingLink(String url, int index) {
    _editingLink = url;
    _editingIndex = index;
    notifyListeners();
  }

  // ==================== CACHE ====================
  void clearCache() {
    HttpService.clearCache();
    notifyListeners();
  }
}
