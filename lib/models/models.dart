// ==================== CHANNEL MODEL ====================
class Channel {
  final String name;
  final String group;
  final String logo;
  final String url;

  Channel({
    required this.name,
    required this.group,
    this.logo = '',
    required this.url,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'group': group,
    'logo': logo,
    'url': url,
  };

  factory Channel.fromMap(Map<String, dynamic> map) => Channel(
    name: map['name'] ?? '',
    group: map['group'] ?? 'Diğer',
    logo: map['logo'] ?? '',
    url: map['url'] ?? '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel && runtimeType == other.runtimeType && url == other.url;

  @override
  int get hashCode => url.hashCode;
}

// ==================== GROUP MODEL ====================
class ChannelGroup {
  final String name;
  final List<Channel> channels;
  final String logo;
  final String countryId;
  bool isSelected;

  ChannelGroup({
    required this.name,
    required this.channels,
    this.logo = '',
    this.countryId = 'other',
    this.isSelected = false,
  });

  int get count => channels.length;
}

// ==================== FAVORITE MODEL ====================
class Favorite {
  final int? id;
  final String url;
  final String name;
  final String expire;
  final int channelCount;
  final DateTime createdAt;

  Favorite({
    this.id,
    required this.url,
    required this.name,
    this.expire = '',
    this.channelCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'url': url,
    'name': name,
    'expire': expire,
    'channel_count': channelCount,
    'created_at': createdAt.toIso8601String(),
  };

  factory Favorite.fromMap(Map<String, dynamic> map) => Favorite(
    id: map['id'],
    url: map['url'] ?? '',
    name: map['name'] ?? '',
    expire: map['expire'] ?? '',
    channelCount: map['channel_count'] ?? 0,
    createdAt: map['created_at'] != null 
        ? DateTime.parse(map['created_at']) 
        : DateTime.now(),
  );
}

// ==================== STATS MODEL ====================
class AppStats {
  final int totalTests;
  final int workingLinks;
  final int totalChannels;
  final int totalFiles;

  AppStats({
    this.totalTests = 0,
    this.workingLinks = 0,
    this.totalChannels = 0,
    this.totalFiles = 0,
  });

  Map<String, dynamic> toMap() => {
    'total_tests': totalTests,
    'working_links': workingLinks,
    'total_channels': totalChannels,
    'total_files': totalFiles,
  };

  factory AppStats.fromMap(Map<String, dynamic> map) => AppStats(
    totalTests: map['total_tests'] ?? 0,
    workingLinks: map['working_links'] ?? 0,
    totalChannels: map['total_channels'] ?? 0,
    totalFiles: map['total_files'] ?? 0,
  );

  AppStats copyWith({
    int? totalTests,
    int? workingLinks,
    int? totalChannels,
    int? totalFiles,
  }) => AppStats(
    totalTests: totalTests ?? this.totalTests,
    workingLinks: workingLinks ?? this.workingLinks,
    totalChannels: totalChannels ?? this.totalChannels,
    totalFiles: totalFiles ?? this.totalFiles,
  );
}

// ==================== COUNTRY MODEL ====================
class Country {
  final String id;
  final String name;
  final String flag;
  final List<String> codes;
  final int priority;
  final bool isPriority;

  const Country({
    required this.id,
    required this.name,
    required this.flag,
    required this.codes,
    this.priority = 99,
    this.isPriority = false,
  });
}

class Countries {
  static const Map<String, Country> all = {
    'turkey': Country(
      id: 'turkey', name: 'Türkiye', flag: '🇹🇷',
      codes: ['tr', 'tur', 'turkey', 'turkiye', 'turk'],
      priority: 1, isPriority: true,
    ),
    'germany': Country(
      id: 'germany', name: 'Almanya', flag: '🇩🇪',
      codes: ['de', 'ger', 'germany', 'deutsch', 'almanya'],
      priority: 2, isPriority: true,
    ),
    'austria': Country(
      id: 'austria', name: 'Avusturya', flag: '🇦🇹',
      codes: ['at', 'aut', 'austria', 'avusturya', 'osterreich'],
      priority: 3, isPriority: true,
    ),
    'romania': Country(
      id: 'romania', name: 'Romanya', flag: '🇷🇴',
      codes: ['ro', 'rom', 'romania', 'romanya'],
      priority: 4, isPriority: true,
    ),
    'france': Country(
      id: 'france', name: 'Fransa', flag: '🇫🇷',
      codes: ['fr', 'fra', 'france', 'fransa'],
      priority: 5,
    ),
    'italy': Country(
      id: 'italy', name: 'İtalya', flag: '🇮🇹',
      codes: ['it', 'ita', 'italy', 'italya'],
      priority: 6,
    ),
    'spain': Country(
      id: 'spain', name: 'İspanya', flag: '🇪🇸',
      codes: ['es', 'esp', 'spain', 'ispanya'],
      priority: 7,
    ),
    'uk': Country(
      id: 'uk', name: 'İngiltere', flag: '🇬🇧',
      codes: ['uk', 'gb', 'england', 'british'],
      priority: 8,
    ),
    'usa': Country(
      id: 'usa', name: 'Amerika', flag: '🇺🇸',
      codes: ['us', 'usa', 'america', 'amerika'],
      priority: 9,
    ),
    'netherlands': Country(
      id: 'netherlands', name: 'Hollanda', flag: '🇳🇱',
      codes: ['nl', 'netherlands', 'holland'],
      priority: 10,
    ),
    'poland': Country(
      id: 'poland', name: 'Polonya', flag: '🇵🇱',
      codes: ['pl', 'poland', 'polonya'],
      priority: 11,
    ),
    'russia': Country(
      id: 'russia', name: 'Rusya', flag: '🇷🇺',
      codes: ['ru', 'rus', 'russia', 'rusya'],
      priority: 12,
    ),
    'arabic': Country(
      id: 'arabic', name: 'Arapça', flag: '🇸🇦',
      codes: ['ar', 'ara', 'arabic', 'arab'],
      priority: 13,
    ),
    'other': Country(
      id: 'other', name: 'Diğer', flag: '🌐',
      codes: ['other'],
      priority: 99,
    ),
  };

  static List<Country> get priorityCountries => 
      all.values.where((c) => c.isPriority).toList()..sort((a, b) => a.priority.compareTo(b.priority));

  static List<Country> get otherCountries => 
      all.values.where((c) => !c.isPriority).toList()..sort((a, b) => a.priority.compareTo(b.priority));

  static Country? detect(String groupName) {
    final g = groupName.toLowerCase();
    for (final country in all.values) {
      for (final code in country.codes) {
        if (g == code || g.startsWith('$code ') || g.startsWith('$code-') ||
            g.endsWith(' $code') || RegExp(r'\b' + code + r'\b').hasMatch(g)) {
          return country;
        }
      }
    }
    return all['other'];
  }
}

// ==================== TEST RESULT ====================
class LinkTestResult {
  final String url;
  final bool isWorking;
  final String message;
  final String? expire;
  final int? channelCount;

  LinkTestResult({
    required this.url,
    required this.isWorking,
    required this.message,
    this.expire,
    this.channelCount,
  });
}

// ==================== EXPORT FILE ====================
class ExportedFile {
  final String name;
  final int channelCount;
  final String? expire;
  final String path;

  ExportedFile({
    required this.name,
    required this.channelCount,
    this.expire,
    required this.path,
  });
}
