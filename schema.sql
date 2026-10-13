-- Búsqueda de Juan · esquema de base de datos
-- Pegar entero en Supabase → SQL Editor → Run.
--
-- Seguridad: las tablas quedan cerradas para el público (RLS sin políticas).
-- La página solo accede a través de funciones que piden la contraseña.
-- Sin la contraseña, la clave pública de Supabase no puede leer ni escribir nada.

create table if not exists tasks (
  id         text primary key,
  week       int  not null,
  sort_order int  not null default 0,
  title      text not null,
  note       text,
  detail     jsonb not null default '[]'::jsonb,
  done       boolean not null default false,
  done_at    date
);

create table if not exists apps (
  id         uuid primary key default gen_random_uuid(),
  company    text not null,
  role       text,
  link       text,
  stage      text not null default 'identificada'
             check (stage in ('identificada','enviada','entrevista','oferta','descartada')),
  source     text not null default 'manual',
  date       date not null default current_date
);

create table if not exists contacts (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  company    text,
  role       text,
  channel    text,
  status     text not null default 'Por contactar'
             check (status in ('Por contactar','Contactado','Respondió','Reunión')),
  date       date not null default current_date
);

create table if not exists app_secret (
  id   int primary key default 1 check (id = 1),
  pass text not null
);

alter table tasks      enable row level security;
alter table apps       enable row level security;
alter table contacts   enable row level security;
alter table app_secret enable row level security;

-- Contraseña compartida entre Karen y Juan. CAMBIALA antes de correr el script.
insert into app_secret (id, pass) values (1, 'robertodawney')
on conflict (id) do update set pass = excluded.pass;

-- Chequeo de contraseña
create or replace function _check(p text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p is null or p <> (select pass from app_secret where id = 1) then
    raise exception 'clave_incorrecta' using errcode = '28000';
  end if;
end $$;

-- Lectura completa del tablero
create or replace function get_board(p text) returns json
language plpgsql security definer set search_path = public as $$
begin
  perform _check(p);
  return json_build_object(
    'tasks',    coalesce((select json_agg(t order by t.week, t.sort_order) from tasks t), '[]'),
    'apps',     coalesce((select json_agg(a order by a.date desc) from apps a), '[]'),
    'contacts', coalesce((select json_agg(c order by c.date desc) from contacts c), '[]')
  );
end $$;

-- Tareas
create or replace function set_task_done(p text, task_id text, is_done boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check(p);
  update tasks set done = is_done, done_at = case when is_done then current_date end where id = task_id;
end $$;

-- Postulaciones
create or replace function add_app(p text, a_company text, a_role text, a_link text, a_stage text) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check(p);
  insert into apps (company, role, link, stage) values (a_company, nullif(a_role,''), nullif(a_link,''), a_stage);
end $$;

create or replace function set_app_stage(p text, app_id uuid, a_stage text) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check(p);
  update apps set stage = a_stage, date = current_date where id = app_id;
end $$;

create or replace function delete_app(p text, app_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check(p);
  delete from apps where id = app_id;
end $$;

-- Contactos
create or replace function add_contact(p text, c_name text, c_company text, c_role text, c_channel text) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check(p);
  insert into contacts (name, company, role, channel) values (c_name, nullif(c_company,''), nullif(c_role,''), c_channel);
end $$;

create or replace function set_contact_status(p text, contact_id uuid, c_status text) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check(p);
  update contacts set status = c_status, date = current_date where id = contact_id;
end $$;

create or replace function delete_contact(p text, contact_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check(p);
  delete from contacts where id = contact_id;
end $$;

-- Permisos: el público solo puede llamar las funciones, nunca tocar tablas.
revoke all on function _check(text) from public, anon, authenticated;
grant execute on function get_board(text)                                to anon;
grant execute on function set_task_done(text, text, boolean)             to anon;
grant execute on function add_app(text, text, text, text, text)          to anon;
grant execute on function set_app_stage(text, uuid, text)                to anon;
grant execute on function delete_app(text, uuid)                         to anon;
grant execute on function add_contact(text, text, text, text, text)      to anon;
grant execute on function set_contact_status(text, uuid, text)           to anon;
grant execute on function delete_contact(text, uuid)                     to anon;
