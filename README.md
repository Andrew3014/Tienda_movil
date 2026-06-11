# Mi Tienda Boutique

Aplicacion multiplataforma desarrollada con Flutter para administrar una boutique de ropa desde Android, iOS y Web. El objetivo es centralizar catalogo, inventario por variantes, ventas rapidas, cobros con QR en Bolivia y control de caja, dejando la base preparada para integrarse con Supabase.

## Objetivo general

Desarrollar una aplicacion comercial eficiente, escalable y responsiva que permita gestionar las operaciones principales de una tienda de ropa o boutique desde una sola base de codigo.

## Objetivos especificos

- Gestionar productos por categoria, marca, modelo, color, talla y stock disponible.
- Registrar ventas rapidas desde una interfaz tipo punto de venta.
- Preparar el flujo de cobro por QR para el contexto boliviano.
- Controlar caja diaria, ingresos, ventas y alertas de stock bajo.
- Integrar autenticacion segura para administradores y clientes con Supabase Auth.
- Diseñar una base de datos relacional en PostgreSQL para productos, variantes, clientes, ventas, pagos y movimientos de caja.
- Aplicar Row Level Security en Supabase para separar permisos de clientes y administradores.
- Mantener una interfaz responsiva para Web, Android e iOS.

## Estado actual

La primera version implementa una pantalla principal con:

- Panel de metricas: caja abierta, ventas del dia, stock bajo y pagos QR.
- Catalogo con productos de ejemplo.
- Variantes de inventario por talla y color.
- Informacion de marca y modelo por prenda.
- Venta rapida con resumen de carrito y total.
- Bloque visual para generar/cobrar por QR.
- Roadmap de integracion con Supabase.

Los datos actuales son locales y sirven como base visual y funcional. La siguiente etapa es conectar repositorios/servicios reales contra Supabase.

## Stack tecnico

- Flutter
- Dart
- Material 3
- Supabase como backend planificado
- PostgreSQL como base de datos relacional

## Estructura principal

```text
lib/
  main.dart              Pantalla principal y modelos locales iniciales
test/
  widget_test.dart       Prueba de carga del dashboard
docs/
  supabase_schema.sql    Esquema inicial propuesto para Supabase
```

## Ejecucion local

```bash
flutter pub get
flutter run
```

Para ejecutar en Web:

```bash
flutter run -d chrome
```

Para pruebas:

```bash
flutter analyze
flutter test
```

## Plan de despliegue

1. Crear proyecto de produccion en Supabase.
2. Ejecutar el esquema SQL ubicado en `docs/supabase_schema.sql`.
3. Configurar politicas RLS para clientes y administradores.
4. Crear variables de entorno para `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
5. Conectar Flutter con el SDK de Supabase.
6. Generar build Web para Netlify/Vercel o hosting compatible.
7. Generar APK/AAB para pruebas y distribucion Android.
8. Preparar configuracion iOS para despliegue desde Xcode/App Store Connect.

## Proximas tareas

- Separar modelos, servicios y pantallas en carpetas por responsabilidad.
- Agregar `supabase_flutter`.
- Implementar autenticacion.
- Crear CRUD de productos y variantes.
- Implementar registro real de ventas y movimientos de caja.
- Generar QR de pago y registrar estado del cobro.
- Agregar roles de usuario: administrador, vendedor y cliente.
