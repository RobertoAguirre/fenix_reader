import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/fenix_logo.dart';
import '../widgets/fenix_bottom_nav.dart';

/// Pantalla de Login
class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  int _navIndex = 2; // Perfil seleccionado por defecto en login

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    
    // TODO: Implementar lógica de login con AuthService
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isLoading = false);
    widget.onLoginSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origen,
      body: Column(
        children: [
          // Header marrón
          _buildHeader(),
          // Cuerpo crema con formulario
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: FenixBottomNav(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 30,
      ),
      decoration: const BoxDecoration(
        color: AppColors.raizSagrada,
      ),
      child: Center(
        child: Text(
          AppConstants.welcomeTitle,
          style: AppTypography.kaushanTitle(
            fontSize: 32,
            color: AppColors.expansionAlquimica,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        // Watermark Logo Fénix
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Opacity(
              opacity: 0.15,
              child: FenixLogo(
                size: 180,
                color: AppColors.raizSagrada,
              ),
            ),
          ),
        ),
        // Watermark Firma
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Opacity(
              opacity: 0.2,
              child: Text(
                'Wendy Staufert',
                style: AppTypography.kaushanTitle(
                  fontSize: 42,
                  color: AppColors.raizSagrada,
                ),
              ),
            ),
          ),
        ),
        // Contenido del formulario
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 80),
              // Título Iniciar Sesión
              Text(
                AppConstants.login,
                style: AppTypography.kaushanTitle(
                  fontSize: 28,
                  color: AppColors.raizSagrada,
                ),
              ),
              const SizedBox(height: 30),
              // Campo email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: AppConstants.emailHint,
                ),
              ),
              const SizedBox(height: 16),
              // Campo contraseña
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: AppConstants.passwordHint,
                ),
              ),
              const SizedBox(height: 30),
              // Botón Acceder
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(AppConstants.access),
                ),
              ),
              const SizedBox(height: 20),
              // Link registro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppConstants.noAccount,
                    style: AppTypography.ralewayRegular(
                      fontSize: 13,
                      color: AppColors.raizSagrada,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      // TODO: Abrir enlace de registro en Safari
                    },
                    child: Text(
                      AppConstants.registerNow,
                      style: AppTypography.ralewayBold(
                        fontSize: 13,
                        color: AppColors.raizSagrada,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
              // Política de privacidad
              GestureDetector(
                onTap: () {
                  // TODO: Abrir política de privacidad en Safari
                },
                child: Text(
                  AppConstants.privacyPolicy,
                  style: AppTypography.ralewayLight(
                    fontSize: 12,
                    color: AppColors.raizSagrada.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
