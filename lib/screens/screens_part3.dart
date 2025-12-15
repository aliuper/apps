import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/widgets.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../theme/app_themes.dart'; // EKLENDİ: Bu satır eksikti

// ==================== COUNTRY SELECT SCREEN ====================
class CountrySelectScreen extends StatelessWidget {
  const CountrySelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final workingCount = provider.workingLinks.length;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(title: '🌍 Ülke Seçimi'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    '$workingCount link = $workingCount ayrı dosya',
                    style: TextStyle(color: theme.info, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seçilen: ${provider.selectedCountries.length} ülke',
                    style: TextStyle(color: theme.ok, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Countries Grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Öncelikli',
                      style: TextStyle(
                        color: theme.t3,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: Countries.priorityCountries.map((country) {
                        final isSelected = provider.selectedCountries.contains(country.id);
                        return SelectionChip(
                          label: country.name,
                          prefix: country.flag,
                          isSelected: isSelected,
                          selectedColor: theme.warn,
                          onTap: () => provider.toggleCountry(country.id),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Diğer Ülkeler',
                      style: TextStyle(
                        color: theme.t3,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: Countries.otherCountries.map((country) {
                        final isSelected = provider.selectedCountries.contains(country.id);
                        return SelectionChip(
                          label: country.name,
                          prefix: country.flag,
                          isSelected: isSelected,
                          onTap: () => provider.toggleCountry(country.id),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Format & Process
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(
                          'Format:',
                          style: TextStyle(color: theme.t3, fontSize: 11),
                        ),
                        const SizedBox(width: 12),
                        ...['m3u', 'm3u8', 'txt'].map((fmt) {
                          final isSelected = provider.format == fmt;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => provider.setFormat(fmt),
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: fmt != 'txt' ? 8 : 0,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.accent : theme.card2,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    fmt.toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : theme.t2,
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AccentButton(
                    text: 'Oluştur',
                    icon: Icons.rocket_launch,
                    color: theme.ok,
                    onPressed: provider.selectedCountries.isEmpty
                        ? null
                        : () => Navigator.pushNamed(context, '/processing'),
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

// ==================== PROCESSING SCREEN ====================
class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _processing = true;
  int _current = 0;
  int _totalChannels = 0;
  int _filteredChannels = 0;
  String _currentDomain = '';
  final List<ExportedFile> _files = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startProcessing());
  }

  Future<void> _startProcessing() async {
    final provider = context.read<AppProvider>();
    final links = provider.workingLinks;
    final countries = provider.selectedCountries;
    final format = provider.format;

    for (var i = 0; i < links.length && _processing; i++) {
      final link = links[i];
      final domain = FileService.shortDomain(link);
      
      setState(() {
        _current = i + 1;
        _currentDomain = domain;
      });

      try {
        final content = await HttpService.fetchContent(link, timeout: provider.timeout + 10);
        final result = M3UParser.parse(content, link);
        
        setState(() => _totalChannels += result.channels.length);

        // Filter by country
        final filtered = <Channel>[];
        for (final group in result.groups.values) {
          if (countries.contains(group.countryId)) {
            filtered.addAll(group.channels);
          }
        }

        setState(() => _filteredChannels += filtered.length);

        if (filtered.isNotEmpty) {
          final m3uContent = M3UParser.generate(filtered);
          final expire = result.expire ?? '';
          String expStr = '';
          if (expire.isNotEmpty && !expire.contains('EXPIRED')) {
            expStr = expire.replaceAll('.', '');
          } else {
            expStr = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
          }

          final filename = 'bitis${expStr}_$domain${FileService.getExtension(format)}';
          final path = await FileService.savePlaylist(m3uContent, filename);
          
          _files.add(ExportedFile(
            name: filename,
            channelCount: filtered.length,
            expire: result.expire,
            path: path,
          ));
        }
      } catch (_) {}
    }

    // Update stats
    await provider.updateStats(
      channels: _filteredChannels,
      files: _files.length,
    );

    provider.setExportResults(
      files: _files,
      filtered: _filteredChannels,
      total: _totalChannels,
    );

    setState(() => _processing = false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/complete');
    }
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings, color: theme.accent, size: 48),
              const SizedBox(height: 16),
              Text(
                'İşleniyor...',
                style: TextStyle(
                  color: theme.t1,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentDomain,
                style: TextStyle(color: theme.t3, fontSize: 12),
              ),
              const SizedBox(height: 32),

              AnimatedProgressBar(progress: progress),
              const SizedBox(height: 12),
              Text(
                '%${(progress * 100).toInt()}',
                style: TextStyle(
                  color: theme.accent,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Stats
              GlassCard(
                child: Column(
                  children: [
                    _buildStatRow(
                      Icons.link,
                      'İşlenen',
                      '$_current / $total',
                      theme.t2,
                      theme,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      Icons.tv,
                      'Toplam',
                      '$_totalChannels kanal',
                      theme.t2,
                      theme,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      Icons.check_circle,
                      'Filtrelenen',
                      '$_filteredChannels kanal',
                      theme.ok,
                      theme,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      Icons.insert_drive_file,
                      'Dosyalar',
                      '${_files.length}',
                      theme.info,
                      theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color, theme) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: theme.t3, fontSize: 12)),
        const Spacer(),
        Text(value, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

// ==================== COMPLETE SCREEN ====================
class CompleteScreen extends StatelessWidget {
  const CompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final files = provider.exportedFiles;
    final filtered = provider.totalFiltered;
    final total = provider.totalChannels;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.ok, theme.ok.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.ok.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 20),
              Text(
                'Tamamlandı!',
                style: TextStyle(
                  color: theme.t1,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Results
              GlassCard(
                child: Column(
                  children: [
                    Text(
                      '$filtered kanal filtrelendi',
                      style: TextStyle(color: theme.ok, fontSize: 16),
                    ),
                    Text(
                      'Toplam $total kanaldan',
                      style: TextStyle(color: theme.t3, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${files.length} dosya oluşturuldu',
                      style: TextStyle(color: theme.info, fontSize: 13),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder, color: theme.t4, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Download/IPTV/',
                          style: TextStyle(color: theme.t4, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Files List
              if (files.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dosyalar:',
                    style: TextStyle(color: theme.t3, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: files.length > 5 ? 6 : files.length,
                    itemBuilder: (ctx, i) {
                      if (i == 5 && files.length > 5) {
                        return Text(
                          '... ve ${files.length - 5} dosya daha',
                          style: TextStyle(color: theme.t4, fontSize: 10),
                        );
                      }
                      final file = files[i];
                      String expInfo = '';
                      if (file.expire != null && !file.expire!.contains('EXPIRED')) {
                        expInfo = ' (${file.expire})';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file, color: theme.t3, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${file.name} - ${file.channelCount} ch$expInfo',
                                style: TextStyle(color: theme.t2, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const Spacer(),

              // Buttons
              AccentButton(
                text: 'Yeni İşlem',
                icon: Icons.refresh,
                onPressed: () {
                  provider.clearTestResults();
                  provider.clearExportResults();
                  provider.clearSelectedCountries();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/auto-input',
                    (route) => route.isFirst,
                  );
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
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== FAVORITES SCREEN ====================
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final favorites = provider.favorites;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(title: '⭐ Favoriler'),
            Expanded(
              child: favorites.isEmpty
                  ? EmptyState(
                      icon: Icons.star_border,
                      title: 'Henüz favori yok',
                      subtitle: 'Manuel düzenlemede yıldız ile ekleyin',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favorites.length,
                      itemBuilder: (ctx, i) {
                        final fav = favorites[i];
                        String subtitle = '${fav.channelCount} kanal';
                        if (fav.expire.isNotEmpty && !fav.expire.contains('EXPIRED')) {
                          subtitle += ' | ${fav.expire}';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: theme.card,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Icon(Icons.star, color: theme.warn, size: 28),
                            title: Text(
                              fav.name.length > 22
                                  ? '${fav.name.substring(0, 22)}...'
                                  : fav.name,
                              style: TextStyle(
                                color: theme.t1,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              subtitle,
                              style: TextStyle(color: theme.t3, fontSize: 11),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.play_arrow, color: theme.ok),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/manual-input',
                                      arguments: fav.url,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: theme.err),
                                  onPressed: () => provider.deleteFavorite(fav.url),
                                ),
                              ],
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

// ==================== SETTINGS SCREEN ====================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final stats = provider.stats;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(title: '⚙️ Ayarlar'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme Section
                    _buildSectionTitle('🎨 Tema', theme),
                    GlassCard(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: AppThemes.themes.entries.map((entry) {
                          final isSelected = provider.themeName == entry.key;
                          return GestureDetector(
                            onTap: () => provider.setTheme(entry.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? theme.accent : theme.card2,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                entry.value.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : theme.t2,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Test Section
                    _buildSectionTitle('⚡ Test', theme),
                    GlassCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Mod:',
                                style: TextStyle(color: theme.t3, fontSize: 11),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => provider.setTestMode('quick'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: provider.testMode == 'quick'
                                          ? theme.accent
                                          : theme.card2,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Hızlı',
                                        style: TextStyle(
                                          color: provider.testMode == 'quick'
                                              ? Colors.white
                                              : theme.t2,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => provider.setTestMode('deep'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: provider.testMode == 'deep'
                                          ? theme.accent
                                          : theme.card2,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Derin',
                                        style: TextStyle(
                                          color: provider.testMode == 'deep'
                                              ? Colors.white
                                              : theme.t2,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Timeout:',
                                style: TextStyle(color: theme.t3, fontSize: 11),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${provider.timeout}s',
                                style: TextStyle(
                                  color: theme.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: provider.timeout.toDouble(),
                                  min: 5,
                                  max: 30,
                                  divisions: 25,
                                  activeColor: theme.accent,
                                  onChanged: (v) => provider.setTimeout(v.toInt()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // File Section
                    _buildSectionTitle('📁 Dosya', theme),
                    GlassCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Format:',
                                style: TextStyle(color: theme.t3, fontSize: 11),
                              ),
                              const SizedBox(width: 12),
                              ...['m3u', 'm3u8', 'txt'].map((fmt) {
                                final isSelected = provider.format == fmt;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => provider.setFormat(fmt),
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        right: fmt != 'txt' ? 8 : 0,
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? theme.accent : theme.card2,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          fmt.toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : theme.t2,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Duplicate Temizle:',
                                style: TextStyle(color: theme.t3, fontSize: 11),
                              ),
                              const Spacer(),
                              Switch(
                                value: provider.removeDuplicates,
                                onChanged: (v) => provider.setRemoveDuplicates(v),
                                activeColor: theme.ok,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.folder, color: theme.info, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Kayıt: Download/IPTV/',
                                style: TextStyle(color: theme.info, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Data Section
                    _buildSectionTitle('🗑️ Veri', theme),
                    GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: AccentButton(
                              text: 'Önbellek Temizle',
                              icon: Icons.cleaning_services,
                              color: theme.info,
                              height: 44,
                              onPressed: () {
                                provider.clearCache();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Önbellek temizlendi!'),
                                    backgroundColor: theme.ok,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // About Section
                    _buildSectionTitle('ℹ️ Hakkında', theme),
                    GlassCard(
                      child: Column(
                        children: [
                          Text(
                            'IPTV Editor Pro v1.0.0',
                            style: TextStyle(
                              color: theme.t1,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Flutter Edition',
                            style: TextStyle(color: theme.ok, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toplam: ${stats.totalTests} test, ${stats.totalFiles} dosya',
                            style: TextStyle(color: theme.t3, fontSize: 10),
                          ),
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

  Widget _buildSectionTitle(String title, theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: theme.t1,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ==================== MANUAL LINK LIST SCREEN ====================
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
                itemBuilder: (ctx, i) {
                  final link = links[i];
                  final domain = FileService.shortDomain(link);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: theme.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        domain,
                        style: TextStyle(
                          color: theme.t1,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        link.length > 36
                            ? '${link.substring(0, 36)}...'
                            : link,
                        style: TextStyle(color: theme.t4, fontSize: 9),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: theme.accent),
                        onPressed: () {
                          provider.setEditingLink(link, i + 1);
                          Navigator.pushNamed(context, '/link-editor');
                        },
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

// ==================== LINK EDITOR SCREEN ====================
class LinkEditorScreen extends StatefulWidget {
  const LinkEditorScreen({super.key});

  @override
  State<LinkEditorScreen> createState() => _LinkEditorScreenState();
}

class _LinkEditorScreenState extends State<LinkEditorScreen> {
  bool _loading = true;
  String? _error;
  M3UParseResult? _result;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylist());
  }

  Future<void> _loadPlaylist() async {
    final provider = context.read<AppProvider>();
    final link = provider.editingLink;
    
    if (link == null) {
      setState(() {
        _loading = false;
        _error = 'Link bulunamadı';
      });
      return;
    }

    try {
      final content = await HttpService.fetchContent(link, timeout: provider.timeout + 10);
      final result = M3UParser.parse(content, link);
      setState(() {
        _loading = false;
        _result = result;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().substring(0, 30);
      });
    }
  }

  void _save() async {
    if (_selected.isEmpty) {
      _showSnackBar('Grup seçin!', isError: true);
      return;
    }

    final provider = context.read<AppProvider>();
    final theme = provider.theme;
    final link = provider.editingLink!;
    
    final channels = <Channel>[];
    for (final groupName in _selected) {
      if (_result!.groups.containsKey(groupName)) {
        channels.addAll(_result!.groups[groupName]!.channels);
      }
    }

    final content = M3UParser.generate(channels);
    final expire = _result?.expire ?? '';
    String expStr = '';
    if (expire.isNotEmpty && !expire.contains('EXPIRED')) {
      expStr = expire.replaceAll('.', '');
    } else {
      expStr = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    }

    final filename = 'bitis${expStr}_${FileService.shortDomain(link)}.m3u8';

    try {
      await FileService.savePlaylist(content, filename);
      await provider.updateStats(channels: channels.length, files: 1);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: theme.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                Icon(Icons.check_circle, color: theme.ok, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Kaydedildi!',
                  style: TextStyle(color: theme.t1, fontSize: 16),
                ),
              ],
            ),
            content: Text(
              '${channels.length} kanal\nIPTV/$filename',
              style: TextStyle(color: theme.t2, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Listeye Dön'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Hata: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final theme = context.read<AppProvider>().theme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.err : theme.ok,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final index = provider.editingIndex;
    final total = provider.workingLinks.length;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(title: 'Link $index/$total'),
            if (_loading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: theme.accent),
                      const SizedBox(height: 16),
                      Text(
                        'Yükleniyor...',
                        style: TextStyle(color: theme.t3),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    'Hata: $_error',
                    style: TextStyle(color: theme.err),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (_result?.expire != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _result!.expire!.contains('EXPIRED')
                                ? theme.err
                                : theme.warn,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bitiş: ${_result!.expire}',
                            style: TextStyle(
                              color: _result!.expire!.contains('EXPIRED')
                                  ? theme.err
                                  : theme.warn,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${_result!.groups.length} grup | ${_result!.channels.length} kanal',
                      style: TextStyle(color: theme.t3, fontSize: 11),
                    ),
                    Text(
                      'Seçilen: ${_selected.length} grup',
                      style: TextStyle(color: theme.ok, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _result!.groups.length,
                  itemBuilder: (ctx, i) {
                    final group = _result!.groups.values.elementAt(i);
                    final country = Countries.all[group.countryId] ?? Countries.all['other']!;
                    final isSelected = _selected.contains(group.name);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.ok.withOpacity(0.15)
                            : theme.card,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? Border.all(color: theme.ok, width: 1.5)
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          group.name.length > 26
                              ? '${group.name.substring(0, 26)}...'
                              : group.name,
                          style: TextStyle(
                            color: theme.t1,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${group.count} kanal',
                          style: TextStyle(color: theme.t3, fontSize: 10),
                        ),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          color: isSelected ? theme.ok : theme.accent,
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selected.remove(group.name);
                            } else {
                              _selected.add(group.name);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: AccentButton(
                  text: 'Kaydet',
                  icon: Icons.save,
                  color: theme.ok,
                  onPressed: _save,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
