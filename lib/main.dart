import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/calendar_refresh_provider.dart';
import 'providers/content_provider.dart';
import 'providers/membership_provider.dart';
import 'providers/program_provider.dart';
import 'services/iap_service.dart';
import 'services/audio_cache_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

const String _oneSignalAppId = 'f2561d52-ac45-4886-92fb-b18f99422515';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Misma sesión que just_audio: playback → el audio de los videos (video_player/AVPlayer)
  // puede seguir en segundo plano con UIBackgroundModes audio (iOS) y foco adecuado (Android).
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // Estilo de barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // OneSignal: inicializar y solicitar permiso de notificaciones
  OneSignal.initialize(_oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);

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
        ChangeNotifierProvider(create: (_) => CalendarRefreshNotifier()),
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
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    if (!mounted) return;
    
    debugPrint('🔍 Verificando sesión guardada...');
    final authProvider = context.read<AuthProvider>();
    final hasSession = await authProvider.init();
    debugPrint('🔍 Resultado verificación sesión: $hasSession');
    
    if (hasSession && mounted) {
      final userEmail = authProvider.user?.email;
      debugPrint('✅ Sesión válida encontrada para: $userEmail');
      
      if (userEmail != null) {
        debugPrint('📦 Sincronizando contenido del usuario (sin caché)...');
        context.read<ContentProvider>().syncPurchasesFromServer(userEmail);
        OneSignal.login(userEmail);
      }
      
      setState(() => _isLoggedIn = true);
    } else {
      debugPrint('❌ No hay sesión válida, mostrando LoginScreen');
    }
  }

  void _handleLoginSuccess() {
    debugPrint('✅ Login exitoso, navegando a HomeScreen');
    if (mounted) {
      final email = context.read<AuthProvider>().user?.email;
      if (email != null) OneSignal.login(email);
      setState(() => _isLoggedIn = true);
    }
  }

  void _handleLogout() {
    if (mounted) {
      OneSignal.logout();
      setState(() => _isLoggedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return const HomeScreen();
    }
    if (_showRegister) {
      return RegisterScreen(
        onGoToLogin: () => setState(() => _showRegister = false),
      );
    }
    return LoginScreen(
      onLoginSuccess: _handleLoginSuccess,
      onGoToRegister: () => setState(() => _showRegister = true),
    );
  }
}
