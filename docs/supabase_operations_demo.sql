-- Fase operacional para demo profesional de Mi Tienda Boutique.
-- Ejecutar completo en Supabase SQL Editor despues de supabase_schema.sql,
-- supabase_three_roles_migration.sql y supabase_product_catalog.sql.

begin;

alter table public.products
add column if not exists image_url text;

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on
  public.categories,
  public.products,
  public.product_variants,
  public.cash_registers,
  public.sales,
  public.sale_items,
  public.payments,
  public.cash_movements
to authenticated;

create or replace function public.boutique_open_cash_register()
returns table (
  id uuid,
  opening_amount numeric,
  expected_amount numeric
)
language sql
stable
security definer
set search_path = public
as $$
  select
    cr.id,
    cr.opening_amount,
    coalesce(sum(
      case
        when cm.movement_type in ('opening', 'income') then cm.amount
        when cm.movement_type = 'expense' then -cm.amount
        else 0
      end
    ), cr.opening_amount) as expected_amount
  from public.cash_registers cr
  left join public.cash_movements cm on cm.cash_register_id = cr.id
  where cr.closed_at is null
  group by cr.id, cr.opening_amount
  order by cr.opened_at desc
  limit 1
$$;

create or replace function public.boutique_open_register(opening_amount_input numeric)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  role_value public.user_role;
  register_id uuid;
begin
  role_value := public.current_user_role();
  if role_value not in ('admin', 'seller') then
    raise exception 'No tienes permiso para abrir caja.';
  end if;

  if exists (select 1 from public.cash_registers where closed_at is null) then
    raise exception 'Ya existe una caja abierta.';
  end if;

  insert into public.cash_registers (opened_by, opening_amount)
  values (auth.uid(), opening_amount_input)
  returning id into register_id;

  insert into public.cash_movements (
    cash_register_id,
    created_by,
    movement_type,
    amount,
    description
  )
  values (
    register_id,
    auth.uid(),
    'opening',
    opening_amount_input,
    'Apertura de caja'
  );

  return register_id;
end;
$$;

create or replace function public.boutique_close_register(closing_amount_input numeric)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  role_value public.user_role;
  register_id uuid;
begin
  role_value := public.current_user_role();
  if role_value not in ('admin', 'seller') then
    raise exception 'No tienes permiso para cerrar caja.';
  end if;

  select id
  into register_id
  from public.cash_registers
  where closed_at is null
  order by opened_at desc
  limit 1;

  if register_id is null then
    raise exception 'No existe una caja abierta.';
  end if;

  update public.cash_registers
  set closed_by = auth.uid(),
      closed_at = now(),
      closing_amount = closing_amount_input
  where id = register_id;

  insert into public.cash_movements (
    cash_register_id,
    created_by,
    movement_type,
    amount,
    description
  )
  values (
    register_id,
    auth.uid(),
    'closing',
    closing_amount_input,
    'Cierre de caja'
  );

  return register_id;
end;
$$;

create or replace function public.boutique_confirm_sale(
  items_input jsonb,
  payment_method_input public.payment_method default 'cash'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  role_value public.user_role;
  register_id uuid;
  sale_id uuid;
  item jsonb;
  variant_row record;
  quantity_value integer;
  unit_price_value numeric;
  subtotal_value numeric := 0;
begin
  role_value := public.current_user_role();
  if role_value not in ('admin', 'seller') then
    raise exception 'No tienes permiso para registrar ventas.';
  end if;

  select id
  into register_id
  from public.cash_registers
  where closed_at is null
  order by opened_at desc
  limit 1;

  if register_id is null then
    raise exception 'Abre caja antes de confirmar ventas.';
  end if;

  if jsonb_array_length(items_input) = 0 then
    raise exception 'La venta no tiene items.';
  end if;

  for item in select * from jsonb_array_elements(items_input)
  loop
    quantity_value := (item ->> 'quantity')::integer;
    unit_price_value := (item ->> 'unit_price')::numeric;

    select id, stock
    into variant_row
    from public.product_variants
    where id = (item ->> 'variant_id')::uuid
    for update;

    if variant_row.id is null then
      raise exception 'Una variante de producto no existe.';
    end if;
    if quantity_value <= 0 then
      raise exception 'Cantidad invalida.';
    end if;
    if variant_row.stock < quantity_value then
      raise exception 'Stock insuficiente para una prenda.';
    end if;

    subtotal_value := subtotal_value + (quantity_value * unit_price_value);
  end loop;

  insert into public.sales (
    cash_register_id,
    seller_id,
    status,
    subtotal,
    discount,
    total,
    paid_at
  )
  values (
    register_id,
    auth.uid(),
    'paid',
    subtotal_value,
    0,
    subtotal_value,
    now()
  )
  returning id into sale_id;

  for item in select * from jsonb_array_elements(items_input)
  loop
    quantity_value := (item ->> 'quantity')::integer;
    unit_price_value := (item ->> 'unit_price')::numeric;

    insert into public.sale_items (
      sale_id,
      variant_id,
      quantity,
      unit_price,
      total
    )
    values (
      sale_id,
      (item ->> 'variant_id')::uuid,
      quantity_value,
      unit_price_value,
      quantity_value * unit_price_value
    );

    update public.product_variants
    set stock = stock - quantity_value
    where id = (item ->> 'variant_id')::uuid;
  end loop;

  insert into public.payments (sale_id, method, amount, qr_reference)
  values (
    sale_id,
    payment_method_input,
    subtotal_value,
    case when payment_method_input = 'qr' then 'QR-' || left(sale_id::text, 8) else null end
  );

  insert into public.cash_movements (
    cash_register_id,
    created_by,
    movement_type,
    amount,
    description
  )
  values (
    register_id,
    auth.uid(),
    'income',
    subtotal_value,
    'Venta ' || left(sale_id::text, 8)
  );

  return sale_id;
end;
$$;

create or replace function public.boutique_create_customer_order(items_input jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  role_value public.user_role;
  sale_id uuid;
  item jsonb;
  variant_row record;
  quantity_value integer;
  unit_price_value numeric;
  subtotal_value numeric := 0;
begin
  role_value := public.current_user_role();
  if role_value <> 'customer' then
    raise exception 'Solo clientes pueden crear pedidos desde el carrito.';
  end if;

  if jsonb_array_length(items_input) = 0 then
    raise exception 'El pedido no tiene items.';
  end if;

  for item in select * from jsonb_array_elements(items_input)
  loop
    quantity_value := (item ->> 'quantity')::integer;
    unit_price_value := (item ->> 'unit_price')::numeric;

    select id, stock
    into variant_row
    from public.product_variants
    where id = (item ->> 'variant_id')::uuid
    for update;

    if variant_row.id is null then
      raise exception 'Una variante de producto no existe.';
    end if;
    if quantity_value <= 0 then
      raise exception 'Cantidad invalida.';
    end if;
    if variant_row.stock < quantity_value then
      raise exception 'Stock insuficiente para una prenda.';
    end if;

    subtotal_value := subtotal_value + (quantity_value * unit_price_value);
  end loop;

  insert into public.sales (
    customer_id,
    status,
    subtotal,
    discount,
    total
  )
  values (
    auth.uid(),
    'draft',
    subtotal_value,
    0,
    subtotal_value
  )
  returning id into sale_id;

  for item in select * from jsonb_array_elements(items_input)
  loop
    quantity_value := (item ->> 'quantity')::integer;
    unit_price_value := (item ->> 'unit_price')::numeric;

    insert into public.sale_items (
      sale_id,
      variant_id,
      quantity,
      unit_price,
      total
    )
    values (
      sale_id,
      (item ->> 'variant_id')::uuid,
      quantity_value,
      unit_price_value,
      quantity_value * unit_price_value
    );

    update public.product_variants
    set stock = stock - quantity_value
    where id = (item ->> 'variant_id')::uuid;
  end loop;

  return sale_id;
end;
$$;

create or replace function public.boutique_dashboard_summary()
returns table (
  active_products integer,
  sales_today integer,
  low_stock_variants integer,
  qr_payments_today integer,
  customer_orders integer,
  pending_orders integer,
  cash_today numeric,
  daily_revenue numeric,
  monthly_revenue numeric,
  yearly_revenue numeric,
  average_ticket numeric,
  cash_payments_today numeric,
  qr_revenue_today numeric,
  card_revenue_today numeric
)
language sql
stable
security definer
set search_path = public
as $$
  select
    (select count(*)::integer from public.products where active = true),
    (select count(*)::integer from public.sales where status = 'paid' and created_at::date = current_date),
    (select count(*)::integer from public.product_variants where stock <= min_stock),
    (select count(*)::integer from public.payments where method = 'qr' and paid_at::date = current_date),
    (select count(*)::integer from public.sales where customer_id = auth.uid()),
    (select count(*)::integer from public.sales where status = 'draft' and (customer_id = auth.uid() or public.current_user_role() in ('admin', 'seller'))),
    coalesce((select sum(amount) from public.cash_movements where movement_type = 'income' and created_at::date = current_date), 0),
    coalesce((select sum(total) from public.sales where status = 'paid' and created_at::date = current_date), 0),
    coalesce((select sum(total) from public.sales where status = 'paid' and date_trunc('month', created_at) = date_trunc('month', now())), 0),
    coalesce((select sum(total) from public.sales where status = 'paid' and date_trunc('year', created_at) = date_trunc('year', now())), 0),
    coalesce((select avg(total) from public.sales where status = 'paid' and created_at::date = current_date), 0),
    coalesce((select sum(amount) from public.payments where method = 'cash' and paid_at::date = current_date), 0),
    coalesce((select sum(amount) from public.payments where method = 'qr' and paid_at::date = current_date), 0),
    coalesce((select sum(amount) from public.payments where method = 'card' and paid_at::date = current_date), 0)
$$;

grant execute on function public.boutique_open_cash_register() to authenticated;
grant execute on function public.boutique_open_register(numeric) to authenticated;
grant execute on function public.boutique_close_register(numeric) to authenticated;
grant execute on function public.boutique_confirm_sale(jsonb, public.payment_method) to authenticated;
grant execute on function public.boutique_create_customer_order(jsonb) to authenticated;
grant execute on function public.boutique_dashboard_summary() to authenticated;

insert into public.categories (name)
values ('Blazers'), ('Vestidos'), ('Jeans'), ('Camisas'), ('Poleras'), ('Chamarras')
on conflict (name) do nothing;

with demo_products as (
  select *
  from (values
    ('Blazer lino premium', 'Casa Mora', 'Roma', 'Blazers', 325::numeric, 'Blazer neutro para oficina y eventos.', 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=900&q=80'),
    ('Vestido satinado', 'Luna Alta', 'Nerea', 'Vestidos', 280::numeric, 'Vestido ligero con caida suave para noche.', 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=80'),
    ('Jean tiro alto', 'Denim Sur', 'Andes', 'Jeans', 210::numeric, 'Jean clasico de tiro alto con elastano.', 'https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=900&q=80'),
    ('Camisa seda fria', 'Atelier Sol', 'Brisa', 'Camisas', 185::numeric, 'Camisa fresca para trabajo y salida casual.', 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?auto=format&fit=crop&w=900&q=80'),
    ('Polera basica premium', 'Norte', 'Essential', 'Poleras', 95::numeric, 'Polera de algodon peinado para uso diario.', 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=900&q=80'),
    ('Chamarra urbana', 'Altiplano', 'Nox', 'Chamarras', 390::numeric, 'Chamarra liviana para temporada fria.', 'https://images.unsplash.com/photo-1506629905607-d9d297dca5e9?auto=format&fit=crop&w=900&q=80')
  ) as p(name, brand, model, category_name, price, description, image_url)
)
insert into public.products (category_id, name, brand, model, description, base_price, image_url)
select c.id, p.name, p.brand, p.model, p.description, p.price, p.image_url
from demo_products p
join public.categories c on c.name = p.category_name
where not exists (
  select 1
  from public.products existing
  where existing.name = p.name
    and existing.brand = p.brand
    and coalesce(existing.model, '') = p.model
);

with variant_seed as (
  select *
  from (values
    ('Blazer lino premium', 'S', 'Negro', '#171717', 4, 2),
    ('Blazer lino premium', 'M', 'Negro', '#171717', 8, 2),
    ('Blazer lino premium', 'L', 'Azul petroleo', '#164E63', 2, 2),
    ('Vestido satinado', 'XS', 'Rosa vino', '#9F1239', 1, 2),
    ('Vestido satinado', 'S', 'Rosa vino', '#9F1239', 5, 2),
    ('Vestido satinado', 'M', 'Champagne', '#D6BD98', 6, 2),
    ('Jean tiro alto', '36', 'Azul denim', '#1D4ED8', 7, 2),
    ('Jean tiro alto', '38', 'Azul denim', '#1D4ED8', 9, 2),
    ('Jean tiro alto', '40', 'Grafito', '#374151', 3, 2),
    ('Camisa seda fria', 'S', 'Blanco', '#F8FAFC', 6, 2),
    ('Camisa seda fria', 'M', 'Mostaza', '#CA8A04', 2, 2),
    ('Camisa seda fria', 'L', 'Mostaza', '#CA8A04', 1, 2),
    ('Polera basica premium', 'S', 'Blanco', '#F8FAFC', 10, 3),
    ('Polera basica premium', 'M', 'Negro', '#171717', 12, 3),
    ('Chamarra urbana', 'M', 'Olivo', '#3F6212', 4, 2),
    ('Chamarra urbana', 'L', 'Negro', '#171717', 3, 2)
  ) as v(product_name, size, color_name, color_hex, stock, min_stock)
)
insert into public.product_variants (
  product_id,
  size,
  color_name,
  color_hex,
  stock,
  min_stock
)
select p.id, v.size, v.color_name, v.color_hex, v.stock, v.min_stock
from variant_seed v
join public.products p on p.name = v.product_name
on conflict (product_id, size, color_name) do update
set stock = excluded.stock,
    min_stock = excluded.min_stock,
    color_hex = excluded.color_hex;

commit;

select 'Funciones operativas listas' as status;
select name, image_url from public.products where image_url is not null order by created_at desc limit 6;
