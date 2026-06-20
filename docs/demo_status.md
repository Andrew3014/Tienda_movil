# Estado funcional de la demostracion

## Conectado a Supabase

- Login y cierre de sesion.
- Perfil y rol del usuario.
- Permisos por administrador, vendedor y cliente.
- Catalogo de productos.
- Categorias.
- Variantes por talla, color, stock y stock minimo.
- Creacion y edicion de prendas por administrador/vendedor.
- Desactivacion de prendas.
- Imagenes en Supabase Storage.
- Lectura publica del catalogo para clientes.

## Funcional durante la sesion

- Filtros por categoria y stock bajo.
- Agregar productos a venta o carrito.
- Actualizar cantidades del carrito.
- Limpiar una venta.
- Vista de total.
- Dialogo de preparacion de cobro QR.

Estos datos de carrito se mantienen mientras la app esta abierta, pero todavia
no se guardan en Supabase.

## Siguiente fase de backend

- Confirmar venta y crear filas en `sales`, `sale_items` y `payments`.
- Descontar stock de manera transaccional.
- Apertura y cierre real de caja.
- Movimientos de ingreso/egreso.
- Pedidos reales del cliente.
- Reportes calculados desde la base de datos.
- Integracion bancaria para generar QR dinamico en Bolivia.
- Gestion de usuarios desde la interfaz del administrador.

## Checklist para demostrar

1. Ejecutar `docs/supabase_product_catalog.sql`.
2. Iniciar como administrador.
3. Crear una prenda con imagen y dos variantes.
4. Confirmar que aparece en el catalogo.
5. Editar stock y verificar el cambio.
6. Iniciar como vendedor y agregar la prenda a venta.
7. Abrir el dialogo QR.
8. Iniciar como cliente y agregar la prenda al carrito.
9. Verificar filtros y total del carrito.
