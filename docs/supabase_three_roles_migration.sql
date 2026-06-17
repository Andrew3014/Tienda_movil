-- Migracion para el proyecto Supabase existente.
-- Mantiene solo los roles usados por la app: admin, seller y customer.
-- Puede ejecutarse completo en SQL Editor.

begin;

insert into public.profiles (id, full_name, role)
values
  ('8f38d94b-4a9f-4f34-b900-d42e4d0a811d', 'Administrador General', 'admin'),
  ('37ffe5a9-ee15-4607-adc0-931b9edd4d4e', 'Vendedor Caja', 'seller'),
  ('ac3b5a5e-962e-4285-9f2d-40d02ecc5cb1', 'Cliente Demo', 'customer')
on conflict (id) do update
set
  full_name = excluded.full_name,
  role = excluded.role;

drop policy if exists "profiles_read_own_or_staff" on public.profiles;
drop policy if exists "admin_manage_profiles" on public.profiles;
drop policy if exists "staff_manage_categories" on public.categories;
drop policy if exists "staff_manage_products" on public.products;
drop policy if exists "staff_manage_variants" on public.product_variants;
drop policy if exists "customers_read_own_sales" on public.sales;
drop policy if exists "staff_manage_sales" on public.sales;
drop policy if exists "staff_manage_sale_items" on public.sale_items;
drop policy if exists "staff_manage_payments" on public.payments;
drop policy if exists "staff_manage_cash_registers" on public.cash_registers;
drop policy if exists "staff_manage_cash_movements" on public.cash_movements;
drop policy if exists "customer_create_own_sales" on public.sales;
drop policy if exists "customer_update_own_draft_sales" on public.sales;
drop policy if exists "customer_read_own_sale_items" on public.sale_items;
drop policy if exists "customer_manage_own_draft_sale_items" on public.sale_items;
drop policy if exists "customer_read_own_payments" on public.payments;

create policy "profiles_read_own_or_staff"
on public.profiles for select
using (
  id = auth.uid()
  or public.current_user_role() in ('admin', 'seller')
);

create policy "admin_manage_profiles"
on public.profiles for all
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

create policy "staff_manage_categories"
on public.categories for all
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

create policy "staff_manage_products"
on public.products for all
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

create policy "staff_manage_variants"
on public.product_variants for all
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

create policy "customers_read_own_sales"
on public.sales for select
using (
  customer_id = auth.uid()
  or public.current_user_role() in ('admin', 'seller')
);

create policy "staff_manage_sales"
on public.sales for all
using (public.current_user_role() in ('admin', 'seller'))
with check (public.current_user_role() in ('admin', 'seller'));

create policy "customer_create_own_sales"
on public.sales for insert
with check (
  customer_id = auth.uid()
  and status = 'draft'
);

create policy "customer_update_own_draft_sales"
on public.sales for update
using (
  customer_id = auth.uid()
  and status = 'draft'
)
with check (
  customer_id = auth.uid()
  and status = 'draft'
);

create policy "staff_manage_sale_items"
on public.sale_items for all
using (public.current_user_role() in ('admin', 'seller'))
with check (public.current_user_role() in ('admin', 'seller'));

create policy "customer_read_own_sale_items"
on public.sale_items for select
using (
  exists (
    select 1
    from public.sales
    where sales.id = sale_items.sale_id
      and sales.customer_id = auth.uid()
  )
);

create policy "customer_manage_own_draft_sale_items"
on public.sale_items for all
using (
  exists (
    select 1
    from public.sales
    where sales.id = sale_items.sale_id
      and sales.customer_id = auth.uid()
      and sales.status = 'draft'
  )
)
with check (
  exists (
    select 1
    from public.sales
    where sales.id = sale_items.sale_id
      and sales.customer_id = auth.uid()
      and sales.status = 'draft'
  )
);

create policy "staff_manage_payments"
on public.payments for all
using (public.current_user_role() in ('admin', 'seller'))
with check (public.current_user_role() in ('admin', 'seller'));

create policy "customer_read_own_payments"
on public.payments for select
using (
  exists (
    select 1
    from public.sales
    where sales.id = payments.sale_id
      and sales.customer_id = auth.uid()
  )
);

create policy "staff_manage_cash_registers"
on public.cash_registers for all
using (public.current_user_role() in ('admin', 'seller'))
with check (public.current_user_role() in ('admin', 'seller'));

create policy "staff_manage_cash_movements"
on public.cash_movements for all
using (public.current_user_role() in ('admin', 'seller'))
with check (public.current_user_role() in ('admin', 'seller'));

commit;
