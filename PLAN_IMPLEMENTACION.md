# 🚀 Plan de Implementación: Migración de Funcionalidades FenixRn → fenix_reader

## 📋 Principios
- ✅ **NO cambiar apariencia** a menos que sea necesario
- ✅ **Mantener optimizaciones** de fenix_reader (cached_network_image, shimmer, Provider)
- ✅ **Basarse en FenixRn** para funcionalidades
- ✅ **Implementar en orden lógico** respetando dependencias

---

## 📦 FASE 1: INFRAESTRUCTURA Y ENDPOINTS (Base)

### 1.1. Expandir WordPressService con todos los endpoints
**Prioridad**: 🔴 CRÍTICA  
**Dependencias**: Ninguna  
**Tiempo estimado**: 8-12 horas

**Tareas**:
- [ ] Agregar método `getUserMeditaciones(String email)`
- [ ] Agregar método `getUserHipnosis(String email)`
- [ ] Agregar método `getUserHipnosisMembresia(String email)`
- [ ] Agregar método `getPublicMeditaciones()`
- [ ] Agregar método `getPublicHipnosis()`
- [ ] Agregar método `getUserMemberships(String email)` - Niveles de acceso activos
- [ ] Agregar método `getAllMemberships()` - Todos los niveles disponibles
- [ ] Agregar método `getWooProducts()`
- [ ] Agregar método `getWooProductDetails(int productId)`
- [ ] Agregar método `getTutorCourses()` - Programas Tutor LMS
- [ ] Agregar método `getTutorCourseDetails(int courseId)`
- [ ] Agregar método `checkUserEnrollment(String email, int courseId)` - Verificar inscripción
- [ ] Agregar método `getThetaFenixSessions()`
- [ ] Agregar método `getSanacionContent({String? slug})`
- [ ] Agregar método `getTratamientoContent()`
- [ ] Agregar método `getNumerologiaContent()`
- [ ] Agregar método `checkProgramPurchase(String email, String programType)`

**Notas**:
- Mantener estructura actual de `WordPressService`
- Usar `http` package (ya instalado)
- Agregar manejo de errores consistente
- Usar `debugPrint` para logging (como actualmente)

---

### 1.2. Implementar Caché de API (adoptar de FenixRn)
**Prioridad**: 🟡 IMPORTANTE  
**Dependencias**: 1.1 (endpoints)  
**Tiempo estimado**: 6-8 horas

**Tareas**:
- [ ] Instalar `shared_preferences` (para caché no sensible)
- [ ] Crear `CacheService` con métodos:
  - `saveCachedPurchases(String email, List data)`
  - `getCachedPurchases(String email)`
  - `isPurchasesCacheValid(String email, int minutes)`
  - `clearPurchasesCache(String email)`
  - Similar para membresías, inscripciones, etc.
- [ ] Integrar caché en `WordPressService`:
  - Verificar caché antes de hacer petición
  - Guardar respuesta en caché
  - Validar expiración (10 min para compras, 60 min para membresías)
- [ ] Agregar flag `forceRefresh` en métodos de `WordPressService`

**Notas**:
- Usar `shared_preferences` para caché (no `flutter_secure_storage` - no es sensible)
- Mantener `flutter_secure_storage` solo para tokens y datos sensibles
- Implementar validación de timestamps

---

### 1.3. Implementar Retry con Backoff Exponencial
**Prioridad**: 🟡 IMPORTANTE  
**Dependencias**: 1.1 (endpoints)  
**Tiempo estimado**: 4-6 horas

**Tareas**:
- [ ] Crear función `retryWithBackoff` en `WordPressService`:
  - Máximo 3 intentos
  - Backoff: 1s, 2s, 4s
  - Manejar timeouts y errores de red
- [ ] Aplicar a todos los métodos de `WordPressService`
- [ ] Agregar timeouts configurables:
  - `API_TIMEOUTS.NORMAL = 10s`
  - `API_TIMEOUTS.SLOW = 30s`

**Notas**:
- Usar `Future.delayed` para backoff
- Manejar `TimeoutException` y `SocketException`
- Logging de reintentos

---

### 1.4. Implementar Rate Limiting
**Prioridad**: 🟢 DESEABLE  
**Dependencias**: 1.2 (caché)  
**Tiempo estimado**: 3-4 horas

**Tareas**:
- [ ] Crear `RateLimitService`:
  - Tracking de peticiones por tipo (purchases, memberships, etc.)
  - Límite: máximo 5 peticiones por minuto por tipo
  - Usar `shared_preferences` para tracking
- [ ] Integrar en `WordPressService`:
  - Verificar rate limit antes de petición
  - Si excede, usar caché si está disponible
  - Retornar error si no hay caché

**Notas**:
- Prevenir spam de peticiones
- Proteger servidor WordPress
- Mejorar rendimiento

---

## 📦 FASE 2: MODELOS Y PROVIDERS (Datos)

### 2.1. Expandir Modelos de Datos
**Prioridad**: 🔴 CRÍTICA  
**Dependencias**: 1.1 (endpoints)  
**Tiempo estimado**: 4-6 horas

**Tareas**:
- [ ] Crear `Membership` model:
  - `id`, `name`, `description`, `type` (Raíz, Conexión, Despertar, Maestría)
  - `features`, `image`, `permalink`
- [ ] Crear `Program` model (Tutor LMS):
  - `id`, `title`, `description`, `image`
  - `topics`, `lessons`, `enrollmentStatus`
- [ ] Crear `Lesson` model:
  - `id`, `title`, `videoUrl`, `duration`, `isLocked`
- [ ] Crear `ThetaSession` model
- [ ] Crear `SanacionContent` model
- [ ] Crear `TratamientoOption` model
- [ ] Expandir `ContentItem` si es necesario (agregar campos faltantes)

**Notas**:
- Mantener estructura similar a modelos actuales
- Usar `fromJson` factories
- Validar campos opcionales

---

### 2.2. Crear Providers Adicionales
**Prioridad**: 🔴 CRÍTICA  
**Dependencias**: 2.1 (modelos), 1.1 (endpoints)  
**Tiempo estimado**: 6-8 horas

**Tareas**:
- [ ] Crear `MembershipProvider`:
  - `List<Membership> activeMemberships`
  - `List<Membership> allMemberships`
  - `loadUserMemberships(String email)`
  - `loadAllMemberships()`
- [ ] Crear `ProgramProvider`:
  - `List<Program> programs`
  - `loadPrograms()`
  - `loadProgramDetails(int courseId)`
  - `checkEnrollment(String email, int courseId)`
- [ ] Crear `ContentProvider` expandido (o extender actual):
  - Agregar métodos para meditaciones/hipnosis específicas
  - Agregar métodos para contenido público
  - Agregar filtrado por acceso (comprado/membresía)

**Notas**:
- Mantener patrón Provider actual
- Usar `ChangeNotifier`
- Manejar estados de loading y error

---

## 📦 FASE 3: ALMACENAMIENTO Y SEGURIDAD

### 3.1. Favoritos Persistentes
**Prioridad**: 🔴 CRÍTICA  
**Dependencias**: Ninguna  
**Tiempo estimado**: 3-4 horas

**Tareas**:
- [ ] Crear `FavoritesService`:
  - Usar `flutter_secure_storage` (ya instalado)
  - `saveFavorites(List<int> favoriteIds)`
  - `getFavorites() -> List<int>`
  - `toggleFavorite(int itemId)`
- [ ] Integrar en `LibraryScreen`:
  - Cargar favoritos al iniciar
  - Guardar al cambiar
  - Mostrar estado de favorito

**Notas**:
- Usar `flutter_secure_storage` (más seguro que `shared_preferences`)
- Mantener lista de IDs (no objetos completos)
- Sincronizar con `ContentProvider` si es necesario

---

### 3.2. IAP SDK (In-App Purchase)
**Prioridad**: 🔴 CRÍTICA (para App Store)  
**Dependencias**: Ninguna  
**Tiempo estimado**: 4-6 horas

**Tareas**:
- [ ] Instalar `in_app_purchase` package
- [ ] Crear `IAPService`:
  - `initialize()` - Inicializar conexión con StoreKit
  - `endConnection()` - Cerrar conexión
  - `getProducts(List<String> productIds)` - Cargar productos (placeholder)
- [ ] Integrar en `main.dart`:
  - Inicializar al iniciar app
  - Cerrar al salir
- [ ] Configurar productos en App Store Connect (solo placeholder, sin precios)

**Notas**:
- **NO implementar flujo de compra real**
- Solo inicialización para cumplir requisito de Apple
- Similar a implementación en FenixRn
- Agregar comentarios claros indicando que NO se usa para cobros

---

## 📦 FASE 4: REPRODUCTORES (Media)

### 4.1. Reproductor de Audio
**Prioridad**: 🔴 CRÍTICA  
**Dependencias**: 2.2 (providers)  
**Tiempo estimado**: 10-14 horas

**Tareas**:
- [ ] Usar `just_audio` (ya instalado)
- [ ] Crear `AudioPlayerService`:
  - `play(String url)`
  - `pause()`, `stop()`
  - `seek(Duration position)`
  - `getDuration()`, `getPosition()`
  - Streams para posición y estado
- [ ] Crear `AudioPlayerModal` widget:
  - Barra de progreso
  - Controles (play/pause, forward/backward)
  - Título y duración
  - Verificación de membresía (si aplica)
  - Descarga y almacenamiento local (opcional)
- [ ] Integrar en pantallas que lo necesiten

**Notas**:
- Usar `just_audio` (ya instalado, mejor que `audioplayers`)
- Implementar background playback con `audio_service` (ya instalado)
- Manejar permisos de almacenamiento si se descarga

---

### 4.2. Reproductor de Video
**Prioridad**: 🔴 CRÍTICA  
**Dependencias**: 2.2 (providers)  
**Tiempo estimado**: 8-12 horas

**Tareas**:
- [ ] Usar `video_player` y `chewie` (ya instalados)
- [ ] Crear `VideoPlayerService` (opcional, si se necesita lógica compleja)
- [ ] Crear `VideoPlayerModal` widget:
  - Usar `Chewie` para controles
  - Descarga temporal de video (opcional)
  - Limpieza al cerrar
- [ ] Integrar en pantallas que lo necesiten

**Notas**:
- `video_player` y `chewie` ya instalados
- Manejar descarga temporal si es necesario
- Limpiar archivos al cerrar modal

---

### 4.3. Integración Vimeo
**Prioridad**: 🟡 IMPORTANTE  
**Dependencias**: 4.2 (reproductor video)  
**Tiempo estimado**: 6-8 horas

**Tareas**:
- [ ] Instalar `webview_flutter` (si no está)
- [ ] Crear `VimeoPlayer` widget:
  - WebView con embed de Vimeo
  - HTML personalizado para player
  - Manejo de eventos (fin de video, etc.)
- [ ] Integrar en `ProgramProvider` para lecciones

**Notas**:
- Similar a implementación en FenixRn
- Usar WebView para embed de Vimeo
- Manejar diferentes formatos de URL de Vimeo

---

## 📦 FASE 5: PANTALLAS Y UI

### 5.1. Pantallas de Contenido Específico
**Prioridad**: 🔴 CRÍTICA  
**Dependencias**: 2.2 (providers), 4.1 (audio), 4.2 (video)  
**Tiempo estimado**: 12-16 horas

**Tareas**:
- [ ] Crear `HipnosisFenixScreen`:
  - Grid de productos con `cached_network_image`
  - Búsqueda (implementar en 5.2)
  - Video introductorio embebido
  - Filtrado por acceso
  - Integrar reproductor de audio/video
- [ ] Crear `MeditacionesFenixScreen`:
  - Similar a HipnosisFenixScreen
  - Grid de productos
  - Búsqueda
  - Video introductorio
- [ ] Actualizar `PortalScreen`:
  - Integrar nuevas pantallas en tabs
  - Mantener apariencia actual

**Notas**:
- **NO cambiar apariencia** de pantallas existentes
- Usar widgets existentes (`ContentFeatureCard`, etc.)
- Mantener branding (colores, tipografía)

---

### 5.2. Búsqueda y Filtrado
**Prioridad**: 🟡 IMPORTANTE  
**Dependencias**: 5.1 (pantallas)  
**Tiempo estimado**: 4-6 horas

**Tareas**:
- [ ] Crear `SearchBar` widget:
  - Campo de texto con debouncing
  - Botón de limpiar
  - Estilo consistente con branding
- [ ] Implementar búsqueda en tiempo real:
  - Filtrar lista local (no petición a API)
  - Debounce de 300ms
- [ ] Implementar filtrado:
  - Por tipo (Hipnosis/Meditación)
  - Por acceso (Comprado/Membresía/Público)

**Notas**:
- Usar `TextField` con `onChanged`
- Implementar debouncing con `Timer`
- Filtrar lista local (mejor rendimiento)

---

### 5.3. Pantallas de Servicios
**Prioridad**: 🟡 IMPORTANTE  
**Dependencias**: 2.2 (providers), 4.3 (Vimeo)  
**Tiempo estimado**: 20-28 horas

**Tareas**:
- [ ] Crear `ProgramasScreen`:
  - Lista de programas (Riqueza, Amor Propio)
  - Modal con detalle de programa
  - Lista de lecciones por tema
  - Reproductor Vimeo integrado
  - Verificación de inscripción
- [ ] Crear `ThetaFenixScreen`:
  - Lista de sesiones
  - Calendario de fechas
  - Enlaces a web
- [ ] Crear `SanacionScreen`:
  - Contenido HTML dinámico
  - Cards de información
  - Enlaces a web
- [ ] Crear `SanacionNinosScreen` (similar a SanacionScreen)
- [ ] Crear `TratamientoScreen`:
  - Video embebido
  - Cards de opciones
  - Lista de espera
- [ ] Crear `NumerologiaScreen`:
  - Cards de información
  - Enlaces a web

**Notas**:
- Usar `html` package para parsing HTML si es necesario
- Mantener estilo consistente
- Usar `url_launcher` para enlaces externos (ya instalado)

---

### 5.4. Pantallas de Usuario
**Prioridad**: 🟡 IMPORTANTE  
**Dependencias**: 2.2 (providers)  
**Tiempo estimado**: 8-12 horas

**Tareas**:
- [ ] Crear `UserMembresiaScreen`:
  - Mostrar nivel activo del usuario
  - Lista de niveles disponibles
  - Agrupación por tipo (Raíz, Conexión, Despertar, Maestría)
  - Enlaces a web para ver detalles
  - **NO mostrar precios** (solo "Ver en la web")
- [ ] Crear `SesionesScreen` (si es necesario)
- [ ] Crear `ClasesScreen` (si es necesario)
- [ ] Crear `CalendarioScreen` (si es necesario)
- [ ] Crear `TerminosCondicionesScreen`

**Notas**:
- **CRÍTICO**: NO mencionar precios, compras, membresías
- Usar "niveles de acceso" en lugar de "membresías"
- Usar "Ver en la web" en lugar de "Comprar"

---

### 5.5. Pantalla de Registro
**Prioridad**: 🟢 DESEABLE  
**Dependencias**: 1.1 (endpoints)  
**Tiempo estimado**: 4-6 horas

**Tareas**:
- [ ] Crear `RegisterScreen`:
  - Formulario de registro
  - Campos: email, password, confirm password
  - Validación
  - Integrar con WordPress API (si existe endpoint)

**Notas**:
- Verificar si existe endpoint de registro en WordPress
- Mantener estilo de `LoginScreen`

---

## 📦 FASE 6: FUNCIONALIDADES AVANZADAS

### 6.1. Gestión de Acceso por Contenido
**Prioridad**: 🟡 IMPORTANTE  
**Dependencias**: 2.2 (providers), 3.1 (favoritos)  
**Tiempo estimado**: 6-8 horas

**Tareas**:
- [ ] Crear `AccessService`:
  - `hasAccessToContent(ContentItem item, List<Membership> memberships)`
  - Verificar si usuario tiene acceso por:
    - Compra directa
    - Nivel de acceso activo
    - Contenido público
- [ ] Integrar en pantallas:
  - Mostrar/ocultar botones según acceso
  - Bloquear/desbloquear contenido
  - Mostrar indicadores de acceso

**Notas**:
- Lógica similar a FenixRn
- Verificar múltiples fuentes de acceso
- Mantener UX clara

---

### 6.2. Notificaciones Push (OneSignal)
**Prioridad**: 🟢 DESEABLE  
**Dependencias**: Ninguna  
**Tiempo estimado**: 8-12 horas

**Tareas**:
- [ ] Instalar `onesignal_flutter`
- [ ] Crear `NotificationService`:
  - `initialize()`
  - `requestPermissions()`
  - `setUserTags()`
  - Manejo de notificaciones
- [ ] Integrar en `main.dart`

**Notas**:
- Similar a implementación en FenixRn
- Configurar en OneSignal dashboard
- Manejar permisos de iOS/Android

---

### 6.3. Limpieza de Archivos
**Prioridad**: 🟢 DESEABLE  
**Dependencias**: 4.1 (audio), 4.2 (video)  
**Tiempo estimado**: 4-6 horas

**Tareas**:
- [ ] Crear `MediaCleanupService`:
  - Tracking de archivos descargados
  - Limpieza automática de archivos antiguos (>7 días sin usar)
  - Gestión de espacio en disco
- [ ] Integrar en reproductores:
  - Registrar archivos al descargar
  - Limpiar al cerrar modal
  - Limpieza periódica

**Notas**:
- Usar `path_provider` para rutas
- Implementar tracking con `shared_preferences`
- Limpiar archivos temporales

---

## 📦 FASE 7: OPTIMIZACIONES FINALES

### 7.1. Cloudinary Integration (Migración de Google Drive)
**Prioridad**: 🟢 DESEABLE (pero importante para rendimiento)  
**Dependencias**: Todas las pantallas  
**Tiempo estimado**: 8-12 horas

**Tareas**:
- [ ] Configurar Cloudinary:
  - Crear cuenta y obtener credenciales
  - Configurar transformaciones
- [ ] Crear `CloudinaryService`:
  - Transformar URLs de Google Drive a Cloudinary
  - Aplicar transformaciones (resize, quality, format)
- [ ] Migrar URLs en modelos:
  - Actualizar `ContentItem.image`
  - Actualizar URLs de audio/video
- [ ] Actualizar `cached_network_image`:
  - Usar URLs de Cloudinary
  - Aprovechar transformaciones

**Notas**:
- **Ventaja futura**: Mejor rendimiento que Google Drive
- CDN global
- Optimización automática

---

### 7.2. Optimizaciones de Flutter
**Prioridad**: 🟢 DESEABLE  
**Dependencias**: Todas las pantallas  
**Tiempo estimado**: 4-6 horas

**Tareas**:
- [ ] Agregar `const` constructors donde sea posible
- [ ] Implementar `RepaintBoundary` en widgets complejos
- [ ] Usar `AutomaticKeepAliveClientMixin` en tabs
- [ ] Implementar `SliverList` para listas grandes
- [ ] Optimizar rebuilds con `Consumer` selectivo

**Notas**:
- Mejorar rendimiento de scroll
- Reducir rebuilds innecesarios
- Optimizar uso de memoria

---

## 📊 RESUMEN DE FASES

| Fase | Descripción | Prioridad | Tiempo Estimado |
|------|-------------|-----------|----------------|
| **1** | Infraestructura y Endpoints | 🔴 CRÍTICA | 21-30 horas |
| **2** | Modelos y Providers | 🔴 CRÍTICA | 10-14 horas |
| **3** | Almacenamiento y Seguridad | 🔴 CRÍTICA | 7-10 horas |
| **4** | Reproductores | 🔴 CRÍTICA | 24-34 horas |
| **5** | Pantallas y UI | 🔴 CRÍTICA / 🟡 IMPORTANTE | 48-68 horas |
| **6** | Funcionalidades Avanzadas | 🟡 IMPORTANTE / 🟢 DESEABLE | 18-26 horas |
| **7** | Optimizaciones Finales | 🟢 DESEABLE | 12-18 horas |

**TOTAL**: ~140-190 horas de desarrollo

---

## 🎯 ORDEN DE IMPLEMENTACIÓN RECOMENDADO

### Sprint 1 (Infraestructura Base) - 2-3 semanas
1. Fase 1.1: Expandir WordPressService (endpoints)
2. Fase 1.2: Implementar Caché de API
3. Fase 1.3: Implementar Retry con Backoff
4. Fase 2.1: Expandir Modelos de Datos
5. Fase 2.2: Crear Providers Adicionales

### Sprint 2 (Funcionalidades Core) - 2 semanas
6. Fase 3.1: Favoritos Persistentes
7. Fase 3.2: IAP SDK
8. Fase 4.1: Reproductor de Audio
9. Fase 4.2: Reproductor de Video

### Sprint 3 (Pantallas Principales) - 3 semanas
10. Fase 5.1: Pantallas de Contenido Específico
11. Fase 5.2: Búsqueda y Filtrado
12. Fase 5.4: Pantallas de Usuario (UserMembresia)

### Sprint 4 (Funcionalidades Completas) - 2-3 semanas
13. Fase 4.3: Integración Vimeo
14. Fase 5.3: Pantallas de Servicios
15. Fase 6.1: Gestión de Acceso por Contenido

### Sprint 5 (Optimizaciones) - 1-2 semanas
16. Fase 6.2: Notificaciones Push (opcional)
17. Fase 6.3: Limpieza de Archivos (opcional)
18. Fase 7.1: Cloudinary Integration
19. Fase 7.2: Optimizaciones de Flutter

---

## ⚠️ NOTAS IMPORTANTES

### Restricciones App Store (aplicar en TODAS las fases):
- ❌ **NO mencionar**: precios, compras, suscripciones, membresías, planes, pagos
- ✅ **Usar**: "niveles de acceso" en lugar de "membresías"
- ✅ **Usar**: "Ver en la web" en lugar de "Comprar"
- ✅ **IAP SDK**: Solo inicialización, NO flujo de compra

### Mantener de fenix_reader:
- ✅ `cached_network_image` (no cambiar)
- ✅ Shimmer effects (no cambiar)
- ✅ Provider pattern (no cambiar)
- ✅ `flutter_secure_storage` (no cambiar)
- ✅ Google Fonts (no cambiar)
- ✅ Branding (colores, tipografía)

### Basarse en FenixRn:
- 📋 Lógica de negocio
- 📋 Estructura de endpoints
- 📋 Flujos de usuario
- 📋 Verificación de acceso

---

**Última actualización**: Diciembre 2024  
**Versión**: 1.0

