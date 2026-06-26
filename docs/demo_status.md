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
- Ventas reales con `boutique_confirm_sale`.
- Pedidos reales de cliente con `boutique_create_customer_order`.
- Descuento de stock transaccional.
- Apertura y cierre de caja.
- Reportes calculados desde Supabase.
- Prendas demo con imagenes remotas.

## Funcional durante la sesion

- Filtros por categoria y stock bajo.
- Agregar productos a venta o carrito.
- Actualizar cantidades del carrito.
- Limpiar una venta.
- Vista de total.
- Dialogo de preparacion de cobro QR.
- Confirmar venta por efectivo, QR o tarjeta.
- Confirmar pedido desde cuenta cliente.

## Siguiente fase de backend

- Integracion bancaria para generar QR dinamico en Bolivia.
- Gestion de usuarios desde la interfaz del administrador.
- Aprobacion/cancelacion de pedidos pendientes.
- Egresos manuales de caja.
- Reportes de margen cuando exista costo de compra por prenda.

## Checklist para demostrar

1. Ejecutar `docs/supabase_product_catalog.sql`.
2. Ejecutar `docs/supabase_operations_demo.sql`.
3. Iniciar como administrador.
4. Abrir caja con monto inicial.
5. Confirmar que aparecen prendas demo con imagenes.
6. Crear o editar una prenda con imagen y variantes.
7. Agregar una prenda a venta y confirmar pago QR o efectivo.
8. Verificar que el stock baja.
9. Revisar reportes diario, mensual y anual.
10. Iniciar como cliente, agregar al carrito y confirmar pedido.
