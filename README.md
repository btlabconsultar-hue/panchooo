# Informe técnico del proyecto

## Opción elegida: E-Commerce Deportivo

Este proyecto fue transformado en una tienda deportiva online con funcionalidades de administración, carrito de compras, checkout, cálculo de envío y pago. La aplicación combina Flutter, Firebase, una API de geolocalización y una pasarela de pagos externa para ofrecer una experiencia de compra completa.

## 1. Objetivo del sistema

El objetivo principal fue convertir una app deportiva base en una tienda funcional donde:

- se puedan visualizar productos;
- los administradores puedan crear y gestionar productos;
- los usuarios puedan agregar productos al carrito;
- se pueda calcular un costo de envío aproximado;
- se pueda iniciar un proceso de pago a través de Mercado Pago.

## 2. Arquitectura general

La aplicación está organizada en capas claras:

- Frontend: Flutter + Dart.
- Estado de la app: Provider.
- Base de datos y autenticación: Firebase Auth + Firestore.
- Integración externa de mapas: Google Distance Matrix API.
- Integración externa de pagos: Mercado Pago Checkout API.
- Persistencia local: Shared Preferences para datos simples y fallback.

## 3. Proceso de integración con APIs externas

### 3.1 Firebase

Firebase se utilizó para tres funciones principales:

1. Autenticación de administradores.
2. Almacenamiento de productos en Firestore.
3. Persistencia de órdenes y favoritos.

El proceso fue el siguiente:

- se creó un proyecto en Firebase;
- se generaron los archivos de configuración con `firebase_options.dart`;
- se instalaron los paquetes correspondientes en `pubspec.yaml`;
- se configuraron reglas de acceso para permitir lectura/escritura a los datos relevantes;
- se conectó Flutter con Firebase mediante `firebase_core`, `firebase_auth` y `cloud_firestore`.

La función de Firebase dentro de la app es central: permite que los productos creados por el administrador se guarden en base de datos y luego aparezcan en la pantalla principal.

### 3.2 Google Distance Matrix API

Esta API se utilizó para calcular la distancia entre el origen del envío y el destino del usuario.

Proceso realizado:

- se obtuvo una API Key desde Google Cloud;
- se configuró la llamada HTTP a la URL de Distance Matrix;
- se parsearon los valores de distancia del JSON recibido;
- se adaptó la respuesta para poder convertirla en kilómetros y usarla en el cálculo del envío.

Función dentro de la aplicación:

- calcular el costo de envío en función de la distancia.
- permitir que el checkout muestre un total realista con transporte.

### 3.3 Mercado Pago API

Mercado Pago se integró para generar un link de pago asociado a una orden.

Proceso realizado:

- se creó una cuenta de desarrollador en Mercado Pago;
- se obtuvo un Access Token de prueba;
- se configuró una petición POST al endpoint de Checkout Preferences;
- se enviaron datos como título del producto, precio, moneda y referencia externa;
- se capturó la respuesta y se extrajo el `init_point` para abrir el pago.

Función dentro de la aplicación:

- crear una orden de compra con link de pago;
- redirigir al usuario a una interfaz de pago externa.

## 4. Trabajo de arquitectura realizado fuera de pedir código a la IA

Este proyecto no se resolvió solo con prompts. Hubo trabajo técnico propio de arquitectura y configuración que fue necesario implementar.

### 4.1 Creación y configuración de cuentas de desarrollador

Se debieron crear y configurar cuentas para:

- Firebase;
- Google Cloud;
- Mercado Pago.

Esto permitió obtener credenciales válidas y conectar correctamente los servicios externos.

### 4.2 Obtención de API Keys y Tokens

Se obtuvieron:

- una clave para Google Maps;
- un token de acceso para Mercado Pago;
- las credenciales del proyecto Firebase.

Estas claves fueron necesarias para que la app pudiera comunicarse con servicios externos en tiempo real.

### 4.3 Lectura de documentación oficial

Fue necesario leer la documentación de:

- Firebase Authentication y Firestore;
- Google Distance Matrix API;
- Mercado Pago Checkout API.

Esto permitió entender cómo debían enviarse los parámetros, qué estructura tenía la respuesta y qué errores podían aparecer.

### 4.4 Instalación y adaptación de paquetes

Se modificó el archivo `pubspec.yaml` para incluir paquetes como:

- `firebase_core`;
- `firebase_auth`;
- `cloud_firestore`;
- `provider`;
- `http`;
- `shared_preferences`.

Además, fue necesario adaptar el código para que las dependencias funcionaran bien con la estructura del proyecto.

### 4.5 Configuración de permisos y reglas

Se tuvieron que revisar y ajustar permisos para que:

- los administradores pudieran crear productos;
- las lecturas de Firestore pudieran ejecutarse correctamente;
- la app no se quedara bloqueada por errores de seguridad.

### 4.6 Adaptación de JSON y manejo de errores

Muchas respuestas de las APIs externas no llegaron en el formato exacto que se esperaba. Por eso fue necesario:

- adaptar el parseo de JSON;
- validar si los valores venían como `num` o como `String`;
- manejar fallbacks cuando una API no estaba disponible;
- corregir errores de runtime y de análisis.

Este trabajo fue clave porque la IA ayudó a generar estructura y lógica, pero la solución final dependió de revisar los datos reales y ajustar el código para que funcionara correctamente.

## 5. Funcionalidades principales implementadas

- Pantalla principal con productos.
- Carrito de compras.
- Checkout con cálculo de envío.
- Integración con Mercado Pago.
- Login de administrador.
- Alta de productos desde el panel de administración.
- Persistencia de órdenes y favoritos.

## 6. Problemas resueltos durante el desarrollo

Durante la implementación surgieron varios problemas que exigieron intervención técnica:

- productos que se guardaban en Firestore pero no aparecían en la pantalla principal;
- errores al parsear valores numéricos provenientes de APIs o de Firestore;
- fallos al calcular el costo de envío por respuesta inesperada de la API;
- errores de autenticación y permisos de administrador;
- necesidad de corregir problemas de sincronización entre la UI y el estado global.

## 7. Conclusión

El proyecto logró pasar de una app deportiva base a una tienda online funcional con integración real a servicios externos. La arquitectura resultó adecuada para separar responsabilidades entre UI, estado, base de datos y servicios externos, y el desarrollo requirió trabajo técnico real más allá de generar código automáticamente: configuración de cuentas, obtención de credenciales, comprensión de documentación y adaptación de respuestas externas.
