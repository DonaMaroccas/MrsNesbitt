import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tela_inicial.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Only apply immersive mode on mobile (not on web)
  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  runApp(const DeliveryPetsApp());
}

class DeliveryPetsApp extends StatelessWidget {
  const DeliveryPetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery Pets',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme:
            const AppBarTheme(backgroundColor: Color(0xFF0A0A0A), elevation: 0),
        cardColor: const Color(0xFF1A1A1A),
      ),
      home: const TelaInicial(),
    );
  }
}
