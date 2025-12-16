import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0a0a0f),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const IPTVEditorApp());
}

class IPTVEditorApp extends StatelessWidget {
  const IPTVEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final theme = provider.theme;
          
          return MaterialApp(
            title: 'IPTV Editor Pro',
            debugShowCheckedModeBanner: false,
            theme: theme.toThemeData(),
            initialRoute: '/',
            routes: {
              '/': (context) => const WelcomeScreen(),
              '/manual-input': (context) => const ManualInputScreen(),
              '/auto-input': (context) => const AutoInputScreen(),
              '/channel-list': (context) => const ChannelListScreen(),
              '/testing': (context) => const TestingScreen(),
              '/auto-result': (context) => const AutoResultScreen(),
              '/country-select': (context) => const CountrySelectScreen(),
              '/processing': (context) => const ProcessingScreen(),
              '/complete': (context) => const CompleteScreen(),
              '/favorites': (context) => const FavoritesScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/manual-link-list': (context) => const ManualLinkListScreen(),
              '/link-editor': (context) => const LinkEditorScreen(),
            },
          );
        },
      ),
    );
  }
}
