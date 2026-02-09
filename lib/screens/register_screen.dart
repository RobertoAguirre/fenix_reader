import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';

const String _termsContent = '''
Términos y condiciones de uso de la aplicación Fénix.

1. Aceptación
Al registrarte y usar la aplicación aceptas estos términos. La app está destinada a contenido de bienestar y meditación.

2. Uso de la aplicación
El contenido (textos, audios, vídeos) es para uso personal. No está permitido redistribuir, revender o usar el contenido con fines comerciales sin autorización.

3. Cuenta y datos
Eres responsable de mantener la confidencialidad de tu cuenta. Los datos se tratan según nuestra política de privacidad.

4. Propiedad intelectual
Todo el contenido y la marca Fénix son propiedad de sus titulares. No se concede ninguna licencia más allá del uso personal en la app.

5. Modificaciones
Nos reservamos el derecho de modificar estos términos. El uso continuado de la app tras cambios implica su aceptación.

6. Contacto
Para dudas sobre estos términos puedes contactarnos a través de los canales indicados en la aplicación.
''';

/// Pantalla de registro. Copy neutro: sin referencias a ventas, precios ni membresías.
class RegisterScreen extends StatefulWidget {
  final VoidCallback? onGoToLogin;

  const RegisterScreen({super.key, this.onGoToLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_nombreController.text.trim().isEmpty ||
        _apellidosController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Todos los campos son obligatorios.');
      return false;
    }
    if (!_emailController.text.trim().contains('@')) {
      setState(() => _errorMessage = 'Ingresa un correo electrónico válido.');
      return false;
    }
    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = 'La contraseña debe tener al menos 8 caracteres.');
      return false;
    }
    if (!_acceptTerms) {
      setState(() => _errorMessage = 'Debes aceptar los términos para continuar.');
      return false;
    }
    return true;
  }

  Future<void> _handleRegister() async {
    if (!_validate()) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _nombreController.text.trim(),
      lastName: _apellidosController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      if (widget.onGoToLogin != null) widget.onGoToLogin!();
    } else {
      setState(() => _errorMessage = authProvider.error ?? 'Error al crear la cuenta.');
    }
  }

  void _showTermsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.origen,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Términos y condiciones',
                    style: AppTypography.ralewayRegular(
                      fontSize: 18,
                      color: AppColors.raizSagrada,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, color: AppColors.raizSagrada),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _termsContent,
                  style: AppTypography.ralewayRegular(
                    fontSize: 14,
                    color: AppColors.raizSagrada,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://wendystaufert.com/politica-privacidad/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
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
      decoration: const BoxDecoration(color: AppColors.raizSagrada),
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
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'Registrarme',
                style: AppTypography.kaushanTitle(
                  fontSize: 28,
                  color: AppColors.raizSagrada,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nombreController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Nombre'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apellidosController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Apellidos'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                autocorrect: false,
                decoration: const InputDecoration(hintText: 'Nombre de usuario'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: AppConstants.emailHint,
                ),
              ),
              const SizedBox(height: 16),
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
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _acceptTerms,
                        onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                        activeColor: AppColors.ascenso,
                        fillColor: WidgetStateProperty.resolveWith((_) => AppColors.raizSagrada.withValues(alpha: 0.2)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: RichText(
                          text: TextSpan(
                            style: AppTypography.ralewayRegular(
                              fontSize: 13,
                              color: AppColors.raizSagrada,
                            ),
                            children: [
                              const TextSpan(text: 'Acepto los '),
                              TextSpan(
                                text: 'términos y condiciones',
                                style: AppTypography.ralewayRegular(
                                  fontSize: 13,
                                  color: AppColors.raizSagrada,
                                ).copyWith(decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _showTermsModal,
                              ),
                              const TextSpan(text: ' para comenzar mi experiencia.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.ralewayRegular(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Activa tu experiencia'),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: widget.onGoToLogin,
                child: Text(
                  '¿Ya tienes cuenta? Inicia sesión',
                  style: AppTypography.ralewayRegular(
                    fontSize: 14,
                    color: AppColors.raizSagrada,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _openPrivacyPolicy,
                child: Text(
                  AppConstants.privacyPolicy,
                  style: AppTypography.ralewayLight(
                    fontSize: 12,
                    color: AppColors.raizSagrada.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}
