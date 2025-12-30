import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Servicio de In-App Purchase
/// IMPORTANTE: Este servicio solo inicializa el SDK de IAP para cumplir
/// con los requisitos de Apple App Store. NO se usa para realizar cobros.
/// El contenido se adquiere en la web externa (WordPress/WooCommerce).
/// READER APP: Solo muestra contenido ya adquirido en web externa.
class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  bool _initialized = false;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get initialized => _initialized;

  /// Inicializar conexión con StoreKit
  /// Solo inicialización, sin flujo de compra
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      debugPrint('IAPService: Inicializando conexión con StoreKit...');
      
      // Verificar disponibilidad
      final available = await _iap.isAvailable();
      if (!available) {
        debugPrint('IAPService: StoreKit no disponible');
        return;
      }

      // Escuchar actualizaciones (aunque no se procesen - solo requisito SDK)
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () {
          _subscription?.cancel();
        },
        onError: (error) {
          debugPrint('IAPService: Error en stream: $error');
        },
      );

      // Cargar productos placeholder (solo para validar configuración)
      const productIds = {'com.fenix.placeholder.product'};
      final response = await _iap.queryProductDetails(productIds);
      
      if (response.error != null) {
        debugPrint('IAPService: Error cargando productos: ${response.error}');
      } else {
        debugPrint('IAPService: Productos IAP cargados (placeholder): ${response.productDetails.length}');
      }

      _initialized = true;
      debugPrint('IAPService: Conexión con StoreKit inicializada.');
    } catch (e) {
      debugPrint('IAPService: Error al inicializar IAP: $e');
    }
  }

  /// Manejar actualizaciones (no se procesan - solo requisito SDK)
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    // No procesar - solo cumplir requisito de SDK para Reader App
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint('IAPService: Actualización detectada (no procesada): ${purchaseDetails.productID}');
    }
  }

  /// Finalizar conexión con StoreKit
  Future<void> endConnection() async {
    if (!_initialized) {
      return;
    }

    try {
      debugPrint('IAPService: Finalizando conexión con StoreKit...');
      await _subscription?.cancel();
      _subscription = null;
      _initialized = false;
      debugPrint('IAPService: Conexión con StoreKit finalizada.');
    } catch (e) {
      debugPrint('IAPService: Error al finalizar IAP: $e');
    }
  }
}

