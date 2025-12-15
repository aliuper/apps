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
              // Header
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.gradient1, theme.gradient2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: theme.gradient1.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.tv, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IPTV Editor Pro',
                          style: TextStyle(
                            color: theme.t1,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'v1.0.0 • Flutter Edition',
                          style: TextStyle(
                            color: theme.t3,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButtonCircle(
                    icon: Icons.settings,
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  StatCard(
                    label: 'Test',
                    value: '${stats.totalTests}',
                    icon: Icons.sync,
                    color: theme.info,
                  ),
                  const SizedBox(width: 10),
                  StatCard(
                    label: 'OK',
                    value: '${stats.workingLinks}',
                    icon: Icons.check_circle,
                    color: theme.ok,
                  ),
                  const SizedBox(width: 10),
                  StatCard(
                    label: 'Kanal',
                    value: '${stats.totalChannels}',
                    icon: Icons.tv,
                    color: theme.accent,
                  ),
                  const SizedBox(width: 10),
                  StatCard(
                    label: 'Dosya',
                    value: '${stats.totalFiles}',
                    icon: Icons.insert_drive_file,
                    color: theme.warn,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info
              Row(
                children: [
                  Icon(Icons.folder, color: theme.info, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Kayıt: Download/IPTV/',
                    style: TextStyle(color: theme.t3, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Menu
              MenuItemCard(
                title: 'Manuel Düzenleme',
                subtitle: 'URL gir, kanalları düzenle',
                icon: Icons.edit,
                iconColor: theme.accent,
                onTap: () => Navigator.pushNamed(context, '/manual-input'),
              ),
              MenuItemCard(
                title: 'Otomatik İşlem',
                subtitle: 'Akıllı link tespit, toplu test',
                icon: Icons.auto_fix_high,
                iconColor: theme.ok,
                onTap: () => Navigator.pushNamed(context, '/auto-input'),
              ),
              MenuItemCard(
                title: 'Favoriler ($favCount)',
                subtitle: 'Kayıtlı IPTV linkleri',
                icon: Icons.star,
                iconColor: theme.warn,
                onTap: () => Navigator.pushNamed(context, '/favorites'),
              ),
              MenuItemCard(
                title: 'Ayarlar',
                subtitle: 'Tema, test ayarları',
                icon: Icons.settings,
                iconColor: theme.info,
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MANUAL INPUT SCREEN ====================
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
    if (url.isEmpty) {
      setState(() => _error = 'URL girin!');
      return;
    }
    if (!url.startsWith('http')) {
      setState(() => _error = 'Geçersiz URL!');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AppProvider>().loadPlaylist(url);
      if (mounted) {
        Navigator.pushNamed(context, '/channel-list');
      }
    } catch (e) {
      setState(() => _error = e.toString().substring(0, 50));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _urlController.text = data!.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.theme;
    final favs = provider.favorites;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(title: 'Manuel Düzenleme'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // URL Input Card
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link, color: theme.t3, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Playlist URL',
                                style: TextStyle(color: theme.t3, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _urlController,
                                  style: TextStyle(color: theme.t1, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'https://example.com/get.php?username=...',
                                    hintStyle: TextStyle(color: theme.t4, fontSize: 12),
                                    filled: true,
                                    fillColor: theme.bg2,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButtonCircle(
                                icon: Icons.content_paste,
                                color: Colors.white,
                                backgroundColor: theme.accent,
                                onPressed: _pasteFromClipboard,
                              ),
                            ],
                          ),
                          if (favs.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _urlController.text = favs.first.url,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.warn.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: theme.warn, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      favs.first.name.length > 22
                                          ? '${favs.first.name.substring(0, 22)}...'
                                          : favs.first.name,
                                      style: TextStyle(
                                        color: theme.warn,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Format Selection
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Çıktı Formatı',
                            style: TextStyle(color: theme.t3, fontSize: 11),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: ['m3u', 'm3u8', 'txt'].map((fmt) {
                              final isSelected = provider.format == fmt;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => provider.setFormat(fmt),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: EdgeInsets.only(
                                      right: fmt != 'txt' ? 10 : 0,
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? theme.accent : theme.card2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        fmt.toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : theme.t2,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Options
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.filter_alt, color: theme.ok, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Duplicate Temizle',
                              style: TextStyle(color: theme.t1, fontSize: 13),
                            ),
                          ),
                          Switch(
                            value: provider.removeDuplicates,
                            onChanged: (v) => provider.setRemoveDuplicates(v),
                            activeColor: theme.ok,
                          ),
                        ],
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.err.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: theme.err, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: theme.err, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Load Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: AccentButton(
                text: 'Kanalları Yükle',
                icon: Icons.download,
                color: theme.ok,
                isLoading: _isLoading,
                onPressed: _loadPlaylist,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== AUTO INPUT SCREEN ====================
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
    if (text.isEmpty) {
      _showSnackBar('Metin girin!', isError: true);
      return;
    }

    final links = SmartLinkExtractor.extractLinks(text);
    
    if (links.isEmpty) {
      _showSnackBar('Link bulunamadı!', isError: true);
      return;
    }

    setState(() => _foundLinks = links);
    _showFoundLinksDialog();
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

  void _showFoundLinksDialog() {
    final theme = context.read<AppProvider>().theme;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: theme.ok, size: 28),
            const SizedBox(width: 10),
            Text(
              '${_foundLinks.length} Link Bulundu!',
              style: TextStyle(color: theme.t1, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: ListView.builder(
            itemCount: _foundLinks.length > 10 ? 11 : _foundLinks.length,
            itemBuilder: (ctx, i) {
              if (i == 10 && _foundLinks.length > 10) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... ve ${_foundLinks.length - 10} link daha',
                    style: TextStyle(color: theme.t4, fontSize: 11),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${i + 1}. ${FileService.shortDomain(_foundLinks[i])}',
                  style: TextStyle(color: theme.t2, fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: theme.t3)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _startTesting();
            },
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text('Test Başlat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.ok,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startTesting() {
    final provider = context.read<AppProvider>();
    provider.setLinksForTest(_foundLinks);
    Navigator.pushNamed(
      context,
      '/testing',
      arguments: _foundLinks,
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _textController.text = data!.text!;
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
            CustomAppBar(
              title: 'Akıllı Link Tespit',
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.psychology, color: theme.accent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'AI',
                        style: TextStyle(
                          color: theme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Info Card
                    GradientCard(
                      padding: const EdgeInsets.all(14),
                      colors: [
                        theme.ok.withOpacity(0.15),
                        theme.ok.withOpacity(0.05),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_fix_high, color: theme.ok, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Karışık metin yapıştırın - linkler otomatik bulunur!',
                                style: TextStyle(color: theme.ok, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Telegram mesajları, emoji içeren metinler desteklenir',
                            style: TextStyle(color: theme.t3, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Text Input
                    GlassCard(
                      child: Column(
                        children: [
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: theme.bg2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _textController,
                              maxLines: null,
                              expands: true,
                              style: TextStyle(color: theme.t1, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Buraya karışık metin, Telegram mesajı veya IPTV linkleri yapıştırın...\n\nÖrnek:\n🎬 𝕄𝟛𝕦 http://server.com:8080/get.php?...',
                                hintStyle: TextStyle(color: theme.t4, fontSize: 11),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GhostButton(
                                  text: 'Yapıştır',
                                  icon: Icons.content_paste,
                                  onPressed: _pasteFromClipboard,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GhostButton(
                                  text: 'Temizle',
                                  icon: Icons.delete_outline,
                                  onPressed: () => _textController.clear(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Test Mode
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Modu',
                            style: TextStyle(color: theme.t3, fontSize: 11),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => provider.setTestMode('quick'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: provider.testMode == 'quick'
                                          ? theme.accent
                                          : theme.card2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.flash_on,
                                          color: provider.testMode == 'quick'
                                              ? Colors.white
                                              : theme.t2,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Hızlı',
                                          style: TextStyle(
                                            color: provider.testMode == 'quick'
                                                ? Colors.white
                                                : theme.t2,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => provider.setTestMode('deep'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: provider.testMode == 'deep'
                                          ? theme.accent
                                          : theme.card2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search,
                                          color: provider.testMode == 'deep'
                                              ? Colors.white
                                              : theme.t2,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Derin',
                                          style: TextStyle(
                                            color: provider.testMode == 'deep'
                                                ? Colors.white
                                                : theme.t2,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Start Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: AccentButton(
                text: 'Linkleri Bul ve Test Et',
                icon: Icons.rocket_launch,
                color: theme.ok,
                onPressed: _extractLinks,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
