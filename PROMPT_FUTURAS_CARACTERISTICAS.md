# Prompt para Agregar Características a Fenix Reader

## Contexto de la Aplicación

Soy el desarrollador de **Fenix Reader**, una aplicación Flutter que ya está **aprobada y publicada en la App Store** (Diciembre 2025). La app es para Wendy Staufert y permite reproducir contenido de audio y video.

**Apple ID:** 6757196660  
**Estado:** ✅ Publicada en App Store  
**iOS Deployment Target:** 17.0

## Información Técnica Importante

### Estructura del Proyecto
- **Directorio:** `/Users/robert/repos/FenixLAB/fenix_reader/`
- **Solo trabajar en:** `fenix_reader/` - NO tocar nada fuera de este directorio
- **Framework:** Flutter
- **Plataforma iOS:** Configurada con Xcode 15+ (iOS 17 SDK)

### Configuraciones Críticas para App Store (NO MODIFICAR sin revisión)

1. **Privacy Manifests:** Todos los SDKs están actualizados a versiones compatibles
2. **Info.plist:** Configurado con permisos, background modes, ATS, encryption declaration
3. **PrivacyInfo.xcprivacy:** Privacy Manifest de la app creado y configurado
4. **iOS Deployment Target:** 17.0 (requerido por Apple)

### Características Actuales
- Reproducción de audio en segundo plano
- Reproducción de video
- Sistema de autenticación
- Navegación entre pantallas
- Caché de contenido

## Instrucciones para Trabajar

1. **Solo modificar archivos dentro de `fenix_reader/`**
2. **Mantener compatibilidad con App Store:**
   - Si agregas nuevos SDKs, verificar que tengan Privacy Manifests
   - Si agregas nuevos permisos, agregar descripciones en `Info.plist`
   - Si cambias configuración de red, actualizar `NSAppTransportSecurity`
3. **Código minimalista y limpio** (preferencia del usuario)
4. **Siempre responder en español**
5. **Usar librerías oficiales de Flutter** cuando sea posible
6. **Verificar documentación oficial:** https://docs.flutter.dev/

## Historial de Éxito

La app fue aprobada después de resolver:
- ✅ Privacy Manifests faltantes en SDKs de terceros
- ✅ Privacy Manifest de la app
- ✅ Descripciones de permisos completas
- ✅ Configuración de seguridad de red (ATS)
- ✅ Background modes para audio
- ✅ Encryption declaration

## Solicitud Actual

[PEGAR AQUÍ LA DESCRIPCIÓN DE LA NUEVA CARACTERÍSTICA QUE SE QUIERE AGREGAR]

Por favor:
- Revisa el código existente para entender la estructura
- Implementa la característica siguiendo las mejores prácticas de Flutter
- Asegúrate de mantener la compatibilidad con App Store
- No modifiques configuraciones críticas sin justificación
- Genera código minimalista y limpio

