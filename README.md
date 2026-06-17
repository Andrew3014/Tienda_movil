# Mi Tienda Boutique

Aplicacion multiplataforma desarrollada con Flutter para administrar una boutique de ropa desde Android, iOS y Web. El objetivo es centralizar catalogo, inventario por variantes, ventas rapidas, cobros con QR en Bolivia y control de caja, dejando la base preparada para integrarse con Supabase.

## Objetivo general

Desarrollar una aplicacion comercial eficiente, escalable y responsiva que permita gestionar las operaciones principales de una tienda de ropa o boutique desde una sola base de codigo.

## Objetivos especificos

- Gestionar productos por categoria, marca, modelo, color, talla y stock disponible.
- Registrar ventas rapidas desde una interfaz tipo punto de venta.
- Preparar el flujo de cobro por QR para el contexto boliviano.
- Controlar caja diaria, ingresos, ventas y alertas de stock bajo.
- Integrar autenticacion segura para administradores, vendedores y clientes con Supabase Auth.
- Diseñar una base de datos relacional en PostgreSQL para productos, variantes, clientes, ventas, pagos y movimientos de caja.
- Aplicar Row Level Security en Supabase para separar permisos por rol.
- Mantener una interfaz responsiva para Web, Android e iOS.

## Estado actual

La version actual implementa una interfaz neutra inspirada en shadcn:

- Paleta blanca, gris y negro con bordes sutiles.
- Selector de cuenta de prueba.
- Login real preparado con Supabase Auth.
- Matriz visual de permisos por rol.
- Panel de metricas.
- Catalogo con productos de ejemplo.
- Variantes de inventario por talla y color.
- Informacion de marca y modelo por prenda.
- Venta rapida con resumen de carrito y total.
- Bloque visual para cobro QR.
- Checklist de preparacion Supabase.

Los datos actuales son locales y sirven como base visual y funcional. La siguiente etapa es conectar autenticacion, perfiles y datos reales contra Supabase.

## Roles propuestos

| Rol | Uso profesional | Acceso |
| --- | --- | --- |
| Administrador | Dueno del emprendimiento | Usuarios, configuracion, inventario, ventas, caja y reportes |
| Vendedor/Cajero | Personal de atencion | Catalogo, ventas rapidas, QR, clientes, caja y reporte de turno |
| Cliente | Comprador final | Catalogo, carrito, perfil y pedidos propios |

Las cuentas de prueba estan documentadas en `docs/testing_accounts.md`.

## Stack tecnico

- Flutter
- Dart
- Material 3
- Supabase como backend planificado
- PostgreSQL como base de datos relacional

## Estructura principal

```text
lib/
  main.dart                 Pantalla principal, demo de roles y permisos
test/
  widget_test.dart          Prueba de carga del dashboard
docs/
  supabase_schema.sql       Esquema inicial propuesto para Supabase
  supabase_setup.md         Guia para crear Supabase y usuarios de prueba
  supabase_three_roles_migration.sql Migracion del proyecto actual a tres roles
  testing_accounts.md       Cuentas, permisos y pruebas de login
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

## Android Studio y emulador

1. Abrir Android Studio.
2. Seleccionar `Open` y elegir la carpeta `C:\Users\andru\StudioProjects\miTienda`.
3. Esperar a que Android Studio detecte Flutter y ejecute `pub get`.
4. Verificar que el plugin de Flutter y Dart este instalado.
5. Abrir `Device Manager` y crear un emulador Android si no existe.
6. Seleccionar el emulador o un celular conectado por USB.
7. Presionar `Run`.

Si Android Studio no reconoce Flutter, revisar que el SDK este configurado en `Settings > Languages & Frameworks > Flutter` apuntando a `C:\src\flutter`.

## Plan Supabase

1. Crear proyecto en Supabase.
2. Ejecutar `docs/supabase_schema.sql` en SQL Editor.
3. Crear usuarios de prueba desde Authentication.
4. Insertar cada usuario en `profiles` con el rol correspondiente.
5. Guardar `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
6. Ejecutar la app e iniciar sesion con las cuentas creadas.
7. Mantener el modo demo solo para pruebas visuales locales.

## Proximas tareas

- Separar modelos, servicios y pantallas en carpetas por responsabilidad.
- Agregar `supabase_flutter`.
- Implementar autenticacion real.
- Crear CRUD de productos y variantes.
- Implementar registro real de ventas y movimientos de caja.
- Generar QR de pago y registrar estado del cobro.
- Agregar reportes de ventas, margen y stock bajo.
