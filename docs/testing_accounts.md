# Cuentas de prueba y niveles de acceso

La primera version comercial utiliza tres perfiles simples para boutiques y nuevos emprendimientos.

## Cuentas

| Email | Rol | Uso |
| --- | --- | --- |
| admin@mitienda.bo | Administrador | Dueno o responsable del negocio |
| ventas@mitienda.bo | Vendedor/Cajero | Personal de venta y caja |
| cliente@mitienda.bo | Cliente | Comprador desde app o web |

## Permisos

| Modulo | Administrador | Vendedor/Cajero | Cliente |
| --- | --- | --- | --- |
| Ver catalogo | Si | Si | Si |
| Gestionar productos y stock | Si | No | No |
| Crear ventas presenciales | Si | Si | No |
| Cobrar QR | Si | Si | No |
| Abrir y cerrar caja | Si | Si | No |
| Buscar clientes | Si | Si | No |
| Ver reportes generales | Si | No | No |
| Ver reporte del turno | Si | Si | No |
| Gestionar usuarios/configuracion | Si | No | No |
| Agregar al carrito | No | No | Si |
| Crear pedido propio | No | No | Si |
| Ver pedidos propios | No | No | Si |
| Editar perfil propio | Si | Si | Si |

## Pruebas recomendadas

1. Iniciar como `admin@mitienda.bo`.
2. Confirmar acceso total a inventario, ventas, caja, reportes y configuracion.
3. Iniciar como `ventas@mitienda.bo`.
4. Confirmar acceso a venta rapida, QR, caja, clientes y reporte del turno.
5. Confirmar que vendedor no puede editar productos, usuarios ni configuracion.
6. Iniciar como `cliente@mitienda.bo`.
7. Confirmar que ve catalogo, carrito, pedidos y perfil.
8. Confirmar que cliente no ve caja, inventario, ventas internas ni reportes.

## UUID del proyecto Supabase actual

| Usuario | UUID |
| --- | --- |
| Administrador | `8f38d94b-4a9f-4f34-b900-d42e4d0a811d` |
| Vendedor | `37ffe5a9-ee15-4607-adc0-931b9edd4d4e` |
| Cliente | `ac3b5a5e-962e-4285-9f2d-40d02ecc5cb1` |

Ejecutar `docs/supabase_three_roles_migration.sql` para crear/actualizar los perfiles y politicas RLS.
