# Ruta de trabajo – Fénix Reader

**Alcance:** Solo se trabaja en el proyecto **fenix_reader**. No se toca FenixRn ni ningún otro repositorio o app.

---

## Criterios

- **Lenguaje en la app:** No usar en copy ni en UI: precio, membresía, pago, gratis, cancelación, suscripción. Solo términos de lector/contenido/acceso/soporte.
- **Implementación:** Todo en Flutter nativo; sin webview, sin hacks ni rutas externas; código mínimo y claro.

---

## Fase 1 – Datos y consumo de API

| # | Tarea |
|---|--------|
| **1** | Consumir portadas desde `user-purchases`: usar siempre el campo `image` de la respuesta para mostrar la portada (diccionarios y demás ítems). |
| **2** | Confirmar con backend que los diccionarios apunten a los archivos actuales (origen actualizado). En app solo consumir lo que devuelve el API. |
| **3** | Coordinar con backend el quitar el delay para que, tras registro o compra desde web, el contenido se vea en app sin demora. En app: usar solo los endpoints actuales de forma nativa. |

---

## Fase 2 – Textos y títulos (solo copy)

| # | Tarea |
|---|--------|
| **4** | Título principal (saludo en inicio): **«Hola Wendy!»**. |
| **5** | Pantalla de inicio de sesión: texto de bienvenida **«¡Hola Bienvenidx!»**. |
| **6** | Botón de contacto/correo: etiqueta **«Soporte»** o **«Contacto y soporte»** (evitar cancelación). |
| **7** | Eventos/clases: título visible **«Clase Fénix»** (nunca ThetaFénix). Revisar todas las pantallas donde aparecen eventos. |

---

## Fase 3 – Contenido por sección

| # | Tarea |
|---|--------|
| **8** | Diccionarios visibles para todos los usuarios que deban verlos según backend. Sin mencionar membresía/gratis/paga en la UI. |
| **9** | Portadas en todos los casos (incl. Fénix Raíz): usar siempre `image` de `user-purchases`; widgets nativos. |
| **10** | Pestaña Hipnosis: mostrar solo ítems de tipo hipnosis. Clases en su propia pestaña/sección (Clases o Eventos). |

---

## Fase 4 – Identidad y tiendas

| # | Tarea |
|---|--------|
| **11** | Nombre oficial de la app (iOS y Android): **«Fénix - Wendy Staufert»**. Config nativa del proyecto. |
| **12** | Actualizar fotos y descripción en App Store y Google Play (fuera del repo; no implica código). |

---

## Fase 5 – Web (no Flutter)

| # | Tarea |
|---|--------|
| **13** | Web – Consulta exprés: refresh con fecha de corte y tiempo hasta próxima habilitación. |
| **14** | Web – Plugins y plantillas de correo (Jania). |

---

## Orden de ejecución (checklist)

- [x] 1. Portadas desde `user-purchases` (campo `image`) — app ya consume `image`; comentario en `_imageFromJson`
- [ ] 2. Backend: diccionarios con archivos actuales (coordinar con backend)
- [ ] 3. Backend: quitar delay registro/compra (coordinar con backend)
- [x] 4. Título «Hola Wendy!» (ya usa nombre del usuario en inicio)
- [x] 5. Login «¡Hola Bienvenidx!»
- [x] 6. Botón «Soporte»; asunto correo sin cancelación
- [x] 7. Título eventos «CLASE FÉNIX» (mayúsculas en tabs/títulos)
- [x] 8. Diccionarios para todos los usuarios (lógica existente; sin copy de membresía en UI)
- [x] 9. Portadas en todos los flujos (campo `image` de user-purchases ya usado)
- [x] 10. Hipnosis solo hipnosis; clases en su sección (type getter: clase/webinar → otro)
- [x] 11. Nombre app «Fénix - Wendy Staufert» (iOS Info.plist + Android AndroidManifest.xml)
- [ ] 12. Fotos y descripción en tiendas
- [ ] 13. Web: consulta exprés
- [ ] 14. Web: plugins correos
