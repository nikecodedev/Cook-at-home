# Guía de verificación – Fase 2 (Cliente)

Use esta guía para comprobar cada función en la app y saber qué depende del backend/web.

---

## 1. Generar lista de compras (app – corregido)

**Qué verificar:** Desde una receta o desde el Plan Semanal, pulsar **Generar Lista de Compras**.

**Comportamiento esperado:**
- Siempre se crea una lista (nunca aparece “Todos los ingredientes ya están en tu despensa” como error que bloquea).
- Si faltan ingredientes: la lista contiene solo los que faltan.
- Si todo está en despensa: la lista contiene todos los ingredientes de la receta como checklist.

**Si falla:** Revisar que el usuario tenga permisos y que Firestore esté bien configurado.

---

## 2. Enlaces de tienda (Amazon / Walmart) (app – corregido)

**Qué verificar:** En Lista de compras o en receta, pulsar un botón de compra (Amazon/Walmart).

**Comportamiento esperado:**
- Si el enlace guardado es válido (amazon.com, walmart.com, etc.): se abre en el navegador/app externa.
- Si el enlace está vacío o es un enlace de compartir receta (cocinaentucasa.com/recipe/...): no se abre; se muestra un mensaje para agregar un enlace de tienda real.

**Si aparece “Sin Internet”:** Comprobar que el enlace guardado sea realmente de Amazon/Walmart (no de la app). Si es correcto, puede ser un tema de conectividad del dispositivo.

---

## 3. Alertas de reabastecimiento (app – corregido)

**Qué verificar:** En Mi Despensa, sección **Alertas de Reabastecimiento**.

**Comportamiento esperado:**
- Mientras cargan las alertas: se muestra un esqueleto de carga (no un bloque en blanco).
- Con datos: se muestran las alertas o el texto “No hay alertas en este momento”.

**Si falla:** Revisar que el usuario esté logueado y que Firestore tenga la colección de refill alerts configurada.

---

## 4. Imagen de receta (app + backend)

**Qué verificar:** Crear o editar una receta, subir una foto, guardar. Ver la receta en lista, detalle y edición.

**Comportamiento esperado en la app:**
- La app sube la imagen a Firebase Storage y guarda la URL en el documento de la receta en Firestore.
- En lista, detalle y edición se usa esa URL para mostrar la imagen (o placeholder si no hay URL).

**Si la imagen no se ve:**
1. **En la app:** Comprobar que Firebase Storage esté inicializado y que las reglas permitan **lectura** (y escritura para subir) en la ruta de recetas (p. ej. `recipes/{recipeId}/*`). Sin lectura pública (o para usuarios autenticados), la URL devuelta por Storage no cargará.
2. **CORS (solo web):** Si la app es web, el bucket de Storage debe tener CORS configurado para tu dominio.

**Resumen:** La lógica de subida y guardado de URL está en la app; que la imagen se vea depende de reglas de Storage (y CORS en web).

---

## 5. Compartir receta – Copiar enlace (app + web)

**Qué verificar:** En detalle de receta, pulsar **Copiar enlace**.

**Comportamiento esperado en la app:**
- Se copia al portapapeles: `https://cocinaentucasa.com/recipe/{id}`.
- Se muestra un mensaje de éxito indicando que el enlace abrirá la receta cuando la página web esté publicada.

**Si al abrir el enlace en el navegador sale error (404, ERR_*, etc.):**
- La **web** en cocinaentucasa.com debe tener publicada la ruta `/recipe/{id}` y conectada al mismo Firebase (Firestore) que la app.
- La app solo genera y copia el enlace; no puede “arreglar” que la web no tenga esa ruta.

---

## 6. Plan de comidas semanal (app)

**Qué verificar:** Plan Semanal: agregar recetas a desayuno/almuerzo/cena, ver coste, generar lista.

**Comportamiento esperado:**
- Se pueden asignar recetas a cada slot.
- **Coste:** Se muestra resumen de coste (semana/día) cuando hay precios de ingredientes en el sistema (Pantry/ingredient prices). Si todo está a 0, el coste será 0 hasta que se asignen precios.
- **Generar lista:** Igual que punto 1: siempre se genera una lista (solo faltantes o checklist completo).

**Si el coste siempre es 0:** Hay que tener precios de ingredientes (p. ej. en Pantry, por ingrediente canónico) para que el cálculo de coste no sea 0.

---

## 7. Precios y “ahorro” (app + datos)

**Qué verificar:** En Pantry, editar un ingrediente y ver si hay campo de precio. En receta/plan, ver si aparece coste y ahorro.

**Comportamiento esperado:**
- En **Editar ingrediente** (Pantry) hay campo opcional de precio por unidad; se guarda como override de usuario para ese ingrediente canónico.
- El coste de receta y plan se calcula con esos precios (y precios globales de ingredientes, si existen).
- Si no hay precios guardados, el coste se muestra como 0 o mensaje de “agregar precios”.

**“Ahorro”:** Si existe lógica de ahorro en la UI, depende de tener precios y posiblemente datos de ofertas; si no está implementada o no hay datos, puede ocultarse hasta que esté lista.

---

## 8. Resumen: qué arregla la app y qué depende de backend/web

| Tema                         | Arreglado en app | Depende de backend/web |
|-----------------------------|------------------|-------------------------|
| Generar lista (no bloquear)  | Sí               | No                      |
| Enlaces de tienda (validar) | Sí               | No                      |
| Alertas – sin bloque vacío  | Sí               | No                      |
| Imagen de receta (mostrar)  | Lógica correcta  | Reglas Storage (+ CORS web) |
| Enlace compartir (abrir)    | URL correcta     | Ruta `/recipe/{id}` en web |
| Coste receta/plan            | Cálculo correcto | Datos de precios        |
| Mismo backend app + web     | N/A              | Sí – mismo proyecto Firebase |

---

## 9. Checklist rápida antes de cerrar fase

- [ ] Generar lista desde receta (con y sin ingredientes en despensa).
- [ ] Generar lista desde Plan Semanal (con y sin ingredientes en despensa).
- [ ] Pulsar enlace Amazon/Walmart en lista de compras (enlace real vs vacío vs enlace de receta).
- [ ] Pantry: ver sección Alertas (carga con esqueleto, sin bloque en blanco).
- [ ] Receta: subir imagen, guardar, ver en lista y detalle (si no se ve, revisar Storage).
- [ ] Receta: Copiar enlace y comprobar mensaje de éxito (abrir en navegador depende de la web).
- [ ] Plan Semanal: asignar recetas, ver coste si hay precios, generar lista.

Si algo no coincide con lo anterior, indicar: pantalla, acción exacta y mensaje o comportamiento que se ve (y si es posible, si la web/Storage ya están configurados como en este documento).
