import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Full black status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF13131A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const CyrusVpnApp(),
    ),
  );
}

class CyrusVpnApp extends StatelessWidget {
  const CyrusVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyrus VPN',
      debugShowCheckedModeBanner: false,
      theme: CyrusTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
