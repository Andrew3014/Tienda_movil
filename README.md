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
- Catalogo real cargado desde Supabase.
- Alta y edicion de prendas para administrador y vendedor.
- Imagen JPG, PNG o WebP almacenada en Supabase Storage.
- Variantes multiples por talla, color y stock.
- Filtros por categoria y stock bajo.
- Panel de metricas.
- Venta real mediante RPC: crea `sales`, `sale_items`, `payments` y descuenta stock.
- Pedido real del cliente desde carrito.
- Apertura y cierre de caja.
- Reportes contables con graficas simples: diario, mensual, anual y metodos de pago.
- Datos demo con imagenes remotas de prendas para presentacion.
- Catalogo con productos de ejemplo.
- Variantes de inventario por talla y color.
- Informacion de marca y modelo por prenda.
- Venta rapida con resumen de carrito, total y metodo de pago.
- Bloque visual para cobro QR y registro de pago QR como metodo.
- Checklist de preparacion Supabase.

La app funciona en modo demo local y tambien conectada a Supabase. Para que ventas, caja, reportes, pedidos e imagenes funcionen en Supabase, ejecutar los SQL indicados en la seccion "Plan Supabase".

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
  supabase_product_catalog.sql Catalogo, imagenes y permisos de productos
  supabase_operations_demo.sql Ventas reales, caja, reportes y datos demo
  testing_accounts.md       Cuentas, permisos y pruebas de login
  demo_status.md            Funciones conectadas y siguientes fases
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

Para activar catalogo e imagenes en un proyecto Supabase existente, ejecutar
completo en SQL Editor:

```text
docs/supabase_product_catalog.sql
```

El script crea el bucket publico `product-images`, agrega `image_url` a
`products` y permite que administrador y vendedor gestionen prendas y stock.

Para activar ventas reales, pedidos del cliente, apertura/cierre de caja,
reportes y cargar prendas de demostracion con imagenes, ejecutar despues:

```text
docs/supabase_operations_demo.sql
```

Ese script agrega funciones RPC para:

- `boutique_confirm_sale`: registra venta pagada, items, pago y descuenta stock.
- `boutique_create_customer_order`: registra pedido del cliente y reserva stock.
- `boutique_open_register` / `boutique_close_register`: control de caja.
- `boutique_dashboard_summary`: datos de reportes diario, mensual y anual.

## Proximas tareas

- Separar modelos, servicios y pantallas en carpetas por responsabilidad.
- Agregar flujo para aprobar pedidos pendientes del cliente.
- Agregar egresos manuales de caja.
- Generar QR bancario dinamico cuando se defina proveedor/banco en Bolivia.
- Agregar reportes de margen cuando se registre costo por producto.
