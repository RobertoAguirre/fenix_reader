import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/content_provider.dart';
import 'providers/membership_provider.dart';
import 'providers/program_provider.dart';
import 'services/iap_service.dart';
import 'services/audio_cache_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Estilo de barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Inicializar IAP SDK (solo para cumplir requisito de App Store)
  IAPService().initialize();

  // Limpiar caché de audio antiguo (en background)
  AudioCacheService().cleanupOldFiles();

  runApp(const FenixReaderApp());
}

class FenixReaderApp extends StatelessWidget {
  const FenixReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        ChangeNotifierProvider(create: (_) => MembershipProvider()),
        ChangeNotifierProvider(create: (_) => ProgramProvider()),
      ],
      child: MaterialApp(
        title: 'Fénix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AppNavigator(),
      ),
    );
  }
}

/// Navegador principal que decide si mostrar Login o Home
class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  bool _isLoggedIn = false;

  void _handleLoginSuccess() {
    setState(() => _isLoggedIn = true);
  }

  void _handleLogout() {
    setState(() => _isLoggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return const HomeScreen();
    }
    return LoginScreen(onLoginSuccess: _handleLoginSuccess);
  }
}
