import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

// ==================== DATABASE SERVICE ====================
class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('iptv_editor.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        expire TEXT,
        channel_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT UNIQUE NOT NULL,
        tests INTEGER DEFAULT 0,
        working INTEGER DEFAULT 0,
        channels INTEGER DEFAULT 0,
        files INTEGER DEFAULT 0
      )
    ''');
  }

  // Favorites
  Future<List<Favorite>> getFavorites() async {
    final db = await database;
    final result = await db.query('favorites', orderBy: 'id DESC');
    return result.map((map) => Favorite.fromMap(map)).toList();
  }

  Future<int> addFavorite(Favorite fav) async {
    final db = await database;
    return await db.insert('favorites', fav.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteFavorite(String url) async {
    final db = await database;
    return await db.delete('favorites', where: 'url = ?', whereArgs: [url]);
  }

  // Stats
  Future<AppStats> getStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(tests), 0) as total_tests,
        COALESCE(SUM(working), 0) as working_links,
        COALESCE(SUM(channels), 0) as total_channels,
        COALESCE(SUM(files), 0) as total_files
      FROM stats
    ''');
    if (result.isNotEmpty) {
      return AppStats.fromMap(result.first);
    }
    return AppStats();
  }

  Future<void> updateStats({int tests = 0, int working = 0, int channels = 0, int files = 0}) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final existing = await db.query('stats', where: 'date = ?', whereArgs: [today]);
    
    if (existing.isNotEmpty) {
      await db.rawUpdate('''
        UPDATE stats SET 
          tests = tests + ?,
          working = working + ?,
          channels = channels + ?,
          files = files + ?
        WHERE date = ?
      ''', [tests, working, channels, files, today]);
    } else {
      await db.insert('stats', {
        'date': today,
        'tests': tests,
        'working': working,
        'channels': channels,
        'files': files,
      });
    }
  }
}

// ==================== PREFERENCES SERVICE ====================
class PreferencesService {
  static SharedPreferences? _prefs;
  
  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<String> getTheme() async => (await prefs).getString('theme') ?? 'cyberpunk';
  static Future<void> setTheme(String value) async => (await prefs).setString('theme', value);

  static Future<String> getTestMode() async => (await prefs).getString('test_mode') ?? 'deep';
  static Future<void> setTestMode(String value) async => (await prefs).setString('test_mode', value);

  static Future<String> getFormat() async => (await prefs).getString('format') ?? 'm3u8';
  static Future<void> setFormat(String value) async => (await prefs).setString('format', value);

  static Future<bool> getRemoveDuplicates() async => (await prefs).getBool('remove_duplicates') ?? true;
  static Future<void> setRemoveDuplicates(bool value) async => (await prefs).setBool('remove_duplicates', value);

  static Future<int> getTimeout() async => (await prefs).getInt('timeout') ?? 12;
  static Future<void> setTimeout(int value) async => (await prefs).setInt('timeout', value);
}

// ==================== HTTP SERVICE ====================
class HttpService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20',
      'Accept': '*/*',
      'Connection': 'keep-alive',
    },
  ));

  static final Map<String, LinkTestResult> _cache = {};

  static Future<String> fetchContent(String url, {int? timeout}) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          receiveTimeout: Duration(seconds: timeout ?? 30),
        ),
      );
      return response.data.toString();
    } catch (e) {
      throw Exception('Bağlantı hatası: ${e.toString().substring(0, 50)}');
    }
  }

  static Future<LinkTestResult> testLink(String url, {String mode = 'deep', int timeout = 12}) async {
    // Check cache
    final cacheKey = url.hashCode.toString();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      if (mode == 'quick') {
        final response = await _dio.head(
          url,
          options: Options(
            receiveTimeout: Duration(seconds: timeout),
            followRedirects: true,
          ),
        );
        final result = LinkTestResult(
          url: url,
          isWorking: response.statusCode == 200,
          message: 'HTTP ${response.statusCode}',
        );
        _cache[cacheKey] = result;
        return result;
      }

      // Deep test
      final response = await _dio.get(
        url,
        options: Options(
          receiveTimeout: Duration(seconds: timeout),
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode != 200) {
        return LinkTestResult(
          url: url,
          isWorking: false,
          message: 'HTTP ${response.statusCode}',
        );
      }

      final content = response.data.toString();
      
      if (content.length < 50) {
        return LinkTestResult(
          url: url,
          isWorking: false,
          message: 'Boş içerik',
        );
      }

      if (content.contains('#EXTINF')) {
        final parseResult = M3UParser.parse(content, url);
        final channelCount = parseResult.channels.length;
        final result = LinkTestResult(
          url: url,
          isWorking: channelCount > 0,
          message: channelCount > 0 ? '$channelCount kanal' : 'Kanal yok',
          expire: parseResult.expire,
          channelCount: channelCount,
        );
        _cache[cacheKey] = result;
        return result;
      }

      final result = LinkTestResult(
        url: url,
        isWorking: content.length > 3000,
        message: content.length > 3000 ? 'Stream OK' : 'Geçersiz',
      );
      _cache[cacheKey] = result;
      return result;

    } on DioException catch (e) {
      String message;
      if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        message = 'Timeout';
      } else {
        message = 'Bağlantı hatası';
      }
      return LinkTestResult(url: url, isWorking: false, message: message);
    } catch (e) {
      return LinkTestResult(url: url, isWorking: false, message: 'Hata');
    }
  }

  static void clearCache() => _cache.clear();
}

// ==================== M3U PARSER ====================
class M3UParseResult {
  final List<Channel> channels;
  final Map<String, ChannelGroup> groups;
  final String? expire;

  M3UParseResult({
    required this.channels,
    required this.groups,
    this.expire,
  });
}

class M3UParser {
  static final RegExp _groupRe = RegExp(r'group-title="([^"]*)"');
  static final RegExp _logoRe = RegExp(r'tvg-logo="([^"]*)"');
  static final RegExp _nameRe = RegExp(r',([^,]+)$');

  static M3UParseResult parse(String content, [String url = '']) {
    final channels = <Channel>[];
    final groups = <String, ChannelGroup>{};
    String? expire = _extractExpire(content, url);

    Channel? current;
    
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      
      if (trimmed.startsWith('#EXTINF:')) {
        String name = '';
        String group = 'Diğer';
        String logo = '';

        final groupMatch = _groupRe.firstMatch(trimmed);
        if (groupMatch != null && groupMatch.group(1)!.isNotEmpty) {
          group = groupMatch.group(1)!.trim();
        }

        final logoMatch = _logoRe.firstMatch(trimmed);
        if (logoMatch != null) {
          logo = logoMatch.group(1)!;
        }

        final nameMatch = _nameRe.firstMatch(trimmed);
        if (nameMatch != null) {
          name = nameMatch.group(1)!.trim();
        }

        current = Channel(name: name, group: group, logo: logo, url: '');
      } else if (current != null && 
          (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('rtmp://'))) {
        final channel = Channel(
          name: current.name,
          group: current.group,
          logo: current.logo,
          url: trimmed,
        );
        channels.add(channel);

        if (!groups.containsKey(channel.group)) {
          groups[channel.group] = ChannelGroup(
            name: channel.group,
            channels: [],
            logo: channel.logo,
            countryId: Countries.detect(channel.group)?.id ?? 'other',
          );
        }
        groups[channel.group]!.channels.add(channel);
        current = null;
      }
    }

    return M3UParseResult(channels: channels, groups: groups, expire: expire);
  }

  static String? _extractExpire(String content, String url) {
    // Try URL params
    final uri = Uri.tryParse(url);
    if (uri != null) {
      for (final key in ['exp', 'expires', 'expire', 'e']) {
        if (uri.queryParameters.containsKey(key)) {
          try {
            var ts = int.parse(uri.queryParameters[key]!);
            if (ts > 1e12) ts ~/= 1000;
            if (ts > 1704067200 && ts < 1893456000) {
              final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
              final now = DateTime.now();
              if (dt.isBefore(now)) {
                return '${_formatDate(dt)} [EXPIRED]';
              }
              return _formatDate(dt);
            }
          } catch (_) {}
        }
      }
    }

    // Try content patterns
    final patterns = [
      RegExp(r'[?&]exp[ire]*[s]?=(\d{10,13})'),
      RegExp(r'"exp[ire]*":\s*(\d{10,13})'),
    ];

    final searchContent = content.length > 5000 ? content.substring(0, 5000) : content;
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(searchContent);
      for (final match in matches) {
        try {
          var ts = int.parse(match.group(1)!);
          if (ts > 1e12) ts ~/= 1000;
          if (ts > 1704067200 && ts < 1893456000) {
            final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
            final now = DateTime.now();
            if (dt.isBefore(now)) {
              return '${_formatDate(dt)} [EXPIRED]';
            }
            return _formatDate(dt);
          }
        } catch (_) {}
      }
    }

    return null;
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  static String generate(List<Channel> channels) {
    final buffer = StringBuffer('#EXTM3U\n');
    for (final ch in channels) {
      buffer.write('#EXTINF:-1');
      if (ch.logo.isNotEmpty) buffer.write(' tvg-logo="${ch.logo}"');
      if (ch.group.isNotEmpty) buffer.write(' group-title="${ch.group}"');
      buffer.writeln(',${ch.name}');
      buffer.writeln(ch.url);
    }
    return buffer.toString();
  }

  static List<Channel> removeDuplicates(List<Channel> channels) {
    final seen = <String>{};
    return channels.where((ch) {
      if (seen.contains(ch.url)) return false;
      seen.add(ch.url);
      return true;
    }).toList();
  }
}

// ==================== SMART LINK EXTRACTOR ====================
class SmartLinkExtractor {
  static final List<RegExp> _urlPatterns = [
    // Standard m3u links
    RegExp(r'(https?://[^\s<>"\']+?/get\.php\?[^\s<>"\']+)', caseSensitive: false),
    // Live/Movie/Series streams
    RegExp(r'(https?://[^\s<>"\']+?/live/[^\s<>"\']+)', caseSensitive: false),
    RegExp(r'(https?://[^\s<>"\']+?/movie/[^\s<>"\']+)', caseSensitive: false),
    RegExp(r'(https?://[^\s<>"\']+?/series/[^\s<>"\']+)', caseSensitive: false),
    // Panel links
    RegExp(r'(https?://[^\s<>"\']+?/panel_api\.php\?[^\s<>"\']+)', caseSensitive: false),
    // Player API
    RegExp(r'(https?://[^\s<>"\']+?/player_api\.php\?[^\s<>"\']+)', caseSensitive: false),
    // Direct m3u8/ts
    RegExp(r'(https?://[^\s<>"\']+?\.m3u8?(?:\?[^\s<>"\']*)?)', caseSensitive: false),
    RegExp(r'(https?://[^\s<>"\']+?\.ts(?:\?[^\s<>"\']*)?)', caseSensitive: false),
    // Generic IPTV ports
    RegExp(r'(https?://[^\s<>"\']+?:(?:8080|8000|25461|2095|2082|80)/[^\s<>"\']+)', caseSensitive: false),
  ];

  static final RegExp _portalPattern = RegExp(
    r'(?:Portal|👀[^A-Za-z]*ℙ𝕠𝕣𝕥𝕒𝕝|Host|Server|🔰[^A-Za-z]*)[:\s]+\s*(https?://[^\s]+)',
    caseSensitive: false,
  );

  static final RegExp _m3uEmojiPattern = RegExp(
    r'🎬[^h]*(https?://[^\s<>"\']+)',
    caseSensitive: false,
  );

  static List<String> extractLinks(String text) {
    final links = <String>{};

    // Method 1: Direct URL extraction
    for (final pattern in _urlPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final url = _cleanUrl(match.group(1) ?? '');
        if (_isValidIptvUrl(url)) {
          links.add(url);
        }
      }
    }

    // Method 2: M3U emoji pattern (🎬 𝕄𝟛𝕦)
    final m3uMatches = _m3uEmojiPattern.allMatches(text);
    for (final match in m3uMatches) {
      final url = _cleanUrl(match.group(1) ?? '');
      if (_isValidIptvUrl(url)) {
        links.add(url);
      }
    }

    // Method 3: Build URLs from portal + credentials
    final portals = <String>[];
    final usernames = <String>[];
    final passwords = <String>[];

    // Extract portals
    final portalMatches = _portalPattern.allMatches(text);
    for (final match in portalMatches) {
      portals.add(_cleanUrl(match.group(1) ?? ''));
    }

    // Extract usernames
    final userPatterns = [
      RegExp(r'[Uu]ser(?:name)?[:\s=]+\s*([A-Za-z0-9_.-]+)'),
      RegExp(r'👥[^A-Za-z0-9]*([A-Za-z0-9_.-]+)'),
    ];
    for (final pattern in userPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final user = match.group(1);
        if (user != null && user.length > 2) {
          usernames.add(user);
        }
      }
    }

    // Extract passwords
    final passPatterns = [
      RegExp(r'[Pp]ass(?:word)?[:\s=]+\s*([A-Za-z0-9_.-]+)'),
      RegExp(r'🔑[^A-Za-z0-9]*([A-Za-z0-9_.-]+)'),
    ];
    for (final pattern in passPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final pass = match.group(1);
        if (pass != null && pass.length > 2) {
          passwords.add(pass);
        }
      }
    }

    // Build URLs from combinations
    for (final portal in portals) {
      for (var i = 0; i < usernames.length; i++) {
        final user = usernames[i];
        final pwd = i < passwords.length ? passwords[i] : '';
        if (user.isNotEmpty && pwd.isNotEmpty) {
          var base = portal.endsWith('/') ? portal.substring(0, portal.length - 1) : portal;
          // Check if has port
          final hasPort = RegExp(r':\d+$').hasMatch(Uri.parse(base).host + (Uri.parse(base).hasPort ? ':${Uri.parse(base).port}' : ''));
          if (!hasPort && !base.contains(':8080') && !base.contains(':2095')) {
            base = base.replaceFirst(RegExp(r'(https?://[^/]+)'), '\$1:8080');
          }
          final url = '$base/get.php?username=$user&password=$pwd&type=m3u_plus';
          links.add(url);
        }
      }
    }

    return links.toList();
  }

  static String _cleanUrl(String url) {
    if (url.isEmpty) return '';
    // Remove trailing punctuation
    url = url.replaceAll(RegExp(r'[.,;:!?\)\]\'"]+$'), '');
    // Remove unicode fancy characters
    url = url.replaceAll(RegExp(r'[^\x00-\x7F]+$'), '');
    return url.trim();
  }

  static bool _isValidIptvUrl(String url) {
    if (url.isEmpty || !url.startsWith('http')) return false;
    
    final indicators = [
      'get.php', 'player_api.php', 'panel_api.php',
      '/live/', '/movie/', '/series/',
      '.m3u', '.m3u8', '.ts',
      'username=', 'password=',
    ];
    
    final urlLower = url.toLowerCase();
    if (indicators.any((ind) => urlLower.contains(ind))) return true;
    
    // Check for port number
    return RegExp(r':\d{4,5}/').hasMatch(url);
  }

  static String? extractExpireFromText(String text) {
    final patterns = [
      RegExp(r'[Ee]xp(?:ire)?[:\s]+(\d{4}-\d{2}-\d{2})'),
      RegExp(r'📆\s*[^\d]*(\d{4}-\d{2}-\d{2})'),
      RegExp(r'[Ee]xp(?:ire)?[:\s]+(\d{2}[./]\d{2}[./]\d{4})'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }
}

// ==================== FILE SERVICE ====================
class FileService {
  static Future<String> get iptvFolder async {
    final directory = await getExternalStorageDirectory();
    final path = '${directory?.path ?? '/storage/emulated/0/Download'}/IPTV';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  static Future<String> savePlaylist(String content, String filename) async {
    final folder = await iptvFolder;
    final file = File('$folder/$filename');
    await file.writeAsString(content, encoding: utf8);
    return file.path;
  }

  static String shortDomain(String url) {
    try {
      final uri = Uri.parse(url);
      var host = uri.host;
      if (host.startsWith('www.')) host = host.substring(4);
      final parts = host.split('.');
      if (parts.length > 2) {
        return parts.sublist(parts.length - 2).join('.');
      }
      return host.length > 18 ? host.substring(0, 18) : host;
    } catch (_) {
      return 'iptv';
    }
  }

  static String getExtension(String format) {
    switch (format) {
      case 'm3u': return '.m3u';
      case 'txt': return '.txt';
      default: return '.m3u8';
    }
  }
}
