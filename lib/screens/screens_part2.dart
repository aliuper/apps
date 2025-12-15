import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/widgets.dart';
import '../services/services.dart';
import '../models/models.dart';

// ==================== CHANNEL LIST SCREEN ====================
class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChannelGroup> get _filteredGroups {
    final groups = context.read<AppProvider>().groups.values.toList();
    if (_searchQuery.isEmpty) return groups;
    return groups
        .where((g) => g.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  int get _selectedCount {
    return context.read<AppProvider>().getSelectedChannelCount();
  }

  int get _selectedGroupCount {
    return context.read<AppProvider>().groups.values.where((g) => g.isSelected).length;
  }

  void _export() async {
    final provider = context.read<AppProvider>();
    final theme = provider.theme;
    final channels = provider.getSelectedChannels();
    
    if (channels.isEmpty) {
      _showSnackBar('Grup seçin!', isError: true);
      return;
    }

    final content = M3UParser.generate(channels);
    final expire = provider.expire ?? '';
    String expStr = '';
    if (expire.isNotEmpty && !expire.contains('EXPIRED')) {
      expStr = expire.replaceAll('.', '');
    } else {
      expStr = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    }

    final filename = 'bitis${expStr}_${FileService.shortDomain(provider.sourceUrl ?? '')}${FileService.getExtension(provider.format)}';

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
                Icon(Icons.check_circle, color: theme.ok, size: 56),
                const SizedBox(height: 12),
                Text(
                  'Kaydedildi!',
                  style: TextStyle(color: theme.t1, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              '${channels.length} kanal\n\nIPTV/$filename',
              style: TextStyle(color: theme.t2, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Tamam'),
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

  void _addToFavorites() async {
    final provider = context.read<AppProvider>();
    final url = provider.sourceUrl;
    if (url != null) {
      await provider.addFavorite(
        url,
        expire: provider.expire,
        channelCount: provider.channels.length,
      );
      _showSnackBar('Favorilere eklendi!');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final theme = context.read<AppProvider>().theme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.err : theme.ok,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final groups = _filteredGroups;
    final expire = provider.expire ?? '';
    final isExpired = expire.contains('EXPIRED');

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Kanal Grupları',
              actions: [
                IconButtonCircle(
                  icon: Icons.star_border,
                  color: theme.warn,
                  onPressed: _addToFavorites,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${provider.groups.length} grup | ${provider.channels.length} kanal',
                        style: TextStyle(color: theme.t3, fontSize: 12),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: isExpired ? theme.err : theme.warn,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bitiş: ${expire.isEmpty ? "Bilinmiyor" : expire}',
                            style: TextStyle(
                              color: isExpired ? theme.err : theme.warn,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seçilen: $_selectedGroupCount grup ($_selectedCount kanal)',
                    style: TextStyle(color: theme.ok, fontSize: 11),
                  ),
                  const SizedBox(height: 12),

                  // Search
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(color: theme.t1, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ara...',
                      hintStyle: TextStyle(color: theme.t4),
                      prefixIcon: Icon(Icons.search, color: theme.t3),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: theme.t3),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.card,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Groups List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: groups.length,
                itemBuilder: (ctx, i) {
                  final group = groups[i];
                  final country = Countries.all[group.countryId] ?? Countries.all['other']!;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: group.isSelected
                          ? theme.ok.withOpacity(0.15)
                          : theme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: group.isSelected
                          ? Border.all(color: theme.ok, width: 1.5)
                          : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Text(
                        country.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        group.name.length > 28
                            ? '${group.name.substring(0, 28)}...'
                            : group.name,
                        style: TextStyle(
                          color: theme.t1,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${group.count} kanal',
                        style: TextStyle(color: theme.t3, fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          group.isSelected
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          color: group.isSelected ? theme.ok : theme.accent,
                        ),
                        onPressed: () {
                          provider.toggleGroupSelection(group.name);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      text: 'Tümünü Seç',
                      onPressed: () => provider.selectAllGroups(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AccentButton(
                      text: 'Dışa Aktar',
                      icon: Icons.upload,
                      color: theme.ok,
                      onPressed: _export,
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

// ==================== TESTING SCREEN ====================
class TestingScreen extends StatefulWidget {
  const TestingScreen({super.key});

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  List<String> _links = [];
  bool _testing = true;
  int _current = 0;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is List<String>) {
        _links = args;
        _startTesting();
      }
    });
  }

  Future<void> _startTesting() async {
    final provider = context.read<AppProvider>();
    
    for (var i = 0; i < _links.length && _testing; i++) {
      final link = _links[i];
      final domain = FileService.shortDomain(link);
      
      _addLog('🔗 $domain', 'testing');
      
      final result = await HttpService.testLink(
        link,
        mode: provider.testMode,
        timeout: provider.timeout,
      );
      
      if (result.isWorking) {
        provider.addWorkingLink(link);
        _addLog('✓ $domain: ${result.message}', 'success');
      } else {
        provider.addFailedLink(result);
        _addLog('✗ $domain: ${result.message}', 'error');
      }
      
      setState(() => _current = i + 1);
      
      // Update stats periodically
      if (i % 5 == 0) {
        await provider.updateStats(
          tests: 5,
          working: provider.workingLinks.length,
        );
      }
    }

    // Final stats update
    await provider.updateStats(
      tests: _links.length,
      working: provider.workingLinks.length,
    );
    
    setState(() => _testing = false);
  }

  void _addLog(String message, String type) {
    setState(() {
      _logs.insert(0, message);
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  void _onAction() {
    if (_testing) {
      setState(() => _testing = false);
      Navigator.pop(context);
    } else {
      final provider = context.read<AppProvider>();
      if (provider.workingLinks.isEmpty) {
        _showNoResultsDialog();
      } else {
        Navigator.pushReplacementNamed(context, '/auto-result');
      }
    }
  }

  void _showNoResultsDialog() {
    final theme = context.read<AppProvider>().theme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.warning_amber, color: theme.warn, size: 48),
            const SizedBox(height: 12),
            Text(
              'Çalışan link yok!',
              style: TextStyle(color: theme.t1, fontSize: 16),
            ),
          ],
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
              child: const Text('Geri'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final progress = _links.isEmpty ? 0.0 : _current / _links.length;
    final working = provider.workingLinks.length;
    final failed = provider.failedLinks.length;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Header
            Icon(
              _testing ? Icons.sync : Icons.check_circle,
              color: theme.accent,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _testing ? 'Test Ediliyor' : 'Tamamlandı!',
              style: TextStyle(
                color: theme.t1,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Progress Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                child: Column(
                  children: [
                    Text(
                      '$_current / ${_links.length}',
                      style: TextStyle(color: theme.t2, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    AnimatedProgressBar(progress: progress),
                    const SizedBox(height: 12),
                    Text(
                      '%${(progress * 100).toInt()}',
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: theme.ok, size: 16),
                        const SizedBox(width: 4),
                        Text('$working', style: TextStyle(color: theme.ok)),
                        const SizedBox(width: 16),
                        Icon(Icons.cancel, color: theme.err, size: 16),
                        const SizedBox(width: 4),
                        Text('$failed', style: TextStyle(color: theme.err)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Logs
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log',
                        style: TextStyle(color: theme.t3, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          reverse: true,
                          itemCount: _logs.length,
                          itemBuilder: (ctx, i) {
                            final log = _logs[i];
                            Color color = theme.t3;
                            if (log.contains('✓')) {
                              color = theme.ok;
                            } else if (log.contains('✗')) {
                              color = theme.err;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                log,
                                style: TextStyle(color: color, fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: AccentButton(
                text: _testing ? 'İptal' : 'Devam',
                icon: _testing ? Icons.close : Icons.arrow_forward,
                color: _testing ? theme.err : theme.ok,
                onPressed: _onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== AUTO RESULT SCREEN ====================
class AutoResultScreen extends StatelessWidget {
  const AutoResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final working = provider.workingLinks.length;
    final failed = provider.failedLinks.length;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.ok.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: theme.ok, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'Test Tamamlandı!',
                style: TextStyle(
                  color: theme.t1,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Results Card
              GlassCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, color: theme.ok, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            '$working',
                            style: TextStyle(
                              color: theme.ok,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Çalışıyor',
                            style: TextStyle(color: theme.t3, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: theme.card2,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.cancel, color: theme.err, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            '$failed',
                            style: TextStyle(
                              color: theme.err,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Başarısız',
                            style: TextStyle(color: theme.t3, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Text(
                '$working link = $working ayrı dosya oluşturulacak',
                style: TextStyle(color: theme.info, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // Options
              MenuItemCard(
                title: 'Otomatik',
                subtitle: 'Ülke seç, $working ayrı dosya',
                icon: Icons.auto_fix_high,
                iconColor: theme.accent,
                onTap: () => Navigator.pushNamed(context, '/country-select'),
              ),
              MenuItemCard(
                title: 'Manuel',
                subtitle: 'Her linki tek tek düzenle',
                icon: Icons.edit,
                iconColor: theme.ok,
                onTap: () => Navigator.pushNamed(context, '/manual-link-list'),
              ),

              const Spacer(),

              GhostButton(
                text: 'Geri',
                icon: Icons.arrow_back,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
