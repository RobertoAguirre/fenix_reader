import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Pantalla de Términos y Condiciones
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origen,
      appBar: AppBar(
        backgroundColor: AppColors.origen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.raizSagrada),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Términos y Condiciones',
          style: AppTypography.kaushanTitle(
            fontSize: 20,
            color: AppColors.raizSagrada,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Términos y Condiciones App Fénix',
                style: AppTypography.kaushanTitle(
                  fontSize: 22,
                  color: AppColors.raizSagrada,
                ),
              ),
              const SizedBox(height: 24),
              _buildTermItem(
                'Todas las hipnosis fénix deben reproducirse usando audífonos si duermes con alguien acompañadx. No se tiene que poner atención, solamente dejarte llevar al sueño profundo. Para mayores resultados, coloca cada tema deseado por lapsos de 3-6-9-12 o 21 días seguidos, según como tú lo sientas.',
              ),
              _buildTermItem(
                'El contenido de esta aplicación está diseñado para uso personal y no debe utilizarse mientras conduces, operas maquinaria o realizas actividades que requieran atención plena. El usuario es responsable de su propio bienestar al utilizar este contenido.',
              ),
              _buildTermItem(
                'Esta aplicación es un reproductor de contenido. El acceso al contenido se gestiona a través de tu cuenta vinculada. Para cualquier consulta sobre tu cuenta o contenido, contacta directamente con el proveedor del servicio.',
              ),
              _buildTermItem(
                'Toda información y material ofrecido por Wendy Staufert son de propiedad intelectual y está prohibida su reproducción, venta o duplicado en forma total o parcial sin autorización expresa.',
              ),
              _buildTermItem(
                'El uso de esta aplicación implica la aceptación de estos términos. Si no estás de acuerdo con alguno de estos términos, no utilices la aplicación.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 12),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.raizSagrada,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.ralewayRegular(
                fontSize: 15,
                color: AppColors.raizSagrada,
              ).copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

