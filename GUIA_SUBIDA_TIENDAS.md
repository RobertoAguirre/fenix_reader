# 📱 Guía para Subir la App a App Store y Play Store

## 🎯 Estado Actual

- ✅ App funcional y probada
- ✅ IAP SDK inicializado (sin compras reales)
- ✅ Sin WebViews
- ✅ Caché de audio implementado
- ✅ Cumplimiento con Reader App Guidelines
- ⚠️ Bundle ID y Package Name aún en formato de ejemplo

---

## 📋 PASO 1: Preparación Pre-Subida

### 1.1 Cambiar Bundle ID y Package Name

**iOS (Bundle Identifier):**
- Actual: `com.example.fenixReader`
- Debe ser: `com.wendystaufert.fenixreader` (o el que elijas)
- Archivo: `ios/Runner.xcodeproj/project.pbxproj` (buscar `PRODUCT_BUNDLE_IDENTIFIER`)

**Android (Application ID):**
- Actual: `com.example.fenix_reader`
- Debe ser: `com.wendystaufert.fenixreader` (debe coincidir con iOS)
- Archivo: `android/app/build.gradle.kts` (línea `applicationId`)

**⚠️ IMPORTANTE:** Una vez cambiados, NO se pueden modificar después sin crear una nueva app.

### 1.2 Verificar Versión

- Actual: `1.0.0+1` en `pubspec.yaml`
- Incrementar `+1` cada vez que subas un build nuevo
- El formato es: `version: X.Y.Z+BUILD_NUMBER`

### 1.3 Preparar Assets

**Icono de la App:**
- iOS: 1024x1024 px (App Store)
- Android: 512x512 px mínimo
- Colocar en:
  - `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
  - `android/app/src/main/res/mipmap-*/ic_launcher.png`

**Screenshots:**
- iOS: Requiere para iPhone (6.7", 6.5", 5.5") y iPad
- Android: Requiere para teléfono y tablet
- **IMPORTANTE:** NO mostrar precios ni botones de compra

**Descripción de la App:**
- Preparar texto explicando que es una Reader App
- Mencionar que el contenido se adquiere en web externa

---

## 🍎 PASO 2: App Store (Apple) - MÁS ESTRICTO

### 2.1 Requisitos Previos

1. **Cuenta de Desarrollador Apple:**
   - Costo: $99 USD/año
   - Registrarse en: https://developer.apple.com

2. **App Store Connect:**
   - Crear app en: https://appstoreconnect.apple.com
   - Bundle ID debe coincidir exactamente

3. **Certificados y Provisioning Profiles:**
   - Xcode puede generarlos automáticamente
   - O usar: https://developer.apple.com/account/resources/certificates/list

### 2.2 Configuración en Xcode

```bash
# 1. Abrir proyecto iOS
cd ios
open Runner.xcworkspace

# 2. En Xcode:
# - Seleccionar Runner en el navegador
# - Ir a "Signing & Capabilities"
# - Seleccionar tu equipo de desarrollo
# - Marcar "Automatically manage signing"
```

### 2.3 Crear Build para App Store

```bash
# Desde la raíz del proyecto
cd fenix_reader

# 1. Limpiar build anterior
flutter clean

# 2. Obtener dependencias
flutter pub get

# 3. Build para iOS (Release)
flutter build ios --release

# 4. Abrir en Xcode para archivar
open ios/Runner.xcworkspace
```

**En Xcode:**
1. Product → Archive
2. Esperar a que termine
3. Window → Organizer
4. Seleccionar el archive
5. "Distribute App"
6. "App Store Connect"
7. Siguiente → Siguiente → Upload

### 2.4 Configurar en App Store Connect

1. **Información de la App:**
   - Nombre: "Fénix Reader" (o el que elijas)
   - Categoría: "Meditación" o "Estilo de vida"
   - Precio: Gratis

2. **Descripción:**
   ```
   Fénix Reader es una aplicación de visualización de contenido (Reader App) 
   que permite a los usuarios acceder y reproducir contenido de audio y video 
   que han adquirido previamente en el sitio web externo wendystaufert.com.

   La aplicación NO permite realizar compras, suscripciones o pagos. 
   Solo muestra y reproduce el contenido digital que el usuario ya posee 
   después de haberlo adquirido en el sitio web externo.

   Esta aplicación cumple con la Guideline 3.1.3(a) de Apple para Reader Apps.
   ```

3. **Notas para el Revisor (CRÍTICO):**
   ```
   IMPORTANTE: Esta es una Reader App según Guideline 3.1.3(a).

   - El contenido se adquiere EXCLUSIVAMENTE en el sitio web externo wendystaufert.com
   - La app NO tiene funcionalidad de compra
   - La app NO menciona precios ni planes de pago
   - El SDK de IAP está presente solo para cumplir requisitos técnicos
   - NO se usa para transacciones reales

   Si el revisor visita wendystaufert.com, verá que ahí se venden productos.
   Esto es CORRECTO y ESPERADO, ya que la app es solo un visor del contenido
   ya adquirido en ese sitio web externo.

   Para probar la app:
   - Usar una cuenta de prueba con contenido ya adquirido
   - La app mostrará solo el contenido que el usuario ya posee
   - No hay forma de comprar desde la app
   ```

4. **Screenshots:**
   - Subir capturas de pantalla (sin precios)
   - Mínimo requerido: iPhone 6.7" y 6.5"

5. **IAP Products (Placeholder):**
   - Crear un producto placeholder: `com.fenix.placeholder.product`
   - Precio: $0.00 (o el mínimo permitido)
   - Estado: "Listo para enviar" (pero NO se usará)

### 2.5 Enviar para Revisión

1. Completar toda la información
2. Seleccionar "Enviar para revisión"
3. Tiempo estimado: 24-48 horas (puede ser más)

---

## 🤖 PASO 3: Google Play Store - MÁS FLEXIBLE

### 3.1 Requisitos Previos

1. **Cuenta de Desarrollador Google:**
   - Costo: $25 USD (pago único)
   - Registrarse en: https://play.google.com/console

2. **Crear App:**
   - Nombre: "Fénix Reader"
   - Idioma predeterminado: Español
   - Tipo: App
   - Gratis o de pago: Gratis

### 3.2 Configurar Firma de la App

```bash
# 1. Generar keystore (solo la primera vez)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Crear archivo key.properties en android/
# Contenido:
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<ruta al keystore>

# 3. Configurar build.gradle.kts para usar el keystore
```

### 3.3 Crear Build para Play Store

```bash
# Desde la raíz del proyecto
cd fenix_reader

# 1. Limpiar build anterior
flutter clean

# 2. Obtener dependencias
flutter pub get

# 3. Build para Android (Release)
flutter build appbundle --release
# O para APK:
# flutter build apk --release
```

**Archivo generado:**
- `build/app/outputs/bundle/release/app-release.aab` (recomendado)
- O `build/app/outputs/flutter-apk/app-release.apk`

### 3.4 Subir a Play Console

1. **Ir a Play Console:**
   - https://play.google.com/console
   - Seleccionar tu app

2. **Producción → Crear nueva versión:**
   - Subir el archivo `.aab` o `.apk`
   - Agregar notas de la versión

3. **Información de la App:**
   - Descripción corta: "Reproductor de contenido de meditación e hipnosis"
   - Descripción completa: Similar a la de App Store
   - Categoría: "Estilo de vida" o "Salud y bienestar"

4. **Contenido de la App:**
   - Clasificación de contenido: PEGI 3 o similar
   - Política de privacidad: URL requerida

5. **Enviar para revisión:**
   - Tiempo estimado: 1-3 días (puede ser más)

---

## ✅ Checklist Final Antes de Subir

### Código:
- [ ] Bundle ID cambiado (iOS)
- [ ] Package Name cambiado (Android)
- [ ] Versión actualizada
- [ ] Sin referencias a "comprar" o "precio" en textos visibles
- [ ] Sin WebViews
- [ ] IAP SDK inicializado (sin compras reales)

### Assets:
- [ ] Icono de la app preparado
- [ ] Screenshots sin precios
- [ ] Descripción de la app lista
- [ ] Política de privacidad actualizada

### App Store Connect:
- [ ] App creada con Bundle ID correcto
- [ ] Descripción completa
- [ ] Notas para el revisor (CRÍTICO)
- [ ] Screenshots subidos
- [ ] IAP placeholder creado

### Play Console:
- [ ] App creada
- [ ] Keystore configurado
- [ ] Build subido
- [ ] Descripción completa
- [ ] Política de privacidad

---

## 🚨 Posibles Problemas y Soluciones

### Apple Rechaza por "Compras Externas"
**Solución:** Enviar apelación explicando que es Reader App según 3.1.3(a)

### Apple Rechaza por "WebView"
**Solución:** Ya eliminado, no debería pasar

### Apple Rechaza por "IAP no funcional"
**Solución:** Explicar que es placeholder para cumplir requisito técnico

### Google Rechaza por "Contenido"
**Solución:** Ajustar clasificación de contenido

---

## 📞 Contacto con Revisores

Si hay problemas, puedes:
- **Apple:** Responder en App Store Connect → "Appeals"
- **Google:** Respondar en Play Console → "Policy"

---

## 🎯 Próximos Pasos

1. Cambiar Bundle ID y Package Name
2. Preparar assets (iconos, screenshots)
3. Crear cuentas de desarrollador (si no las tienes)
4. Crear builds de release
5. Subir a las tiendas
6. Esperar aprobación

**Tiempo estimado total:** 1-2 semanas (dependiendo de aprobaciones)

---

## 📚 Recursos Útiles

- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play Policy](https://play.google.com/about/developer-content-policy/)
- [Flutter Build Documentation](https://docs.flutter.dev/deployment)

