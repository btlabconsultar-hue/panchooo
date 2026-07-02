# Informe técnico del proyecto

## Opción elegida: E-Commerce Deportivo

Elegimos desarrollar la aplicación como un E-Commerce Deportivo. La propuesta se orientó a una tienda online donde el usuario puede navegar productos, agregarlos al carrito, calcular envío y pagar con Mercado Pago, mientras el administrador gestiona el catálogo.

## 1. Objetivo del sistema

La aplicación busca ofrecer una experiencia de compra completa con los siguientes objetivos:

- mostrar un catálogo de productos deportivos;
- permitir la creación y edición de productos desde un panel administrativo;
- permitir al usuario final agregar productos al carrito y ver el total;
- calcular el costo de envío según la distancia entre origen y destino;
- generar un flujo de pago con Mercado Pago;
- almacenar órdenes y productos de forma segura en Firebase.

## 2. Arquitectura general

La aplicación está estructurada en capas bien definidas:

- Frontend: Flutter + Dart.
- Gestión de estado: Provider.
- Base de datos y autenticación: Firebase Auth + Firestore.
- API de mapa: Google Distance Matrix para cálculo de distancia.
- API de pagos: Mercado Pago Checkout para generar links de pago.
- Persistencia local: Shared Preferences para fallback y datos simples.

### Componentes clave

- `main.dart`: inicializa Firebase y Provider.
- `app_state.dart`: centraliza estado, carga de datos, autenticación y operaciones de compra.
- `checkout_screen.dart`: muestra productos, carrito y proceso de checkout.
- `cart_screen.dart`: detalla el carrito, calcula envío y envía la orden de pago.
- `admin_products_screen.dart`: panel para crear productos y ver órdenes.

## 3. Esquema de integración con APIs externas

### 3.1 Firebase

Firebase funciona como columna vertebral de los datos:

- Autenticación de administradores: permite acceder al panel de gestión.
- Firestore de productos: guarda el catálogo que se muestra en la tienda.
- Firestore de órdenes: conserva cada compra iniciada.
- Persistencia local: guarda favoritos y órdenes en Shared Preferences cuando Firebase no está disponible.

#### Cómo se usa en la app

- `FirebaseService` abstrae los métodos `saveProduct`, `loadProducts`, `saveOrder` y `loadOrders`.
- `AppState` consume esa capa para mantener la UI sincronizada.
- Los productos cargados en Firestore aparecen inmediatamente en la pantalla de checkout.

### 3.2 Google Distance Matrix API

La API externa se utilizó para calcular la distancia entre la dirección de origen y la del usuario.

#### Proceso integrado

1. El usuario ingresa provincia, localidad y dirección.
2. La app construye un `destinationAddress` completo.
3. `CheckoutService._resolveDistanceKm` llama a Google Distance Matrix.
4. El JSON devuelto se parsea y se extrae el valor de distancia.
5. El envío se calcula como `distanceKm * shippingRatePerKm`.

#### Función dentro de la app

- permite mostrar un `shippingCost` realista;
- mejora la experiencia del checkout con valores de envío dinámicos;
- evita cálculos estáticos, usando distancia real entre ubicaciones.

### 3.3 Mercado Pago API

Mercado Pago se integra como pasarela de pago para que la orden pueda completarse fuera de la app.

#### Proceso integrado

1. El checkout arma el detalle del pedido (`orderTitle`, precio, destino).
2. `CheckoutService._buildMercadoPagoUrl` envía una petición POST al endpoint `/checkout/preferences`.
3. Se incluye `items`, `external_reference`, `unit_price` y `currency_id`.
4. Se recibe el `init_point` y se abre en el navegador para pagar.

#### Función dentro de la app

- genera un link de pago seguro;
- permite al usuario terminar la compra con Mercado Pago;
- centraliza la integración de cobro fuera de la app.

## 4. Trabajo de arquitectura realizado fuera de pedir código a la IA

Todo el desarrollo involucró trabajo manual más allá de los prompts de IA. Estos son los pasos concretos que se hicieron fuera del código generado automáticamente.

### 4.1 Cuentas y configuración de desarrollador

Se crearon y configuraron cuentas en:

- Firebase: para Auth y Firestore.
- Google Cloud: para obtener la API Key de Distance Matrix.
- Mercado Pago: para generar el Access Token de pruebas.

Esto incluyó registrar la app, descargar archivos de configuración de Firebase e inscribir dominios y paquetes.

### 4.2 Manejo de credenciales y tokens

Se obtuvieron y gestionaron claves como:

- `firebase_options.dart` para conectar Firebase con Flutter.
- Google Maps API Key para Distance Matrix.
- Mercado Pago Access Token para generar pagos.

Este trabajo implicó proteger las credenciales y colocarlas en la configuración correcta.

### 4.3 Lectura de documentación oficial

Se leyó y aplicó la documentación de:

- Firebase Authentication y Firestore;
- Google Distance Matrix API;
- Mercado Pago Checkout API.

La documentación permitió comprender los endpoints, parámetros requeridos, estructuras JSON y formatos de respuesta.

### 4.4 Instalación y adaptación de dependencias

Se actualizó `pubspec.yaml` para incluir paquetes necesarios:

- `firebase_core`;
- `firebase_auth`;
- `cloud_firestore`;
- `provider`;
- `http`;
- `shared_preferences`.

También se adaptó el código para garantizar compatibilidad entre versiones y evitar conflictos de paquetes.

### 4.5 Configuración de permisos

Se revisaron y probaron permisos en Firestore para que:

- el administrador pueda escribir productos;
- la app pueda leer productos y órdenes;
- el fallback local funcione cuando Firebase no esté disponible.

### 4.6 Adaptación de JSON y manejo de errores complejos

Se detectaron respuestas JSON con formatos variables, por ejemplo:

- valores numéricos entregados como `String`;
- campos opcionales ausentes en Firestore;
- objetos `distance` con rutas diferentes.

Para resolverlo se hizo:

- parseo seguro en `checkout_models.dart`;
- validación de `num` y `String` antes de convertir a `int` o `double`;
- fallback en la lógica de cálculo de distancia;
- mensajes claros de error en la UI.

Este trabajo fue esencial para que la aplicación funcionara sin fallos a pesar de datos externos inconsistentes.

## 5. Organización de los datos y base de datos

La base de datos se diseñó para almacenar registros limpios y organizados:

- `Products`: documentos con `id`, `titulo`, `precio`, `description`, `stock` e `imageUrl`.
- `Orders`: documentos con `id`, `productName`, `productPrice`, `distanceKm`, `shippingCost`, `totalAmount`, `paymentUrl`, `createdAt`, `destinationAddress`.

Además, se utilizó `Shared Preferences` como fallback local para guardar órdenes y favoritos cuando Firebase no estaba disponible.

### Datos JSON adaptados

Se trabajó en adaptar los JSON de las APIs para que la app los utilice de forma consistente:

- `StoreProduct.fromFirestoreMap` valida y normaliza campos de Firestore.
- `CheckoutOrder.fromFirestoreMap` convierte fechas y valores numéricos correctamente.
- `CheckoutService` parsea bloques de respuesta de Google y Mercado Pago con robustez.

## 6. Errores complejos resueltos

Se solucionaron fallos que la IA no pudo resolver sola, incluyendo:

- productos no aparecían tras guardarse en Firestore;
- mensajes de stock incorrectos en el carrito;
- botón de agregar producto demasiado grande y con texto equivocado;
- cálculo de envío que fallaba cuando la API no entregaba distancia directa.

También se ajustaron estados de UI, validaciones de campos y condiciones de renderizado para que la interfaz no muestre elementos erróneos.

## 7. Resultados finales

La aplicación quedó con:

- catálogo de productos dinámico;
- carrito funcional con límite por stock;
- resumen de compra claro;
- checkout con envío calculado;
- integración con Mercado Pago;
- panel administrativo para crear productos;
- almacenamiento eficiente de órdenes y favoritos.

## 8. Conclusión

El informe demuestra un desarrollo completo y documentado. Se eligió la opción E-Commerce Deportivo y se realizó un trabajo técnico sustantivo: integración de APIs, adaptación de JSON, configuración de permisos y solución de errores complejos. La aplicación funciona como una tienda real, con backend Firebase y servicios externos perfectamente conectados.