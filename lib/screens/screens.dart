import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/widgets.dart';
import '../services/services.dart';
import '../models/models.dart';

// ==================== WELCOME SCREEN ====================
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final stats = provider.stats;
    final favCount = provider.favorites.length;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [theme.gradient1, theme.gradient2]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.tv, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('IPTV Editor Pro', style: TextStyle(color: theme.t1, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('v1.0.0 • Flutter', style: TextStyle(color: theme.t3, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButtonCircle(icon: Icons.settings, onPressed: () => Navigator.pushNamed(context, '/settings')),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  StatCard(label: 'Test', value: '${stats.totalTests}', icon: Icons.sync, color: theme.info),
                  const SizedBox(width: 10),
                  StatCard(label: 'OK', value: '${stats.workingLinks}', icon: Icons.check_circle, color: theme.ok),
                  const SizedBox(width: 10),
                  StatCard(label: 'Kanal', value: '${stats.totalChannels}', icon: Icons.tv, color: theme.accent),
                  const SizedBox(width: 10),
                  StatCard(label: 'Dosya', value: '${stats.totalFiles}', icon: Icons.insert_drive_file, color: theme.warn),
                ],
              ),
              const SizedBox(height: 24),
              MenuItemCard(title: 'Manuel Düzenleme', subtitle: 'URL gir, kanalları düzenle', icon: Icons.edit, iconColor: theme.accent, onTap: () => Navigator.pushNamed(context, '/manual-input')),
              MenuItemCard(title: 'Otomatik İşlem', subtitle: 'Akıllı link tespit, toplu test', icon: Icons.auto_fix_high, iconColor: theme.ok, onTap: () => Navigator.pushNamed(context, '/auto-input')),
              MenuItemCard(title: 'Favoriler ($favCount)', subtitle: 'Kayıtlı IPTV linkleri', icon: Icons.star, iconColor: theme.warn, onTap: () => Navigator.pushNamed(context, '/favorites')),
              MenuItemCard(title: 'Ayarlar', subtitle: 'Tema, test ayarları', icon: Icons.settings, iconColor: theme.info, onTap: () => Navigator.pushNamed(context, '/settings')),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MANUAL INPUT ====================
class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});
  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylist() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      setState(() => _error = 'Geçerli URL girin!');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await context.read<AppProvider>().loadPlaylist(url);
      if (mounted) Navigator.pushNamed(context, '/channel-list');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(title: 'Manuel Düzenleme'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GlassCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _urlController,
                                  style: TextStyle(color: theme.t1, fontSize: 13),
                                  decoration: InputDecoration(hintText: 'https://example.com/get.php?...', hintStyle: TextStyle(color: theme.t4)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButtonCircle(
                                icon: Icons.content_paste,
                                backgroundColor: theme.accent,
                                color: Colors.white,
                                onPressed: () async {
                                  final data = await Clipboard.getData('text/plain');
                                  if (data?.text != null) _urlController.text = data!.text!;
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: theme.err.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [Icon(Icons.error, color: theme.err), const SizedBox(width: 8), Expanded(child: Text(_error!, style: TextStyle(color: theme.err, fontSize: 12)))]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(16), child: AccentButton(text: 'Kanalları Yükle', icon: Icons.download, color: theme.ok, isLoading: _isLoading, onPressed: _loadPlaylist)),
          ],
        ),
      ),
    );
  }
}

// ==================== AUTO INPUT ====================
class AutoInputScreen extends StatefulWidget {
  const AutoInputScreen({super.key});
  @override
  State<AutoInputScreen> createState() => _AutoInputScreenState();
}

class _AutoInputScreenState extends State<AutoInputScreen> {
  final _textController = TextEditingController();
  List<String> _foundLinks = [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _extractLinks() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final links = SmartLinkExtractor.extractLinks(text);
    if (links.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link bulunamadı!')));
      return;
    }
    setState(() => _foundLinks = links);
    _showDialog();
  }

  void _showDialog() {
    final theme = context.read<AppProvider>().theme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.card,
        title: Text('${_foundLinks.length} Link Bulundu!', style: TextStyle(color: theme.t1)),
        content: SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: _foundLinks.length > 10 ? 10 : _foundLinks.length,
            itemBuilder: (_, i) => Text('${i + 1}. ${FileService.shortDomain(_foundLinks[i])}', style: TextStyle(color: theme.t2, fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('İptal', style: TextStyle(color: theme.t3))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppProvider>().setLinksForTest(_foundLinks);
              Navigator.pushNamed(context, '/testing', arguments: _foundLinks);
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.ok),
            child: const Text('Test Başlat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppProvider>().theme;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(title: 'Akıllı Link Tespit'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: GlassCard(
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(color: theme.bg2, borderRadius: BorderRadius.circular(12)),
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          expands: true,
                          style: TextStyle(color: theme.t1, fontSize: 12),
                          decoration: InputDecoration(hintText: 'Telegram mesajı veya karışık metin yapıştırın...', hintStyle: TextStyle(color: theme.t4), border: InputBorder.none, contentPadding: const EdgeInsets.all(14)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GhostButton(
                              text: 'Yapıştır',
                              icon: Icons.content_paste,
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data?.text != null) _textController.text = data!.text!;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: GhostButton(text: 'Temizle', icon: Icons.delete_outline, onPressed: () => _textController.clear())),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(16), child: AccentButton(text: 'Linkleri Bul ve Test Et', icon: Icons.rocket_launch, color: theme.ok, onPressed: _extractLinks)),
          ],
        ),
      ),
    );
  }
}

// ==================== CHANNEL LIST ====================
class ChannelListScreen extends StatelessWidget {
  const ChannelListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final groups = provider.groups.values.toList();

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(title: 'Kanal Grupları'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${groups.length} grup | ${provider.channels.length} kanal | Seçilen: ${provider.getSelectedChannelCount()}', style: TextStyle(color: theme.t3, fontSize: 11)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groups.length,
                itemBuilder: (_, i) {
                  final group = groups[i];
                  final country = Countries.all[group.countryId] ?? Countries.all['other']!;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: group.isSelected ? theme.ok.withOpacity(0.15) : theme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: group.isSelected ? Border.all(color: theme.ok, width: 1.5) : null,
                    ),
                    child: ListTile(
                      leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(group.name, style: TextStyle(color: theme.t1, fontSize: 14)),
                      subtitle: Text('${group.count} kanal', style: TextStyle(color: theme.t3, fontSize: 11)),
                      trailing: IconButton(
                        icon: Icon(group.isSelected ? Icons.check_circle : Icons.add_circle_outline, color: group.isSelected ? theme.ok : theme.accent),
                        onPressed: () => provider.toggleGroupSelection(group.name),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: GhostButton(text: 'Tümünü Seç', onPressed: () => provider.selectAllGroups())),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AccentButton(
                      text: 'Dışa Aktar',
                      icon: Icons.upload,
                      color: theme.ok,
                      onPressed: () async {
                        final channels = provider.getSelectedChannels();
                        if (channels.isEmpty) return;
                        final content = M3UParser.generate(channels);
                        final filename = 'playlist_${DateTime.now().millisecondsSinceEpoch}.m3u8';
                        await FileService.savePlaylist(content, filename);
                        await provider.updateStats(channels: channels.length, files: 1);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$filename kaydedildi!')));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TESTING ====================
class TestingScreen extends StatefulWidget {
  const TestingScreen({super.key});
  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  List<String> _links = [];
  bool _testing = true;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is List<String>) { _links = args; _startTesting(); }
    });
  }

  Future<void> _startTesting() async {
    final provider = context.read<AppProvider>();
    for (var i = 0; i < _links.length && _testing; i++) {
      final result = await HttpService.testLink(_links[i], mode: provider.testMode, timeout: provider.timeout);
      if (result.isWorking) provider.addWorkingLink(_links[i]);
      else provider.addFailedLink(result);
      setState(() => _current = i + 1);
    }
    await provider.updateStats(tests: _links.length, working: provider.workingLinks.length);
    setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final progress = _links.isEmpty ? 0.0 : _current / _links.length;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_testing ? Icons.sync : Icons.check_circle, color: theme.accent, size: 48),
              const SizedBox(height: 12),
              Text(_testing ? 'Test Ediliyor' : 'Tamamlandı!', style: TextStyle(color: theme.t1, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              AnimatedProgressBar(progress: progress),
              const SizedBox(height: 12),
              Text('%${(progress * 100).toInt()}', style: TextStyle(color: theme.accent, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: theme.ok, size: 16),
                  Text(' ${provider.workingLinks.length}', style: TextStyle(color: theme.ok)),
                  const SizedBox(width: 16),
                  Icon(Icons.cancel, color: theme.err, size: 16),
                  Text(' ${provider.failedLinks.length}', style: TextStyle(color: theme.err)),
                ],
              ),
              const SizedBox(height: 32),
              AccentButton(
                text: _testing ? 'İptal' : 'Devam',
                icon: _testing ? Icons.close : Icons.arrow_forward,
                color: _testing ? theme.err : theme.ok,
                onPressed: () {
                  if (_testing) { setState(() => _testing = false); Navigator.pop(context); }
                  else if (provider.workingLinks.isEmpty) Navigator.pop(context);
                  else Navigator.pushReplacementNamed(context, '/auto-result');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== AUTO RESULT ====================
class AutoResultScreen extends StatelessWidget {
  const AutoResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.check_circle, color: theme.ok, size: 64),
              const SizedBox(height: 16),
              Text('Test Tamamlandı!', style: TextStyle(color: theme.t1, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              GlassCard(
                child: Row(
                  children: [
                    Expanded(child: Column(children: [Text('${provider.workingLinks.length}', style: TextStyle(color: theme.ok, fontSize: 28, fontWeight: FontWeight.bold)), Text('Çalışıyor', style: TextStyle(color: theme.t3, fontSize: 11))])),
                    Expanded(child: Column(children: [Text('${provider.failedLinks.length}', style: TextStyle(color: theme.err, fontSize: 28, fontWeight: FontWeight.bold)), Text('Başarısız', style: TextStyle(color: theme.t3, fontSize: 11))])),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              MenuItemCard(title: 'Otomatik', subtitle: 'Ülke seç, dosya oluştur', icon: Icons.auto_fix_high, iconColor: theme.accent, onTap: () => Navigator.pushNamed(context, '/country-select')),
              MenuItemCard(title: 'Manuel', subtitle: 'Her linki tek tek düzenle', icon: Icons.edit, iconColor: theme.ok, onTap: () => Navigator.pushNamed(context, '/manual-link-list')),
              const Spacer(),
              GhostButton(text: 'Geri', icon: Icons.arrow_back, onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== COUNTRY SELECT ====================
class CountrySelectScreen extends StatelessWidget {
  const CountrySelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(title: '🌍 Ülke Seçimi'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [...Countries.priorityCountries, ...Countries.otherCountries].map((country) {
                    final isSelected = provider.selectedCountries.contains(country.id);
                    return SelectionChip(label: country.name, prefix: country.flag, isSelected: isSelected, onTap: () => provider.toggleCountry(country.id));
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AccentButton(text: 'Oluştur', icon: Icons.rocket_launch, color: theme.ok, onPressed: provider.selectedCountries.isEmpty ? null : () => Navigator.pushNamed(context, '/processing')),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PROCESSING ====================
class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});
  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  int _current = 0;
  int _filtered = 0;
  final List<ExportedFile> _files = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _process());
  }

  Future<void> _process() async {
    final provider = context.read<AppProvider>();
    final links = provider.workingLinks;
    final countries = provider.selectedCountries;

    for (var i = 0; i < links.length; i++) {
      setState(() => _current = i + 1);
      try {
        final content = await HttpService.fetchContent(links[i], timeout: provider.timeout + 10);
        final result = M3UParser.parse(content, links[i]);
        final filtered = <Channel>[];
        for (final group in result.groups.values) {
          if (countries.contains(group.countryId)) filtered.addAll(group.channels);
        }
        if (filtered.isNotEmpty) {
          final m3uContent = M3UParser.generate(filtered);
          final filename = 'playlist_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.m3u8';
          final path = await FileService.savePlaylist(m3uContent, filename);
          _files.add(ExportedFile(name: filename, channelCount: filtered.length, path: path));
          setState(() => _filtered += filtered.length);
        }
      } catch (_) {}
    }

    await provider.updateStats(channels: _filtered, files: _files.length);
    provider.setExportResults(files: _files, filtered: _filtered, total: provider.workingLinks.length);
    if (mounted) Navigator.pushReplacementNamed(context, '/complete');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final total = provider.workingLinks.length;
    final progress = total > 0 ? _current / total : 0.0;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings, color: theme.accent, size: 48),
              const SizedBox(height: 16),
              Text('İşleniyor...', style: TextStyle(color: theme.t1, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: AnimatedProgressBar(progress: progress)),
              const SizedBox(height: 12),
              Text('%${(progress * 100).toInt()}', style: TextStyle(color: theme.accent, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== COMPLETE ====================
class CompleteScreen extends StatelessWidget {
  const CompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: theme.ok, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 20),
              Text('Tamamlandı!', style: TextStyle(color: theme.t1, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  children: [
                    Text('${provider.totalFiltered} kanal filtrelendi', style: TextStyle(color: theme.ok, fontSize: 16)),
                    Text('${provider.exportedFiles.length} dosya oluşturuldu', style: TextStyle(color: theme.info, fontSize: 13)),
                  ],
                ),
              ),
              const Spacer(),
              AccentButton(
                text: 'Yeni İşlem',
                icon: Icons.refresh,
                onPressed: () {
                  provider.clearTestResults();
                  provider.clearExportResults();
                  provider.clearSelectedCountries();
                  Navigator.pushNamedAndRemoveUntil(context, '/auto-input', (route) => route.isFirst);
                },
              ),
              const SizedBox(height: 12),
              GhostButton(
                text: 'Ana Sayfa',
                icon: Icons.home,
                onPressed: () {
                  provider.clearTestResults();
                  provider.clearExportResults();
                  provider.clearSelectedCountries();
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== FAVORITES ====================
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(title: '⭐ Favoriler'),
            Expanded(
              child: provider.favorites.isEmpty
                  ? const EmptyState(icon: Icons.star_border, title: 'Henüz favori yok')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.favorites.length,
                      itemBuilder: (_, i) {
                        final fav = provider.favorites[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: Icon(Icons.star, color: theme.warn),
                            title: Text(fav.name, style: TextStyle(color: theme.t1)),
                            subtitle: Text('${fav.channelCount} kanal', style: TextStyle(color: theme.t3, fontSize: 11)),
                            trailing: IconButton(icon: Icon(Icons.delete, color: theme.err), onPressed: () => provider.deleteFavorite(fav.url)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SETTINGS ====================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(title: '⚙️ Ayarlar'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎨 Tema', style: TextStyle(color: theme.t1, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Wrap(
                        spacing: 10, runSpacing: 10,
                        children: AppThemes.themes.entries.map((entry) {
                          final isSelected = provider.themeName == entry.key;
                          return GestureDetector(
                            onTap: () => provider.setTheme(entry.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(color: isSelected ? theme.accent : theme.card2, borderRadius: BorderRadius.circular(10)),
                              child: Text(entry.value.name, style: TextStyle(color: isSelected ? Colors.white : theme.t2)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('⚡ Test', style: TextStyle(color: theme.t1, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text('Timeout: ${provider.timeout}s', style: TextStyle(color: theme.t3, fontSize: 11)),
                              Expanded(child: Slider(value: provider.timeout.toDouble(), min: 5, max: 30, divisions: 25, activeColor: theme.accent, onChanged: (v) => provider.setTimeout(v.toInt()))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Column(
                        children: [
                          Text('IPTV Editor Pro v1.0.0', style: TextStyle(color: theme.t1, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('Flutter Edition', style: TextStyle(color: theme.ok, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MANUAL LINK LIST ====================
class ManualLinkListScreen extends StatelessWidget {
  const ManualLinkListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final links = provider.workingLinks;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(title: '✏️ Manuel (${links.length})'),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: links.length,
                itemBuilder: (_, i) {
                  final link = links[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: theme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text('${i + 1}', style: TextStyle(color: theme.accent, fontWeight: FontWeight.bold))),
                      ),
                      title: Text(FileService.shortDomain(link), style: TextStyle(color: theme.t1, fontSize: 14)),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: theme.accent),
                        onPressed: () { provider.setEditingLink(link, i + 1); Navigator.pushNamed(context, '/link-editor'); },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== LINK EDITOR ====================
class LinkEditorScreen extends StatefulWidget {
  const LinkEditorScreen({super.key});
  @override
  State<LinkEditorScreen> createState() => _LinkEditorScreenState();
}

class _LinkEditorScreenState extends State<LinkEditorScreen> {
  bool _loading = true;
  M3UParseResult? _result;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<AppProvider>();
    final link = provider.editingLink;
    if (link == null) return;
    try {
      final content = await HttpService.fetchContent(link, timeout: provider.timeout + 10);
      final result = M3UParser.parse(content, link);
      setState(() { _loading = false; _result = result; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _save() async {
    if (_selected.isEmpty || _result == null) return;
    final provider = context.read<AppProvider>();
    final channels = <Channel>[];
    for (final name in _selected) {
      if (_result!.groups.containsKey(name)) channels.addAll(_result!.groups[name]!.channels);
    }
    final content = M3UParser.generate(channels);
    final filename = 'edited_${DateTime.now().millisecondsSinceEpoch}.m3u8';
    await FileService.savePlaylist(content, filename);
    await provider.updateStats(channels: channels.length, files: 1);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(title: 'Link ${provider.editingIndex}'),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_result == null)
              Expanded(child: Center(child: Text('Hata', style: TextStyle(color: theme.err))))
            else ...[
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _result!.groups.length,
                  itemBuilder: (_, i) {
                    final group = _result!.groups.values.elementAt(i);
                    final isSelected = _selected.contains(group.name);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.ok.withOpacity(0.15) : theme.card,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected ? Border.all(color: theme.ok, width: 1.5) : null,
                      ),
                      child: ListTile(
                        title: Text(group.name, style: TextStyle(color: theme.t1, fontSize: 13)),
                        subtitle: Text('${group.count} kanal', style: TextStyle(color: theme.t3, fontSize: 10)),
                        trailing: Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline, color: isSelected ? theme.ok : theme.accent),
                        onTap: () => setState(() { if (isSelected) _selected.remove(group.name); else _selected.add(group.name); }),
                      ),
                    );
                  },
                ),
              ),
              Padding(padding: const EdgeInsets.all(16), child: AccentButton(text: 'Kaydet', icon: Icons.save, color: theme.ok, onPressed: _save)),
            ],
          ],
        ),
      ),
    );
  }
}
