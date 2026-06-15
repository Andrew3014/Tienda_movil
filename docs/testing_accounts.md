# Cuentas de prueba y niveles de acceso

Estas cuentas son la base recomendada para probar login, visibilidad y gestion por rol. En la app actual se simulan desde el selector "Cuenta de prueba". Cuando se conecte Supabase, cada email debe crearse en Authentication y luego vincularse en la tabla `profiles`.

## Cuentas recomendadas

| Email | Rol | Nivel |
| --- | --- | --- |
| admin@mitienda.bo | Administrador | Acceso total |
| gerente@mitienda.bo | Gerente | Gestion operativa |
| ventas@mitienda.bo | Vendedor/Cajero | Venta y caja |
| stock@mitienda.bo | Inventario | Productos y stock |
| cliente@mitienda.bo | Cliente | Compra y pedidos propios |

Para desarrollo local se puede usar una contraseña temporal comun, por ejemplo:

```text
Demo123456!
```

En produccion cada usuario debe cambiar su contraseña y activar politicas de seguridad reales.

## Permisos por rol

| Modulo | Admin | Gerente | Vendedor | Inventario | Cliente |
| --- | --- | --- | --- | --- | --- |
| Ver catalogo | Si | Si | Si | Si | Si |
| Gestionar productos | Si | Si | No | Si | No |
| Gestionar variantes/stock | Si | Si | No | Si | No |
| Crear ventas | Si | Si | Si | No | No |
| Cobrar QR | Si | Si | Si | No | No |
| Abrir/cerrar caja | Si | Si | Si | No | No |
| Ver reportes | Si | Si | No | Si | No |
| Gestionar usuarios | Si | No | No | No | No |
| Configuracion | Si | No | No | No | No |
| Ver pedidos propios | Si | Si | No | No | Si |

## Flujo minimo de pruebas

1. Iniciar como `admin@mitienda.bo`.
2. Confirmar que todos los modulos aparecen activos.
3. Cambiar a `gerente@mitienda.bo`.
4. Confirmar que puede operar ventas, caja, inventario y reportes, pero no usuarios/configuracion.
5. Cambiar a `ventas@mitienda.bo`.
6. Confirmar que puede vender y cobrar QR, pero no editar productos.
7. Cambiar a `stock@mitienda.bo`.
8. Confirmar que puede gestionar inventario, pero no vender ni cobrar QR.
9. Cambiar a `cliente@mitienda.bo`.
10. Confirmar que solo ve catalogo/pedidos propios y no operaciones internas.

## Implementacion en Supabase

Cuando Supabase este creado:

1. Crear cada usuario en `Authentication > Users`.
2. Copiar el `id` UUID de cada usuario.
3. Insertar filas en `profiles`:

```sql
insert into public.profiles (id, full_name, role)
values
  ('UUID_ADMIN', 'Admin General', 'admin'),
  ('UUID_GERENTE', 'Gerente Boutique', 'manager'),
  ('UUID_VENTAS', 'Vendedora Caja', 'seller'),
  ('UUID_STOCK', 'Encargado Stock', 'inventory'),
  ('UUID_CLIENTE', 'Cliente Demo', 'customer');
```

4. Probar login por cada usuario.
5. Validar que las politicas RLS permitan o bloqueen las operaciones correctas.
