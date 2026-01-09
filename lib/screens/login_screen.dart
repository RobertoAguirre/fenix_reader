import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../widgets/fenix_logo.dart';

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
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu correo y contraseña');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    debugPrint('🔐 Intentando login con: $email');
    
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(email, password);

    debugPrint('🔐 Resultado login: $success');

    if (success) {
      debugPrint('✅ Login exitoso, llamando onLoginSuccess...');
      debugPrint('🔍 onLoginSuccess es null? ${widget.onLoginSuccess == null}');
      
      // Navegar primero, luego cargar contenido en background
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Llamar callback de navegación
        if (widget.onLoginSuccess != null) {
          debugPrint('🚀 Ejecutando onLoginSuccess callback');
          widget.onLoginSuccess!();
        } else {
          debugPrint('⚠️ onLoginSuccess es NULL - no se puede navegar');
        }
        
        // Cargar contenido en background después de navegar
        context.read<ContentProvider>().loadUserContent(email).catchError((error) {
          debugPrint('⚠️ Error cargando contenido después del login: $error');
          // No bloquear la navegación si falla la carga de contenido
        });
      }
    } else {
      debugPrint('❌ Login falló: ${authProvider.error}');
      setState(() {
        _isLoading = false;
        _errorMessage = authProvider.error ?? 'Error al iniciar sesión';
      });
    }
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
      // Barra de navegación oculta cuando no está logueado
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
        // Watermark Logo Fénix - Grande detrás del contenido
        Center(
          child: Opacity(
            opacity: 0.30,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 1.8,
              height: MediaQuery.of(context).size.width * 1.8,
              child: Image.asset(
                'assets/images/logotriangulo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // Watermark Firma
        // Positioned(
        //   bottom: 80,
        //   left: 0,
        //   right: 0,
        //   child: Center(
        //     child: Opacity(
        //       opacity: 0.2,
        //       child: Text(
        //         'Wendy Staufert',
        //         style: AppTypography.kaushanTitle(
        //           fontSize: 42,
        //           color: AppColors.raizSagrada,
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
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
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: AppConstants.passwordHint,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.raizSagrada.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
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
              // Mensaje de error
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: AppTypography.ralewayRegular(
                    fontSize: 13,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
