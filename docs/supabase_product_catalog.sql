-- Catalogo real con imagenes para administrador y vendedor.
-- Ejecutar completo en Supabase SQL Editor una sola vez.

begin;

alter table public.products
add column if not exists image_url text;

grant usage on schema public to anon, authenticated;
grant execute on function public.current_user_role() to authenticated;
grant select on public.categories, public.products, public.product_variants
to anon, authenticated;
grant insert, update, delete on
  public.categories,
  public.products,
  public.product_variants
to authenticated;

drop policy if exists "staff_manage_categories" on public.categories;
drop policy if exists "staff_manage_products" on public.products;
drop policy if exists "staff_manage_variants" on public.product_variants;

create policy "staff_manage_categories"
on public.categories for all
to authenticated
using (public.current_user_role() in ('admin', 'seller'))
with check (public.current_user_role() in ('admin', 'seller'));

create policy "staff_manage_products"
on public.products for all
to authenticated
using (public.current_user_role() in ('admin', 'seller'))
with check (public.current_user_role() in ('admin', 'seller'));

create policy "staff_manage_variants"
on public.product_variants for all
to authenticated
using (public.current_user_role() in ('admin', 'seller'))
with check (public.current_user_role() in ('admin', 'seller'));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "public_read_product_images" on storage.objects;
drop policy if exists "staff_upload_product_images" on storage.objects;
drop policy if exists "staff_update_product_images" on storage.objects;
drop policy if exists "staff_delete_product_images" on storage.objects;

create policy "public_read_product_images"
on storage.objects for select
to public
using (bucket_id = 'product-images');

create policy "staff_upload_product_images"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'product-images'
  and public.current_user_role() in ('admin', 'seller')
);

create policy "staff_update_product_images"
on storage.objects for update
to authenticated
using (
  bucket_id = 'product-images'
  and public.current_user_role() in ('admin', 'seller')
)
with check (
  bucket_id = 'product-images'
  and public.current_user_role() in ('admin', 'seller')
);

create policy "staff_delete_product_images"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'product-images'
  and public.current_user_role() in ('admin', 'seller')
);

commit;

select
  column_name,
  data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'products'
  and column_name = 'image_url';

select id, name, public, file_size_limit
from storage.buckets
where id = 'product-images';
