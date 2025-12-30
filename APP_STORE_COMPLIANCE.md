# 📱 Cumplimiento App Store - Reader App Guidelines

## ⚠️ SITUACIÓN CRÍTICA

Apple ha revisado el sitio web https://wendystaufert.com y ha detectado que ahí se venden productos. Esto es **NORMAL** porque:
- El sitio web es donde los usuarios **adquieren** el contenido
- La app es **SOLO un visor/reproductor** del contenido ya adquirido
- La app **NO permite compras** ni menciona precios

## 📋 Lineamientos de Apple para Reader Apps (Guideline 3.1.3(a))

Según los lineamientos actualizados de Apple (diciembre 2025):

### ✅ Requisitos para Reader Apps:

1. **Solo visualización de contenido ya adquirido**
   - La app NO debe tener botones de compra
   - La app NO debe mencionar precios
   - La app NO debe tener enlaces a páginas de compra

2. **Clasificación como Reader App**
   - Contenido digital: audio, música, video, libros
   - Funcionalidad principal: reproducir/mostrar contenido
   - NO es una tienda, es un visor

3. **External Link Account Entitlement (Opcional)**
   - Solo para creación/gestión de cuentas
   - NO para compras
   - Requiere solicitud especial a Apple

4. **IAP SDK debe estar presente**
   - Inicializado (ya implementado)
   - NO usado para cobros reales
   - Solo para cumplir requisito técnico

## 🚫 PROHIBICIONES ABSOLUTAS en la App

### ❌ NUNCA incluir:
- Botones de "Comprar", "Adquirir", "Suscribirse"
- Enlaces a páginas de compra del sitio web
- Menciones de precios, costos, planes de pago
- Textos como "Membresía de pago", "Plan premium"
- Referencias a "comprar contenido en la app"
- Carritos de compra o checkout

### ✅ PERMITIDO:
- "Ver en la web" (para información, NO para compra)
- "Nivel de acceso" (en lugar de "membresía de pago")
- "Contenido disponible" (en lugar de "comprar")
- "Tu biblioteca" (contenido ya adquirido)
- "Iniciar sesión" (para acceder a contenido ya adquirido)

## 📝 Mensaje para Apple en la Revisión

### Descripción de la App:
```
"Fénix Reader es una aplicación de visualización de contenido (Reader App) 
que permite a los usuarios acceder y reproducir contenido de audio y video 
que han adquirido previamente en el sitio web externo wendystaufert.com.

La aplicación NO permite realizar compras, suscripciones o pagos. 
Solo muestra y reproduce el contenido digital que el usuario ya posee 
después de haberlo adquirido en el sitio web externo.

Esta aplicación cumple con la Guideline 3.1.3(a) de Apple para Reader Apps."
```

### Notas para el Revisor:
```
IMPORTANTE: Esta es una Reader App según Guideline 3.1.3(a).

- El contenido se adquiere EXCLUSIVAMENTE en el sitio web externo
- La app NO tiene funcionalidad de compra
- La app NO menciona precios ni planes de pago
- El SDK de IAP está presente solo para cumplir requisitos técnicos
- NO se usa para transacciones reales

Si el revisor visita wendystaufert.com, verá que ahí se venden productos.
Esto es CORRECTO y ESPERADO, ya que la app es solo un visor del contenido
ya adquirido en ese sitio web externo.
```

## 🔍 Checklist de Cumplimiento

### Código:
- [x] IAP SDK inicializado (sin flujo de compra)
- [x] Sin WebView (eliminado)
- [x] Sin botones de compra en UI
- [x] Sin enlaces a páginas de compra
- [ ] Revisar TODOS los textos visibles al usuario
- [ ] Asegurar que "membresía" se refiera a "nivel de acceso"
- [ ] Eliminar cualquier referencia a "comprar" o "precio"

### UI/Textos:
- [ ] Revisar `library_screen.dart` - textos visibles
- [ ] Revisar `portal_screen.dart` - textos visibles
- [ ] Revisar `home_screen.dart` - textos visibles
- [ ] Revisar `profile_screen.dart` - textos visibles
- [ ] Revisar todos los widgets - textos visibles

### Documentación:
- [ ] Descripción en App Store Connect
- [ ] Capturas de pantalla (sin precios)
- [ ] Notas para el revisor
- [ ] Política de privacidad actualizada

## 🎯 Acciones Inmediatas Requeridas

1. **Revisar TODOS los textos visibles** en la app
2. **Reemplazar términos problemáticos**:
   - "Membresía de pago" → "Nivel de acceso"
   - "Comprar" → "Ver en la web" o eliminar
   - "Precio" → Eliminar completamente
   - "Suscripción" → "Acceso" o eliminar

3. **Asegurar que NO haya enlaces** a:
   - Páginas de compra
   - Carritos de compra
   - Checkout
   - Páginas de membresías con precios

4. **Preparar documentación clara** para Apple explicando:
   - Que es una Reader App
   - Que el contenido se compra en web externa
   - Que la app solo visualiza contenido ya adquirido

## 📚 Referencias

- [Apple Reader Apps Guidelines](https://developer.apple.com/support/reader-apps/)
- [App Store Review Guidelines 3.1.3(a)](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)
- [External Link Account Entitlement](https://developer.apple.com/documentation/storekit/external-purchase-link-entitlement)

