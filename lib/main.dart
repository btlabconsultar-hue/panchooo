import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'route_observer.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_products_screen.dart';
import 'screens/checkout_screen.dart';
import 'services/checkout_service.dart';
import 'services/firebase_service.dart';
import 'services/gemini_service.dart';
import 'services/sports_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState(
    sportsService: SportsService(),
    firebaseService: FirebaseService(),
    aiService: AiService(),
    checkoutService: CheckoutService(),
  );

  await appState.initialize();

  runApp(ChangeNotifierProvider.value(value: appState, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tienda Deportiva',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0546A0),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F9FF),
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B3D91),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1220),
      ),
      home: const CheckoutScreen(),
      navigatorObservers: [appRouteObserver],
      routes: {
        '/checkout': (_) => const CheckoutScreen(),
        '/admin-login': (_) => const AdminLoginScreen(),
        '/admin-products': (_) => const AdminProductsScreen(),
      },
    );
  }
}
