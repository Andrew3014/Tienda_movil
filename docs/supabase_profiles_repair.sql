-- Reparacion directa de perfiles para los tres usuarios existentes.
-- Busca los UUID por email, crea/actualiza profiles y verifica el resultado.

grant usage on schema public to anon, authenticated;
grant execute on function public.current_user_role() to authenticated;

grant select on public.categories, public.products, public.product_variants
to anon, authenticated;

grant select, insert, update, delete on
  public.profiles,
  public.categories,
  public.products,
  public.product_variants,
  public.cash_registers,
  public.sales,
  public.sale_items,
  public.payments,
  public.cash_movements
to authenticated;

insert into public.profiles (id, full_name, role)
select id, 'Administrador General', 'admin'::public.user_role
from auth.users
where email = 'admin@mitienda.bo'
on conflict (id) do update
set full_name = excluded.full_name, role = excluded.role;

insert into public.profiles (id, full_name, role)
select id, 'Vendedor Caja', 'seller'::public.user_role
from auth.users
where email = 'ventas@mitienda.bo'
on conflict (id) do update
set full_name = excluded.full_name, role = excluded.role;

insert into public.profiles (id, full_name, role)
select id, 'Cliente Demo', 'customer'::public.user_role
from auth.users
where email = 'cliente@mitienda.bo'
on conflict (id) do update
set full_name = excluded.full_name, role = excluded.role;

drop policy if exists "profiles_read_own_or_staff" on public.profiles;

create policy "profiles_read_own_or_staff"
on public.profiles for select
to authenticated
using (
  id = auth.uid()
  or public.current_user_role() in ('admin', 'seller')
);

select
  users.email,
  profiles.id,
  profiles.full_name,
  profiles.role
from auth.users as users
left join public.profiles as profiles on profiles.id = users.id
where users.email in (
  'admin@mitienda.bo',
  'ventas@mitienda.bo',
  'cliente@mitienda.bo'
)
order by users.email;
