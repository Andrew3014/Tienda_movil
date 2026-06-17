-- Esquema inicial para Mi Tienda Boutique en Supabase/PostgreSQL.
-- Ejecutar en el SQL Editor de Supabase cuando se cree el backend.

create extension if not exists "pgcrypto";

create type public.user_role as enum ('admin', 'seller', 'customer');
create type public.payment_method as enum ('cash', 'qr', 'card', 'transfer');
create type public.sale_status as enum ('draft', 'paid', 'cancelled');
create type public.cash_movement_type as enum ('opening', 'income', 'expense', 'closing');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  phone text,
  role public.user_role not null default 'customer',
  created_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories (id) on delete set null,
  name text not null,
  brand text not null,
  model text,
  description text,
  base_price numeric(12, 2) not null check (base_price >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  size text not null,
  color_name text not null,
  color_hex text,
  sku text unique,
  stock integer not null default 0 check (stock >= 0),
  min_stock integer not null default 2 check (min_stock >= 0),
  created_at timestamptz not null default now(),
  unique (product_id, size, color_name)
);

create table public.cash_registers (
  id uuid primary key default gen_random_uuid(),
  opened_by uuid not null references public.profiles (id),
  closed_by uuid references public.profiles (id),
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  opening_amount numeric(12, 2) not null default 0,
  closing_amount numeric(12, 2),
  note text
);

create table public.sales (
  id uuid primary key default gen_random_uuid(),
  cash_register_id uuid references public.cash_registers (id),
  customer_id uuid references public.profiles (id),
  seller_id uuid references public.profiles (id),
  status public.sale_status not null default 'draft',
  subtotal numeric(12, 2) not null default 0,
  discount numeric(12, 2) not null default 0,
  total numeric(12, 2) not null default 0,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

create table public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales (id) on delete cascade,
  variant_id uuid not null references public.product_variants (id),
  quantity integer not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  total numeric(12, 2) not null check (total >= 0)
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales (id) on delete cascade,
  method public.payment_method not null,
  amount numeric(12, 2) not null check (amount > 0),
  qr_reference text,
  paid_at timestamptz not null default now()
);

create table public.cash_movements (
  id uuid primary key default gen_random_uuid(),
  cash_register_id uuid not null references public.cash_registers (id) on delete cascade,
  created_by uuid not null references public.profiles (id),
  movement_type public.cash_movement_type not null,
  amount numeric(12, 2) not null,
  description text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.cash_registers enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.payments enable row level security;
alter table public.cash_movements enable row level security;

create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

create policy "profiles_read_own_or_staff"
on public.profiles for select
using (id = auth.uid() or public.current_user_role() in ('admin', 'seller'));

create policy "admin_manage_profiles"
on public.profiles for all
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

create policy "catalog_public_read"
on public.categories for select
using (true);

create policy "products_public_read"
on public.products for select
using (active = true);

create policy "variants_public_read"
on public.product_variants for select
using (true);

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
using (customer_id = auth.uid() or public.current_user_role() in ('admin', 'seller'));

create policy "staff_manage_sales"
on public.sales for all
using (public.current_user_role() in ('admin', 'seller'))
with check (public.current_user_role() in ('admin', 'seller'));

create policy "customer_create_own_sales"
on public.sales for insert
with check (customer_id = auth.uid() and status = 'draft');

create policy "customer_update_own_draft_sales"
on public.sales for update
using (customer_id = auth.uid() and status = 'draft')
with check (customer_id = auth.uid() and status = 'draft');

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
