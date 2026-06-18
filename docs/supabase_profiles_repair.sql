-- Reparacion directa de perfiles para los tres usuarios existentes.
-- Busca los UUID por email, crea/actualiza profiles y verifica el resultado.

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
