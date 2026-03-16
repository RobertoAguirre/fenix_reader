import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/fenix_logo.dart';
import '../widgets/fenix_bottom_nav.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../providers/calendar_refresh_provider.dart';
import 'calendar_screen.dart';
import 'portal_screen.dart';
import 'profile_screen.dart';

/// Pantalla principal con navegación
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastPurchasesSync;

  final List<Widget> _screens = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens.addAll([
      const PortalScreen(),
      const CalendarScreen(),
      ProfileScreen(
        onNavigateToIndex: (index) => setState(() => _currentIndex = index),
      ),
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final email = context.read<AuthProvider>().user?.email;
    if (email == null) return;
    // Tras comprar en navegador y volver: refrescar sin caché (máx. cada 20s para no spamear)
    final now = DateTime.now();
    if (_lastPurchasesSync != null &&
        now.difference(_lastPurchasesSync!) < const Duration(seconds: 20)) {
      return;
    }
    _lastPurchasesSync = now;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ContentProvider>().syncPurchasesFromServer(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: _screens[_currentIndex],
      bottomNavigationBar: FenixBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) context.read<CalendarRefreshNotifier>().refresh();
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.raizSagrada,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saludo
                  Text(
                    'Bienvenida a tu espacio fénix.',
                    style: AppTypography.kaushanTitle(
                      fontSize: 18,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Logo
                  Center(
                    child: Column(
                      children: [
                        const FenixLogo(
                          size: 100,
                          color: AppColors.expansionAlquimica,
                        ),
                        const SizedBox(height: 12),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            final displayName = authProvider.user?.displayName ?? 'Usuario';
                            return Text(
                              displayName,
                              style: AppTypography.kaushanTitle(
                                fontSize: 20,
                                color: AppColors.expansionAlquimica,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Menú items
            _DrawerItem(
              icon: Icons.vpn_key_outlined,
              label: AppConstants.portals,
              onTap: () => _navigateToIndex(0),
            ),
            _DrawerItem(
              icon: Icons.library_books_outlined,
              label: AppConstants.myLibrary,
              onTap: () => _navigateToIndex(1),
            ),
            _DrawerItem(
              icon: Icons.auto_awesome_outlined,
              label: AppConstants.myAccount,
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar a mi espacio
              },
            ),
            _DrawerItem(
              icon: Icons.description_outlined,
              label: AppConstants.termsConditions,
              onTap: () {
                Navigator.pop(context);
                // TODO: Abrir términos en Safari
              },
            ),
            _DrawerItem(
              icon: Icons.mail_outline,
              label: AppConstants.contactUs,
              onTap: () {
                Navigator.pop(context);
                // TODO: Abrir contacto
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToIndex(int index) {
    Navigator.pop(context);
    setState(() => _currentIndex = index);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.white, size: 22),
      title: Text(
        label,
        style: AppTypography.ralewayRegular(
          fontSize: 15,
          color: AppColors.white,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}

