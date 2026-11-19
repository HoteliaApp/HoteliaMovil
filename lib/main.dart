import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/config/config.dart';
import 'package:hotel_app/presentation/providers/providers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Habilita persistencia offline y caché ilimitada en Cloud Firestore (H-31)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Inicializa los datos del locale para DateFormat
  await initializeDateFormatting('es', null);

  // Carga el archivo .env antes de iniciar la app
  await dotenv.load(fileName: '.env');

  runApp(
    const ProviderScope(
      child: HotelApp(),
    ),
  );
}

class HotelApp extends ConsumerWidget {
  const HotelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Hotel App',
      debugShowCheckedModeBanner: false,
      theme: const AppTheme().getTheme(),
      darkTheme: const AppTheme(isDarkMode: true).getTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
