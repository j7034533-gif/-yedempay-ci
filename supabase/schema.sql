create extension if not exists pgcrypto;
create schema if not exists private;

create table if not exists public.schools(id uuid primary key default gen_random_uuid(),name text not null,directeur text not null,telephone text,adresse text,created_at timestamptz not null default now());
create table if not exists public.classes(id uuid primary key default gen_random_uuid(),school_id uuid not null references public.schools(id) on delete cascade,nom text not null,frais_scolarite_total numeric(12,2) not null default 0,created_at timestamptz not null default now());
create table if not exists public.students(id uuid primary key default gen_random_uuid(),school_id uuid not null references public.schools(id) on delete cascade,class_id uuid references public.classes(id) on delete set null,nom_complet text not null,matricule text not null,nom_parent text not null,telephone_parent text not null,created_at timestamptz not null default now(),unique(school_id,matricule));
create table if not exists public.paiements(id uuid primary key default gen_random_uuid(),student_id uuid not null references public.students(id) on delete cascade,montant_paye numeric(12,2) not null check(montant_paye>0),date_paiement timestamptz not null default now(),mode_paiement text not null,mois_concerne text not null,recu_numero text unique not null,created_at timestamptz not null default now());
create table if not exists public.annee_scolaire(id uuid primary key default gen_random_uuid(),libelle text not null unique,status text not null default 'inactive',created_at timestamptz not null default now());
create table if not exists public.school_users(user_id uuid primary key references auth.users(id) on delete cascade,school_id uuid not null references public.schools(id) on delete cascade,role text not null default 'directeur',created_at timestamptz not null default now());

create or replace function private.my_school_id() returns uuid language sql stable security definer set search_path=public,private as $$ select school_id from public.school_users where user_id=(select auth.uid()) limit 1 $$;
create or replace function private.is_school_member(school uuid) returns boolean language sql stable security definer set search_path=public,private as $$ select exists(select 1 from public.school_users where user_id=(select auth.uid()) and school_id=school) $$;
grant execute on function private.my_school_id() to authenticated;
grant execute on function private.is_school_member(uuid) to authenticated;
revoke all on function private.my_school_id() from public,anon;
revoke all on function private.is_school_member(uuid) from public,anon;

create or replace function private.handle_new_school_user() returns trigger language plpgsql security definer set search_path=public,private as $$
declare sid uuid;
begin
 insert into public.schools(name,directeur,telephone,adresse) values(coalesce(new.raw_user_meta_data->>'school_name','École'),coalesce(new.raw_user_meta_data->>'directeur','Directeur'),new.raw_user_meta_data->>'telephone',new.raw_user_meta_data->>'adresse') returning id into sid;
 insert into public.school_users(user_id,school_id,role) values(new.id,sid,'directeur') on conflict (user_id) do nothing;
 return new;
end; $$;
revoke all on function private.handle_new_school_user() from public,anon,authenticated;
drop trigger if exists on_auth_user_created_yedempay on auth.users;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created_yedempay after insert on auth.users for each row execute function private.handle_new_school_user();

alter table public.schools enable row level security;
alter table public.classes enable row level security;
alter table public.students enable row level security;
alter table public.paiements enable row level security;
alter table public.annee_scolaire enable row level security;
alter table public.school_users enable row level security;

drop policy if exists "authenticated create school" on public.schools;
create policy schools_isolation on public.schools for all to authenticated using(id=private.my_school_id()) with check(id=private.my_school_id());
create policy classes_isolation on public.classes for all to authenticated using(school_id=private.my_school_id()) with check(school_id=private.my_school_id());
create policy students_isolation on public.students for all to authenticated using(school_id=private.my_school_id()) with check(school_id=private.my_school_id());
create policy payments_isolation on public.paiements for all to authenticated using(exists(select 1 from public.students s where s.id=student_id and s.school_id=private.my_school_id())) with check(exists(select 1 from public.students s where s.id=student_id and s.school_id=private.my_school_id()));
create policy school_users_self on public.school_users for select to authenticated using(user_id=(select auth.uid()));
create policy academic_year_read on public.annee_scolaire for select to authenticated using(true);
