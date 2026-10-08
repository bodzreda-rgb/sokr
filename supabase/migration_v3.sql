-- =====================================================================
-- SOKR - MIGRATION v3 (yt3ml run BA3D supabase_schema.sql)
-- - doctor accounts (schedule + accept/reject + diet plans)
-- - gym plans (as3ar el eshterakat) + gym subscriptions
-- - bucket lel sowar (el admin yrf3 sowar el adwya...)
-- - fix el signup (confirm lel users el adema)
-- el file momken yt3ml run aktar men mara
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0) fix el signup: bn-confirm ay user ma-et-confirm-sh
-- ---------------------------------------------------------------------
update auth.users set email_confirmed_at = now() where email_confirmed_at is null;

-- ---------------------------------------------------------------------
-- 1) role gedid: doctor
-- ---------------------------------------------------------------------
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('patient','doctor','admin'));

-- el doctor row momken ykon marboot b account (profile_id)
alter table public.doctors add column if not exists profile_id uuid unique
  references public.profiles(id) on delete set null;

-- btrg3 el doctors.id beta3 el user el 7ali (law howa doctor)
create or replace function public.my_doctor_id()
returns uuid language sql stable security definer set search_path = public as $$
  select id from public.doctors where profile_id = auth.uid() limit 1;
$$;

-- hal el patient da 3ando appointment m3 el doctor el 7ali?
create or replace function public.is_my_patient(p_patient uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.appointments a
    where a.patient_id = p_patient and a.doctor_id = public.my_doctor_id()
  );
$$;

-- lama el admin yrbot account b doctor, el role byt8yr le doctor automatic
create or replace function public.sync_doctor_role()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' and old.profile_id is not null and old.profile_id is distinct from new.profile_id then
    update public.profiles set role = 'patient' where id = old.profile_id and role = 'doctor';
  end if;
  if new.profile_id is not null then
    update public.profiles set role = 'doctor' where id = new.profile_id and role <> 'admin';
  end if;
  return new;
end;
$$;

drop trigger if exists doctors_sync_role on public.doctors;
create trigger doctors_sync_role
  after insert or update of profile_id on public.doctors
  for each row execute function public.sync_doctor_role();

-- ---------- doctor policies ----------
drop policy if exists "doctor_update_own" on public.doctors;
create policy "doctor_update_own" on public.doctors for update to authenticated
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- el doctor y-edit el schedule bta3o
drop policy if exists "availability_doctor_manage" on public.doctor_availability;
create policy "availability_doctor_manage" on public.doctor_availability for all to authenticated
  using (doctor_id = public.my_doctor_id()) with check (doctor_id = public.my_doctor_id());

-- el doctor yshof w y-accept / reject el 7ogozat beta3to
drop policy if exists "appointments_doctor_select" on public.appointments;
create policy "appointments_doctor_select" on public.appointments for select to authenticated
  using (doctor_id = public.my_doctor_id());
drop policy if exists "appointments_doctor_update" on public.appointments;
create policy "appointments_doctor_update" on public.appointments for update to authenticated
  using (doctor_id = public.my_doctor_id()) with check (doctor_id = public.my_doctor_id());

-- el doctor yshof profiles el patients beta3to bas
drop policy if exists "profiles_doctor_select" on public.profiles;
create policy "profiles_doctor_select" on public.profiles for select to authenticated
  using (public.is_my_patient(id));

-- el doctor yshof qeyasat el patients beta3to (read only)
drop policy if exists "metrics_doctor_read" on public.health_metrics;
create policy "metrics_doctor_read" on public.health_metrics for select to authenticated
  using (public.is_my_patient(patient_id));

-- el doctor yekteb roshetta lel patients beta3to
drop policy if exists "prescriptions_doctor_all" on public.prescriptions;
create policy "prescriptions_doctor_all" on public.prescriptions for all to authenticated
  using (doctor_id = public.my_doctor_id())
  with check (doctor_id = public.my_doctor_id() and public.is_my_patient(patient_id));

-- ---------------------------------------------------------------------
-- 2) DIET PLANS: el doctor y3ml diet lel patient men el akl elly f el app
-- ---------------------------------------------------------------------
create table if not exists public.diet_plans (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  title text not null,
  notes text default '',
  created_at timestamptz not null default now()
);

create table if not exists public.diet_plan_items (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.diet_plans(id) on delete cascade,
  food_item_id uuid not null references public.food_items(id) on delete cascade,
  meal text not null default 'Lunch' check (meal in ('Breakfast','Lunch','Dinner','Snack')),
  notes text default ''
);
create index if not exists diet_plans_patient_idx on public.diet_plans (patient_id);
create index if not exists diet_plan_items_plan_idx on public.diet_plan_items (plan_id);

alter table public.diet_plans enable row level security;
alter table public.diet_plan_items enable row level security;

drop policy if exists "diet_patient_select" on public.diet_plans;
create policy "diet_patient_select" on public.diet_plans for select to authenticated
  using (patient_id = auth.uid());
drop policy if exists "diet_doctor_all" on public.diet_plans;
create policy "diet_doctor_all" on public.diet_plans for all to authenticated
  using (doctor_id = public.my_doctor_id())
  with check (doctor_id = public.my_doctor_id() and public.is_my_patient(patient_id));

drop policy if exists "diet_items_select" on public.diet_plan_items;
create policy "diet_items_select" on public.diet_plan_items for select to authenticated
  using (exists (select 1 from public.diet_plans p where p.id = plan_id
    and (p.patient_id = auth.uid() or p.doctor_id = public.my_doctor_id())));
drop policy if exists "diet_items_doctor_all" on public.diet_plan_items;
create policy "diet_items_doctor_all" on public.diet_plan_items for all to authenticated
  using (exists (select 1 from public.diet_plans p where p.id = plan_id and p.doctor_id = public.my_doctor_id()))
  with check (exists (select 1 from public.diet_plans p where p.id = plan_id and p.doctor_id = public.my_doctor_id()));

-- ---------------------------------------------------------------------
-- 3) GYM PLANS (el admin y8yr el as3ar) + SUBSCRIPTIONS
-- ---------------------------------------------------------------------
create table if not exists public.gym_plans (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms(id) on delete cascade,
  name text not null,
  duration_months int not null default 1 check (duration_months > 0),
  price numeric(10,2) not null check (price >= 0),
  description text default '',
  created_at timestamptz not null default now()
);

create table if not exists public.gym_subscriptions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  gym_id uuid not null references public.gyms(id) on delete cascade,
  plan_id uuid references public.gym_plans(id) on delete set null,
  plan_name text not null,
  price numeric(10,2) not null,
  start_date date not null default current_date,
  end_date date not null,
  status text not null default 'active' check (status in ('pending','active','cancelled','expired')),
  created_at timestamptz not null default now()
);
create index if not exists gym_plans_gym_idx on public.gym_plans (gym_id);
create index if not exists gym_subs_patient_idx on public.gym_subscriptions (patient_id);

alter table public.gym_plans enable row level security;
alter table public.gym_subscriptions enable row level security;

drop policy if exists "gym_plans_read" on public.gym_plans;
create policy "gym_plans_read" on public.gym_plans for select to authenticated using (true);
drop policy if exists "gym_subs_own_select" on public.gym_subscriptions;
create policy "gym_subs_own_select" on public.gym_subscriptions for select to authenticated
  using (patient_id = auth.uid());
drop policy if exists "gym_subs_own_cancel" on public.gym_subscriptions;
create policy "gym_subs_own_cancel" on public.gym_subscriptions for update to authenticated
  using (patient_id = auth.uid() and status in ('pending','active'))
  with check (patient_id = auth.uid() and status = 'cancelled');

-- hena el patient by-subscribe: el se3r w el tarekh byt7sbo men el DB
create or replace function public.subscribe_gym(p_plan uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_plan record;
  v_id uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  select * into v_plan from public.gym_plans where id = p_plan;
  if not found then raise exception 'Plan not found'; end if;
  insert into public.gym_subscriptions (patient_id, gym_id, plan_id, plan_name, price, start_date, end_date)
  values (auth.uid(), v_plan.gym_id, v_plan.id, v_plan.name, v_plan.price,
          current_date, current_date + make_interval(months => v_plan.duration_months))
  returning id into v_id;
  return v_id;
end;
$$;
grant execute on function public.subscribe_gym(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 4) el admin by-edit kol el tables el gedida
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['diet_plans','diet_plan_items','gym_plans','gym_subscriptions'] loop
    execute format('drop policy if exists "admin_all" on public.%I', t);
    execute format(
      'create policy "admin_all" on public.%I for all to authenticated using (public.is_admin()) with check (public.is_admin())', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 5) STORAGE: bucket public lel sowar (adwya, doctors, gyms, akl...)
--    ay 7ad yshof, el admin bas yrf3 / yms7
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('app-images', 'app-images', true)
on conflict (id) do update set public = true;

drop policy if exists "app_images_read" on storage.objects;
drop policy if exists "app_images_admin_insert" on storage.objects;
drop policy if exists "app_images_admin_update" on storage.objects;
drop policy if exists "app_images_admin_delete" on storage.objects;
create policy "app_images_read" on storage.objects for select
  using (bucket_id = 'app-images');
create policy "app_images_admin_insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'app-images' and public.is_admin());
create policy "app_images_admin_update" on storage.objects for update to authenticated
  using (bucket_id = 'app-images' and public.is_admin());
create policy "app_images_admin_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'app-images' and public.is_admin());

-- ---------------------------------------------------------------------
-- 6) SEED: doctor account + gym plans + diet plan demo
-- ---------------------------------------------------------------------
do $$
declare
  v_doc_user uuid;
  v_doc uuid;
  v_patient uuid;
  v_plan uuid;
begin
  -- doctor@demo.com marboot b Dr. Sarah Johnson (password: Demo@1234)
  v_doc_user := public.create_demo_user('doctor@demo.com', 'Dr. Sarah Johnson');
  update public.doctors set profile_id = v_doc_user where full_name = 'Dr. Sarah Johnson';
  select id into v_doc from public.doctors where profile_id = v_doc_user;

  -- as3ar el gyms (law mafish plans lessa)
  if not exists (select 1 from public.gym_plans) then
    insert into public.gym_plans (gym_id, name, duration_months, price, description)
    select g.id, p.name, p.months, round(p.base * (0.8 + g.rating / 10.0)), p.descr
    from public.gyms g
    cross join (values
      ('Monthly', 1, 600, 'Full access for one month'),
      ('3 Months', 3, 1600, 'Save more with 3 months'),
      ('Yearly', 12, 5500, 'Best value for one year')
    ) as p(name, months, base, descr);
  end if;

  -- diet plan demo men Dr. Sarah lel patient
  select id into v_patient from public.profiles where email = 'patient@demo.com';
  if v_patient is not null and v_doc is not null
     and not exists (select 1 from public.diet_plans where patient_id = v_patient) then
    insert into public.diet_plans (patient_id, doctor_id, title, notes)
    values (v_patient, v_doc, 'Heart-friendly week', 'Low salt, more vegetables. Drink 2 liters of water daily.')
    returning id into v_plan;
    insert into public.diet_plan_items (plan_id, food_item_id, meal)
    select v_plan, f.id, m.meal
    from (values ('Oatmeal Bowl','Breakfast'), ('Grilled Chicken Salad','Lunch'),
                 ('Salmon & Brown Rice','Dinner'), ('Greek Yogurt Parfait','Snack')) as m(food, meal)
    join public.food_items f on f.name = m.food;
  end if;
end $$;
