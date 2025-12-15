# IPTV Editor Pro - Flutter Edition

<p align="center">
  <img src="screenshots/logo.png" width="120" alt="IPTV Editor Pro Logo">
</p>

<p align="center">
  <strong>Profesyonel IPTV Playlist Düzenleyici</strong><br>
  Akıllı Link Tespit • 4 Tema • Ülke Filtreleme • Toplu Test
</p>

<p align="center">
  <a href="https://github.com/user/iptv-editor-pro/releases">
    <img src="https://img.shields.io/github/v/release/user/iptv-editor-pro?style=flat-square" alt="Release">
  </a>
  <a href="https://github.com/user/iptv-editor-pro/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/user/iptv-editor-pro/build.yml?style=flat-square" alt="Build">
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.24-blue?style=flat-square" alt="Flutter">
  <img src="https://img.shields.io/badge/Platform-Android-green?style=flat-square" alt="Platform">
</p>

---

## ✨ Özellikler

### 🤖 Akıllı Link Tespit (AI-like)
- Karışık Telegram mesajlarından IPTV linkleri otomatik bulur
- Emoji içeren metinleri anlar (🎬 𝕄𝟛𝕦, 👥 𝕌𝕤𝕖𝕣, 🔑 ℙ𝕒𝕤𝕤)
- Portal + Username + Password kombinasyonlarından URL oluşturur
- 15+ regex pattern ile robust link extraction

### 🎨 Modern UI
- **4 Tema**: Cyberpunk, Midnight, Forest, Light
- Material Design 3
- Glassmorphism kartlar
- Smooth animasyonlar
- Responsive layout (yatay/dikey)

### ⚡ Performans
- HTTP session pooling
- LRU cache (500 capacity)
- Async/await yapısı
- 60fps animasyonlar

### 📁 Dosya Yönetimi
- M3U/M3U8/TXT formatları
- Otomatik bitiş tarihi algılama
- Duplicate temizleme
- Ülke bazlı filtreleme
- Kayıt: `Download/IPTV/`

---

## 📱 Ekranlar

| Ana Sayfa | Otomatik İşlem | Test Sonuçları |
|-----------|----------------|----------------|
| ![Home](screenshots/home.png) | ![Auto](screenshots/auto.png) | ![Results](screenshots/results.png) |

| Kanal Listesi | Ülke Seçimi | Ayarlar |
|---------------|-------------|---------|
| ![Channels](screenshots/channels.png) | ![Countries](screenshots/countries.png) | ![Settings](screenshots/settings.png) |

---

## 🚀 Kurulum

### GitHub Actions (Önerilen)
1. Bu repository'yi fork edin
2. Actions sekmesine gidin
3. "Build Android APK" workflow'unu çalıştırın
4. Artifacts'tan APK'yı indirin

### Manuel Build
```bash
# Clone
git clone https://github.com/user/iptv-editor-pro.git
cd iptv-editor-pro

# Dependencies
flutter pub get

# Build APK
flutter build apk --release

# APK konumu
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 📋 Gereksinimler

- Flutter 3.24+
- Dart 3.0+
- Android SDK 21+ (Android 5.0+)
- Java 17

---

## 🗂️ Proje Yapısı

```
iptv_flutter/
├── lib/
│   ├── main.dart              # Uygulama giriş noktası
│   ├── models/
│   │   └── models.dart        # Channel, Favorite, Stats
│   ├── providers/
│   │   └── app_provider.dart  # State management
│   ├── services/
│   │   └── services.dart      # HTTP, DB, M3U Parser, Smart Extractor
│   ├── screens/
│   │   ├── screens.dart       # Barrel export
│   │   ├── screens_part1.dart # Welcome, Manual, Auto Input
│   │   ├── screens_part2.dart # Channels, Testing, Results
│   │   └── screens_part3.dart # Countries, Processing, Settings
│   ├── themes/
│   │   └── app_themes.dart    # 4 tema tanımları
│   └── widgets/
│       └── widgets.dart       # GlassCard, AccentButton, etc.
├── android/                   # Android yapılandırması
├── assets/                    # Fontlar, ikonlar
├── .github/workflows/
│   └── build.yml              # GitHub Actions CI/CD
└── pubspec.yaml               # Dependencies
```

---

## 🎯 Kullanım

### Manuel Düzenleme
1. IPTV URL'sini girin veya yapıştırın
2. Kanalları yükleyin
3. Grupları seçin
4. Dışa aktarın

### Otomatik İşlem
1. Karışık metin/Telegram mesajı yapıştırın
2. "Linkleri Bul" butonuna tıklayın
3. Bulunan linkler otomatik test edilir
4. Çalışan linkler için ülke seçin
5. Her link için ayrı dosya oluşturulur

---

## 🔧 Desteklenen URL Formatları

```
# Standart M3U
http://server:8080/get.php?username=XXX&password=YYY&type=m3u_plus

# Live/Movie/Series
http://server:8080/live/XXX/YYY/stream.m3u8
http://server:8080/movie/XXX/YYY/movie.mp4

# Panel API
http://server/panel_api.php?username=XXX&password=YYY

# Direct streams
http://server/playlist.m3u8
```

---

## 🌍 Desteklenen Ülkeler

| Öncelikli | Diğer |
|-----------|-------|
| 🇹🇷 Türkiye | 🇫🇷 Fransa |
| 🇩🇪 Almanya | 🇮🇹 İtalya |
| 🇦🇹 Avusturya | 🇪🇸 İspanya |
| 🇷🇴 Romanya | 🇬🇧 İngiltere |
| | 🇺🇸 Amerika |
| | 🇳🇱 Hollanda |
| | 🇵🇱 Polonya |
| | 🇷🇺 Rusya |
| | 🇸🇦 Arapça |

---

## 📄 Lisans

MIT License - Özgürce kullanın, değiştirin, dağıtın.

---

## 🙏 Teşekkürler

- [Flutter](https://flutter.dev)
- [Provider](https://pub.dev/packages/provider)
- [Dio](https://pub.dev/packages/dio)
- [SQLite](https://pub.dev/packages/sqflite)

---

<p align="center">
  Made with ❤️ using Flutter
</p>
