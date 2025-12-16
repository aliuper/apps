class Channel {
  final String name, group, logo, url;
  Channel({required this.name, required this.group, this.logo = '', required this.url});
  Map<String, dynamic> toMap() => {'name': name, 'group': group, 'logo': logo, 'url': url};
  factory Channel.fromMap(Map<String, dynamic> m) => Channel(name: m['name'] ?? '', group: m['group'] ?? 'Diğer', logo: m['logo'] ?? '', url: m['url'] ?? '');
  @override bool operator ==(Object o) => identical(this, o) || o is Channel && url == o.url;
  @override int get hashCode => url.hashCode;
}

class ChannelGroup {
  final String name, logo, countryId;
  final List<Channel> channels;
  bool isSelected;
  ChannelGroup({required this.name, required this.channels, this.logo = '', this.countryId = 'other', this.isSelected = false});
  int get count => channels.length;
}

class Favorite {
  final int? id;
  final String url, name, expire;
  final int channelCount;
  final DateTime createdAt;
  Favorite({this.id, required this.url, required this.name, this.expire = '', this.channelCount = 0, DateTime? createdAt}) : createdAt = createdAt ?? DateTime.now();
  Map<String, dynamic> toMap() => {'url': url, 'name': name, 'expire': expire, 'channel_count': channelCount, 'created_at': createdAt.toIso8601String()};
  factory Favorite.fromMap(Map<String, dynamic> m) => Favorite(id: m['id'], url: m['url'] ?? '', name: m['name'] ?? '', expire: m['expire'] ?? '', channelCount: m['channel_count'] ?? 0, createdAt: m['created_at'] != null ? DateTime.parse(m['created_at']) : DateTime.now());
}

class AppStats {
  final int totalTests, workingLinks, totalChannels, totalFiles;
  AppStats({this.totalTests = 0, this.workingLinks = 0, this.totalChannels = 0, this.totalFiles = 0});
  factory AppStats.fromMap(Map<String, dynamic> m) => AppStats(totalTests: m['total_tests'] ?? 0, workingLinks: m['working_links'] ?? 0, totalChannels: m['total_channels'] ?? 0, totalFiles: m['total_files'] ?? 0);
}

class Country {
  final String id, name, flag;
  final List<String> codes;
  final int priority;
  final bool isPriority;
  const Country({required this.id, required this.name, required this.flag, required this.codes, this.priority = 99, this.isPriority = false});
}

class Countries {
  static const Map<String, Country> all = {
    'turkey': Country(id: 'turkey', name: 'Türkiye', flag: '🇹🇷', codes: ['tr', 'tur', 'turkey', 'turkiye', 'turk'], priority: 1, isPriority: true),
    'germany': Country(id: 'germany', name: 'Almanya', flag: '🇩🇪', codes: ['de', 'ger', 'germany', 'deutsch', 'almanya'], priority: 2, isPriority: true),
    'austria': Country(id: 'austria', name: 'Avusturya', flag: '🇦🇹', codes: ['at', 'aut', 'austria', 'avusturya'], priority: 3, isPriority: true),
    'romania': Country(id: 'romania', name: 'Romanya', flag: '🇷🇴', codes: ['ro', 'rom', 'romania', 'romanya'], priority: 4, isPriority: true),
    'france': Country(id: 'france', name: 'Fransa', flag: '🇫🇷', codes: ['fr', 'fra', 'france', 'fransa'], priority: 5),
    'italy': Country(id: 'italy', name: 'İtalya', flag: '🇮🇹', codes: ['it', 'ita', 'italy', 'italya'], priority: 6),
    'spain': Country(id: 'spain', name: 'İspanya', flag: '🇪🇸', codes: ['es', 'esp', 'spain', 'ispanya'], priority: 7),
    'uk': Country(id: 'uk', name: 'İngiltere', flag: '🇬🇧', codes: ['uk', 'gb', 'england', 'british'], priority: 8),
    'usa': Country(id: 'usa', name: 'Amerika', flag: '🇺🇸', codes: ['us', 'usa', 'america', 'amerika'], priority: 9),
    'netherlands': Country(id: 'netherlands', name: 'Hollanda', flag: '🇳🇱', codes: ['nl', 'netherlands', 'holland'], priority: 10),
    'poland': Country(id: 'poland', name: 'Polonya', flag: '🇵🇱', codes: ['pl', 'poland', 'polonya'], priority: 11),
    'russia': Country(id: 'russia', name: 'Rusya', flag: '🇷🇺', codes: ['ru', 'rus', 'russia', 'rusya'], priority: 12),
    'arabic': Country(id: 'arabic', name: 'Arapça', flag: '🇸🇦', codes: ['ar', 'ara', 'arabic', 'arab'], priority: 13),
    'other': Country(id: 'other', name: 'Diğer', flag: '🌐', codes: ['other'], priority: 99),
  };
  static List<Country> get priorityCountries => all.values.where((c) => c.isPriority).toList()..sort((a, b) => a.priority.compareTo(b.priority));
  static List<Country> get otherCountries => all.values.where((c) => !c.isPriority && c.id != 'other').toList()..sort((a, b) => a.priority.compareTo(b.priority));
  static Country? detect(String g) {
    final gl = g.toLowerCase();
    for (final c in all.values) {
      for (final code in c.codes) {
        if (gl == code || gl.startsWith('$code ') || gl.startsWith('$code-') || gl.endsWith(' $code') || RegExp('\\b$code\\b').hasMatch(gl)) return c;
      }
    }
    return all['other'];
  }
}

class LinkTestResult {
  final String url, message;
  final bool isWorking;
  final String? expire;
  final int? channelCount;
  LinkTestResult({required this.url, required this.isWorking, required this.message, this.expire, this.channelCount});
}

class ExportedFile {
  final String name, path;
  final int channelCount;
  final String? expire;
  ExportedFile({required this.name, required this.channelCount, this.expire, required this.path});
}
