# Guia para crear Supabase

## 1. Crear el proyecto

1. Entrar a https://supabase.com.
2. Crear una cuenta o iniciar sesion.
3. Crear un nuevo proyecto.
4. Nombre sugerido: `mi-tienda-boutique`.
5. Elegir una region cercana.
6. Guardar la contraseña de base de datos en un lugar seguro.

## 2. Ejecutar el esquema

1. Abrir el proyecto en Supabase.
2. Ir a `SQL Editor`.
3. Crear un nuevo query.
4. Copiar el contenido de `docs/supabase_schema.sql`.
5. Ejecutar el script completo.

Esto crea tablas, roles, relaciones y politicas RLS iniciales.

## 3. Crear usuarios de prueba

Ir a `Authentication > Users > Add user` y crear:

| Email | Rol en `profiles` |
| --- | --- |
| admin@mitienda.bo | admin |
| ventas@mitienda.bo | seller |
| cliente@mitienda.bo | customer |

Puedes usar una contraseña temporal como `Demo123456!` durante desarrollo.

## 4. Insertar perfiles

Despues de crear los usuarios, copiar el UUID de cada uno e insertar en `profiles`:

```sql
insert into public.profiles (id, full_name, role)
values
  ('8f38d94b-4a9f-4f34-b900-d42e4d0a811d', 'Administrador General', 'admin'),
  ('37ffe5a9-ee15-4607-adc0-931b9edd4d4e', 'Vendedor Caja', 'seller'),
  ('ac3b5a5e-962e-4285-9f2d-40d02ecc5cb1', 'Cliente Demo', 'customer')
on conflict (id) do update
set full_name = excluded.full_name, role = excluded.role;
```

## 5. Guardar credenciales para Flutter

Ir a `Project Settings > API` y copiar:

- Project URL
- publishable key

Luego se conectaran en Flutter como variables:

```text
SUPABASE_URL=...
SUPABASE_PUBLISHABLE_KEY=...
```

No subir claves privadas ni service role key al repositorio.

La app ya puede recibir estos valores por `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://pakfwasisthdpfbsqvef.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_JZ7rsQ2p3kfOSR9oUoEMmw_Xj1askQF
```

En Android Studio puedes abrir `Run > Edit Configurations` y agregar esos `Additional run args`.

## 6. Pruebas esperadas

- Cliente solo puede ver catalogo y pedidos propios.
- Vendedor puede crear ventas y registrar pagos QR.
- Vendedor puede operar caja, clientes y consultar su turno.
- Administrador puede gestionar inventario, usuarios, configuracion y todo lo operativo.
