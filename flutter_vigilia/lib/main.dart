import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'theme/t.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Permitir portrait y landscape
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Barra de estado transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: T.bg,
  ));

  runApp(const TATSApp());
}

class TATSApp extends StatelessWidget {
  const TATSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'vigilIA',
      debugShowCheckedModeBanner: false,
      theme: T.theme(),
      home: const HomeScreen(),
    );
  }
}
