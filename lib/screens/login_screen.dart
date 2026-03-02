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
  final VoidCallback? onGoToRegister;

  const LoginScreen({super.key, this.onLoginSuccess, this.onGoToRegister});

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

  /// Limpia HTML y simplifica mensajes de error del backend
  String _cleanErrorMessage(String? rawError) {
    if (rawError == null || rawError.isEmpty) {
      return 'Error al iniciar sesión';
    }

    // Remover todas las etiquetas HTML
    String cleaned = rawError.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Remover URLs completas
    cleaned = cleaned.replaceAll(RegExp(r'https?://[^\s]+'), '');
    
    // Limpiar espacios múltiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Detectar y simplificar mensajes comunes
    final lowerError = cleaned.toLowerCase();
    
    if (lowerError.contains('contraseña') && lowerError.contains('no es correcta')) {
      return 'La contraseña es incorrecta';
    }
    
    if (lowerError.contains('contraseña') && lowerError.contains('incorrecta')) {
      return 'La contraseña es incorrecta';
    }
    
    if (lowerError.contains('usuario') && lowerError.contains('incorrecto')) {
      return 'Correo o contraseña incorrectos';
    }
    
    if (lowerError.contains('correo') && lowerError.contains('incorrecto')) {
      return 'Correo o contraseña incorrectos';
    }
    
    if (lowerError.contains('has olvidado') || lowerError.contains('olvidado tu contraseña')) {
      return 'La contraseña es incorrecta';
    }
    
    if (lowerError.contains('no existe') || lowerError.contains('no encontrado')) {
      return 'No existe una cuenta con ese correo';
    }
    
    if (lowerError.contains('nombre de usuario') && lowerError.contains('registrado')) {
      return 'No existe una cuenta con ese correo';
    }
    
    if (lowerError.contains('usuario') && lowerError.contains('registrado')) {
      return 'No existe una cuenta con ese correo';
    }
    
    // Si el mensaje limpio es muy largo, tomar solo la primera parte
    if (cleaned.length > 100) {
      final firstSentence = cleaned.split('.').first;
      return firstSentence.isNotEmpty ? '$firstSentence.' : 'Error al iniciar sesión';
    }

    return cleaned.isNotEmpty ? cleaned : 'Error al iniciar sesión';
  }

  void _showForgotPasswordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ForgotPasswordSheetContent(
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showPrivacyPolicyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.origen,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Barra superior
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.raizSagrada,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Política de Privacidad',
                    style: AppTypography.kaushanTitle(
                      fontSize: 20,
                      color: AppColors.raizSagrada,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.raizSagrada,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Política de Privacidad App Fénix',
                      style: AppTypography.kaushanTitle(
                        fontSize: 22,
                        color: AppColors.raizSagrada,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildPrivacyItem(
                      'Recopilación de Información',
                      'Recopilamos información que nos proporcionas directamente, como tu correo electrónico y nombre cuando creas una cuenta o te comunicas con nosotros.',
                    ),
                    _buildPrivacyItem(
                      'Uso de la Información',
                      'Utilizamos tu información para proporcionarte acceso a tu contenido personalizado, mejorar nuestros servicios y comunicarnos contigo sobre tu cuenta.',
                    ),
                    _buildPrivacyItem(
                      'Protección de Datos',
                      'Implementamos medidas de seguridad técnicas y organizativas para proteger tu información personal contra acceso no autorizado, pérdida o destrucción.',
                    ),
                    _buildPrivacyItem(
                      'Almacenamiento',
                      'Tu información se almacena de forma segura en nuestros servidores. Utilizamos almacenamiento seguro encriptado para proteger tus credenciales de acceso.',
                    ),
                    _buildPrivacyItem(
                      'Derechos del Usuario',
                      'Tienes derecho a acceder, rectificar, eliminar o portar tus datos personales. Puedes ejercer estos derechos contactándonos a través de los canales de soporte.',
                    ),
                    _buildPrivacyItem(
                      'Cookies y Tecnologías Similares',
                      'Esta aplicación utiliza tecnologías de almacenamiento local para mantener tu sesión activa y mejorar tu experiencia. No compartimos esta información con terceros.',
                    ),
                    _buildPrivacyItem(
                      'Cambios en la Política',
                      'Nos reservamos el derecho de actualizar esta política de privacidad. Te notificaremos sobre cambios significativos a través de la aplicación o por correo electrónico.',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Última actualización: ${DateTime.now().year}',
                      style: AppTypography.ralewayLight(
                        fontSize: 12,
                        color: AppColors.raizSagrada.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyItem(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.ralewayBold(
              fontSize: 16,
              color: AppColors.raizSagrada,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.8),
            ).copyWith(height: 1.5),
          ),
        ],
      ),
    );
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
        _errorMessage = _cleanErrorMessage(authProvider.error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origen,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            // Header marrón
            _buildHeader(),
            // Cuerpo crema con formulario
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
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
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showForgotPasswordSheet(context),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: AppTypography.ralewayRegular(
                    fontSize: 13,
                    color: AppColors.raizSagrada.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 18),
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
              // Mensaje de error (login fallido o sesión en otro dispositivo)
              Consumer<AuthProvider>(
                builder: (_, authProvider, __) {
                  final message = _errorMessage ?? authProvider.error;
                  if (message == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _cleanErrorMessage(message),
                        style: AppTypography.ralewayRegular(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
              if (widget.onGoToRegister != null) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: widget.onGoToRegister,
                  child: Text(
                    '${AppConstants.noAccount} ${AppConstants.registerNow}',
                    style: AppTypography.ralewayRegular(
                      fontSize: 14,
                      color: AppColors.raizSagrada,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Política de privacidad - Casi al fondo
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => _showPrivacyPolicyModal(context),
              child: Text(
                AppConstants.privacyPolicy,
                style: AppTypography.ralewayLight(
                  fontSize: 12,
                  color: AppColors.raizSagrada.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Contenido del sheet de recuperar contraseña. Copy neutro.
class _ForgotPasswordSheetContent extends StatefulWidget {
  final VoidCallback onClose;

  const _ForgotPasswordSheetContent({required this.onClose});

  @override
  State<_ForgotPasswordSheetContent> createState() => _ForgotPasswordSheetContentState();
}

class _ForgotPasswordSheetContentState extends State<_ForgotPasswordSheetContent> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = 'Ingresa tu correo electrónico';
        _success = false;
      });
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _error = 'Ingresa un correo electrónico válido';
        _success = false;
      });
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
      _success = false;
    });
    try {
      await context.read<AuthProvider>().requestPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Error de conexión. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.origen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recuperar contraseña',
                style: AppTypography.kaushanTitle(
                  fontSize: 22,
                  color: AppColors.raizSagrada,
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: Icon(Icons.close, color: AppColors.raizSagrada),
              ),
            ],
          ),
          if (!_success) ...[
            const SizedBox(height: 8),
            Text(
              'Ingresa tu correo electrónico y te enviaremos un enlace seguro para restablecer tu contraseña.',
              style: AppTypography.ralewayRegular(
                fontSize: 14,
                color: AppColors.raizSagrada.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: AppConstants.emailHint,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTypography.ralewayRegular(
                  fontSize: 13,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Enviar enlace de recuperación'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Icon(Icons.check_circle, color: AppColors.ascenso, size: 56),
            const SizedBox(height: 12),
            Text(
              'Hemos enviado un enlace de recuperación a tu correo. Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
              style: AppTypography.ralewayRegular(
                fontSize: 14,
                color: AppColors.raizSagrada,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onClose,
                child: const Text('Entendido'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
