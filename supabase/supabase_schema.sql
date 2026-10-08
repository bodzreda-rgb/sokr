-- =====================================================================
-- SOKR - سكر : SUPABASE SCHEMA
-- 7ot el file da kolo f: Supabase Dashboard -> SQL Editor -> Run
-- el file momken yt3ml run aktar men mara (bey3ml drop lel 7agat el adema)
--
-- el roles: patient (el user el 3adi) + admin (by-edit/add/delete kol 7aga)
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- 0) CLEANUP
-- ---------------------------------------------------------------------
-- bnms7 kol el users elly msh patients (el doctors / pharmacist / gym / restaurant el adema)
delete from auth.users
where coalesce(raw_user_meta_data->>'role', 'patient') <> 'patient'
  and email <> 'admin@demo.com';

drop trigger if exists on_auth_user_created on auth.users;
drop table if exists public.food_order_items cascade;
drop table if exists public.food_orders cascade;
drop table if exists public.favorites cascade;
drop table if exists public.prescriptions cascade;
drop table if exists public.health_metrics cascade;
drop table if exists public.medical_records cascade;
drop table if exists public.food_items cascade;
drop table if exists public.restaurants cascade;
drop table if exists public.gym_exercises cascade;
drop table if exists public.gyms cascade;
drop table if exists public.exercises cascade;
drop table if exists public.medicine_order_items cascade;
drop table if exists public.medicine_orders cascade;
drop table if exists public.medicines cascade;
drop table if exists public.pharmacies cascade;
drop table if exists public.appointments cascade;
drop table if exists public.doctor_availability cascade;
drop table if exists public.doctors cascade;
drop table if exists public.profiles cascade;
drop function if exists public.my_doctor_id() cascade;
drop function if exists public.my_role() cascade;
drop function if exists public.owns_pharmacy(uuid) cascade;
drop function if exists public.owns_gym(uuid) cascade;
drop function if exists public.owns_restaurant(uuid) cascade;
drop function if exists public.is_my_patient(uuid) cascade;
drop function if exists public.is_my_customer(uuid) cascade;
drop function if exists public.create_demo_user(text, text, text, text) cascade;

-- =====================================================================
-- 1) TABLES
-- =====================================================================

-- da table el profiles: kol user leh row wa7ed (patient aw admin)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text,
  phone text,
  role text not null default 'patient' check (role in ('patient','admin')),
  avatar_url text,
  created_at timestamptz not null default now()
);

-- el doctors (data bas, el admin howa elly byd5lha)
create table public.doctors (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  phone text,
  avatar_url text,
  specialization text not null default 'General Practitioner',
  bio text default '',
  years_experience int not null default 0,
  consultation_price numeric(10,2) not null default 0,
  clinic_name text default '',
  clinic_address text default '',
  latitude double precision,
  longitude double precision,
  rating numeric(2,1) not null default 0,
  is_available boolean not null default true,
  created_at timestamptz not null default now()
);

-- mawa3eed el doctor (day_of_week: 0 = Sunday ... 6 = Saturday)
create table public.doctor_availability (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  day_of_week int not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  is_available boolean not null default true,
  check (end_time > start_time)
);

-- el 7ogozat
create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  appointment_date date not null,
  appointment_time time not null,
  status text not null default 'pending'
    check (status in ('pending','confirmed','completed','cancelled','rejected')),
  notes text,
  created_at timestamptz not null default now()
);

create table public.pharmacies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  address text default '',
  latitude double precision,
  longitude double precision,
  phone text,
  image_url text,
  is_open boolean not null default true,
  rating numeric(2,1) not null default 0,
  created_at timestamptz not null default now()
);

create table public.medicines (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  name text not null,
  description text default '',
  category text default 'General',
  price numeric(10,2) not null check (price >= 0),
  stock_quantity int not null default 0 check (stock_quantity >= 0),
  image_url text,
  prescription_required boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.medicine_orders (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  total_price numeric(10,2) not null default 0,
  status text not null default 'pending'
    check (status in ('pending','preparing','out_for_delivery','completed','cancelled')),
  delivery_address text not null,
  phone text,
  notes text,
  created_at timestamptz not null default now()
);

create table public.medicine_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.medicine_orders(id) on delete cascade,
  medicine_id uuid references public.medicines(id) on delete set null,
  quantity int not null check (quantity > 0),
  price numeric(10,2) not null
);

create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  category text not null default 'Home Workout',
  difficulty text not null default 'Beginner',
  duration_minutes int not null default 10,
  calories int not null default 50,
  image_url text,
  video_url text,
  created_at timestamptz not null default now()
);

create table public.gyms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  address text default '',
  latitude double precision,
  longitude double precision,
  phone text,
  rating numeric(2,1) not null default 0,
  image_url text,
  created_at timestamptz not null default now()
);

create table public.gym_exercises (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null references public.gyms(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete cascade,
  unique (gym_id, exercise_id)
);

create table public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  address text default '',
  latitude double precision,
  longitude double precision,
  phone text,
  rating numeric(2,1) not null default 0,
  image_url text,
  is_open boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.food_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  description text default '',
  price numeric(10,2) not null check (price >= 0),
  calories int default 0,
  protein int default 0,
  carbs int default 0,
  fats int default 0,
  category text default 'Healthy',
  image_url text,
  is_healthy boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.food_orders (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  total_price numeric(10,2) not null default 0,
  status text not null default 'pending'
    check (status in ('pending','preparing','out_for_delivery','completed','cancelled')),
  delivery_address text not null,
  phone text,
  created_at timestamptz not null default now()
);

create table public.food_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.food_orders(id) on delete cascade,
  food_item_id uuid references public.food_items(id) on delete set null,
  quantity int not null check (quantity > 0),
  price numeric(10,2) not null
);

-- file_url = el path gowa el storage bucket (private)
create table public.medical_records (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text default '',
  file_url text,
  record_type text not null default 'Health Summary'
    check (record_type in ('Prescriptions','Lab Reports','X-Ray Reports','Vaccinations','Health Summary')),
  created_at timestamptz not null default now()
);

create table public.health_metrics (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  heart_rate int,
  blood_pressure text,
  blood_sugar int,
  weight numeric(5,1),
  height numeric(5,1),
  steps int,
  calories_burned int,
  sleep_hours numeric(3,1),
  recorded_at timestamptz not null default now()
);

create table public.prescriptions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  medicine_name text not null,
  dosage text not null,
  instructions text default '',
  created_at timestamptz not null default now()
);

create table public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  item_type text not null check (item_type in ('doctor','pharmacy','gym','restaurant')),
  item_id uuid not null,
  created_at timestamptz not null default now(),
  unique (user_id, item_type, item_id)
);

-- =====================================================================
-- 2) INDEXES
-- =====================================================================
create index on public.doctors (specialization);
create index on public.doctor_availability (doctor_id);
create index on public.appointments (patient_id);
create index on public.appointments (doctor_id, appointment_date);
-- mmno3 2 7ogozat f nafs el wa2t le nafs el doctor
create unique index appointments_no_double_booking
  on public.appointments (doctor_id, appointment_date, appointment_time)
  where status in ('pending','confirmed');
create index on public.medicines (pharmacy_id);
create index on public.medicine_orders (patient_id);
create index on public.medicine_order_items (order_id);
create index on public.gym_exercises (gym_id);
create index on public.food_items (restaurant_id);
create index on public.food_orders (patient_id);
create index on public.medical_records (patient_id);
create index on public.health_metrics (patient_id, recorded_at desc);
create index on public.prescriptions (patient_id);
create index on public.favorites (user_id);

-- =====================================================================
-- 3) HELPER FUNCTION: hal el user el 7ali admin?
-- (security definer 3shan n-avoid RLS recursion 3la profiles)
-- =====================================================================
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- =====================================================================
-- 4) TRIGGER: lama user y3ml signup bn3mlo profile automatic
-- MOHEM: kol signup byb2a patient (mafish 7ad y2dar y3ml nafso admin)
-- =====================================================================
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, email, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.email,
    new.raw_user_meta_data->>'phone',
    'patient'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =====================================================================
-- 5) RPC FUNCTIONS
-- =====================================================================

-- btrg3 el awqat el ma7goza lel doctor f youm mo3ayan (men 8er data el patients)
create or replace function public.get_booked_slots(p_doctor uuid, p_date date)
returns setof time language sql stable security definer set search_path = public as $$
  select appointment_time from public.appointments
  where doctor_id = p_doctor and appointment_date = p_date
    and status in ('pending','confirmed');
$$;

-- medicine order kamel: el se3r byt7seb men el DB w bn2ales el stock
create or replace function public.place_medicine_order(
  p_pharmacy uuid, p_address text, p_phone text, p_items jsonb
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_order uuid;
  v_total numeric := 0;
  v_item jsonb;
  v_med record;
  v_needs_rx boolean := false;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if jsonb_array_length(p_items) = 0 then raise exception 'Cart is empty'; end if;

  insert into public.medicine_orders (patient_id, pharmacy_id, delivery_address, phone)
  values (auth.uid(), p_pharmacy, p_address, p_phone) returning id into v_order;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_med from public.medicines
      where id = (v_item->>'id')::uuid and pharmacy_id = p_pharmacy for update;
    if not found then raise exception 'Medicine not found'; end if;
    if v_med.stock_quantity < (v_item->>'qty')::int then
      raise exception 'Not enough stock for %', v_med.name;
    end if;

    insert into public.medicine_order_items (order_id, medicine_id, quantity, price)
    values (v_order, v_med.id, (v_item->>'qty')::int, v_med.price);

    update public.medicines set stock_quantity = stock_quantity - (v_item->>'qty')::int
    where id = v_med.id;

    v_total := v_total + v_med.price * (v_item->>'qty')::int;
    v_needs_rx := v_needs_rx or v_med.prescription_required;
  end loop;

  update public.medicine_orders
  set total_price = v_total,
      notes = case when v_needs_rx then 'Prescription required - pharmacist will verify' end
  where id = v_order;
  return v_order;
end;
$$;

-- nafs el fekra bas lel akl
create or replace function public.place_food_order(
  p_restaurant uuid, p_address text, p_phone text, p_items jsonb
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_order uuid;
  v_total numeric := 0;
  v_item jsonb;
  v_food record;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if jsonb_array_length(p_items) = 0 then raise exception 'Cart is empty'; end if;

  insert into public.food_orders (patient_id, restaurant_id, delivery_address, phone)
  values (auth.uid(), p_restaurant, p_address, p_phone) returning id into v_order;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_food from public.food_items
      where id = (v_item->>'id')::uuid and restaurant_id = p_restaurant;
    if not found then raise exception 'Food item not found'; end if;

    insert into public.food_order_items (order_id, food_item_id, quantity, price)
    values (v_order, v_food.id, (v_item->>'qty')::int, v_food.price);
    v_total := v_total + v_food.price * (v_item->>'qty')::int;
  end loop;

  update public.food_orders set total_price = v_total where id = v_order;
  return v_order;
end;
$$;

grant execute on function public.get_booked_slots(uuid, date) to authenticated;
grant execute on function public.place_medicine_order(uuid, text, text, jsonb) to authenticated;
grant execute on function public.place_food_order(uuid, text, text, jsonb) to authenticated;

-- =====================================================================
-- 6) ROW LEVEL SECURITY
-- =====================================================================
alter table public.profiles enable row level security;
alter table public.doctors enable row level security;
alter table public.doctor_availability enable row level security;
alter table public.appointments enable row level security;
alter table public.pharmacies enable row level security;
alter table public.medicines enable row level security;
alter table public.medicine_orders enable row level security;
alter table public.medicine_order_items enable row level security;
alter table public.exercises enable row level security;
alter table public.gyms enable row level security;
alter table public.gym_exercises enable row level security;
alter table public.restaurants enable row level security;
alter table public.food_items enable row level security;
alter table public.food_orders enable row level security;
alter table public.food_order_items enable row level security;
alter table public.medical_records enable row level security;
alter table public.health_metrics enable row level security;
alter table public.prescriptions enable row level security;
alter table public.favorites enable row level security;

-- ---------- ADMIN: by-edit / add / delete kol 7aga f el app ----------
-- (ma3ada el medical records w el health metrics: di private lel patient bas)
do $$
declare t text;
begin
  foreach t in array array[
    'doctors','doctor_availability','appointments','pharmacies','medicines',
    'medicine_orders','medicine_order_items','exercises','gyms','gym_exercises',
    'restaurants','food_items','food_orders','food_order_items','prescriptions'
  ] loop
    execute format(
      'create policy "admin_all" on public.%I for all to authenticated using (public.is_admin()) with check (public.is_admin())', t);
  end loop;
end $$;

-- ---------- PROFILES ----------
-- kol user yshof profile bta3o, w el admin yshof kol el users
create policy "profiles_select" on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin());
-- el user y3dl el profile bta3o bas (w mynf3sh y8yr el role bta3o)
create policy "profiles_update_own" on public.profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid() and role = (select p.role from public.profiles p where p.id = auth.uid()));
-- el admin y3dl ay user
create policy "profiles_admin_update" on public.profiles for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------- PUBLIC DATA (ay user 3aml login yshofha) ----------
create policy "doctors_read" on public.doctors for select to authenticated using (true);
create policy "availability_read" on public.doctor_availability for select to authenticated using (true);
create policy "pharmacies_read" on public.pharmacies for select to authenticated using (true);
create policy "medicines_read" on public.medicines for select to authenticated using (true);
create policy "exercises_read" on public.exercises for select to authenticated using (true);
create policy "gyms_read" on public.gyms for select to authenticated using (true);
create policy "gym_exercises_read" on public.gym_exercises for select to authenticated using (true);
create policy "restaurants_read" on public.restaurants for select to authenticated using (true);
create policy "food_read" on public.food_items for select to authenticated using (true);

-- ---------- APPOINTMENTS ----------
-- el patient yshof el 7ogozat beta3to bas
create policy "appointments_own_select" on public.appointments for select to authenticated
  using (patient_id = auth.uid());
-- el patient y3ml 7agz le nafso bas (status lazem pending)
create policy "appointments_own_insert" on public.appointments for insert to authenticated
  with check (patient_id = auth.uid() and status = 'pending');
-- el patient y-cancel el 7agz bta3o bas
create policy "appointments_own_cancel" on public.appointments for update to authenticated
  using (patient_id = auth.uid() and status in ('pending','confirmed'))
  with check (patient_id = auth.uid() and status = 'cancelled');

-- ---------- ORDERS ----------
-- hena el user byshof el orders beta3to bas (el insert by RPC)
create policy "med_orders_own_select" on public.medicine_orders for select to authenticated
  using (patient_id = auth.uid());
create policy "med_orders_own_cancel" on public.medicine_orders for update to authenticated
  using (patient_id = auth.uid() and status = 'pending')
  with check (patient_id = auth.uid() and status = 'cancelled');
create policy "med_order_items_own_select" on public.medicine_order_items for select to authenticated
  using (exists (select 1 from public.medicine_orders o where o.id = order_id and o.patient_id = auth.uid()));

create policy "food_orders_own_select" on public.food_orders for select to authenticated
  using (patient_id = auth.uid());
create policy "food_orders_own_cancel" on public.food_orders for update to authenticated
  using (patient_id = auth.uid() and status = 'pending')
  with check (patient_id = auth.uid() and status = 'cancelled');
create policy "food_order_items_own_select" on public.food_order_items for select to authenticated
  using (exists (select 1 from public.food_orders o where o.id = order_id and o.patient_id = auth.uid()));

-- ---------- PRIVATE PATIENT DATA ----------
-- da RLS policy 3shan kol patient yshof el records beta3to bas
create policy "records_own_all" on public.medical_records for all to authenticated
  using (patient_id = auth.uid()) with check (patient_id = auth.uid());
create policy "metrics_own_all" on public.health_metrics for all to authenticated
  using (patient_id = auth.uid()) with check (patient_id = auth.uid());
create policy "prescriptions_own_select" on public.prescriptions for select to authenticated
  using (patient_id = auth.uid());
create policy "favorites_own_all" on public.favorites for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- =====================================================================
-- 7) STORAGE: bucket private lel medical records
-- =====================================================================
insert into storage.buckets (id, name, public)
values ('medical-records', 'medical-records', false)
on conflict (id) do nothing;

drop policy if exists "medical_files_select_own" on storage.objects;
drop policy if exists "medical_files_insert_own" on storage.objects;
drop policy if exists "medical_files_delete_own" on storage.objects;

create policy "medical_files_select_own" on storage.objects for select to authenticated
  using (bucket_id = 'medical-records' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "medical_files_insert_own" on storage.objects for insert to authenticated
  with check (bucket_id = 'medical-records' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "medical_files_delete_own" on storage.objects for delete to authenticated
  using (bucket_id = 'medical-records' and (storage.foldername(name))[1] = auth.uid()::text);

-- =====================================================================
-- 8) SEED DATA
-- =====================================================================

-- helper: bt3ml demo user f auth (password: Demo@1234) w el trigger y3ml el profile
create or replace function public.create_demo_user(p_email text, p_name text, p_phone text default null)
returns uuid language plpgsql security definer set search_path = public, auth, extensions as $$
declare
  v_id uuid;
begin
  select id into v_id from auth.users where email = p_email;
  if v_id is not null then
    -- el user mawgood men run adeem: bn3ml el profile tany
    insert into public.profiles (id, full_name, email, phone, role)
    values (v_id, p_name, p_email, p_phone, 'patient') on conflict (id) do nothing;
    return v_id;
  end if;

  v_id := gen_random_uuid();
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
  ) values (
    '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
    p_email, crypt('Demo@1234', gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('full_name', p_name, 'phone', p_phone),
    now(), now(), '', '', '', ''
  );

  insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  values (gen_random_uuid(), v_id, v_id::text,
    jsonb_build_object('sub', v_id::text, 'email', p_email, 'email_verified', true),
    'email', now(), now(), now());
  return v_id;
end;
$$;
revoke execute on function public.create_demo_user(text, text, text) from public, anon, authenticated;

do $$
declare
  v_patient uuid; v_admin uuid;
  v_d1 uuid; v_d2 uuid;
  v_ph1 uuid; v_ph2 uuid; v_ph3 uuid;
  v_g1 uuid; v_g2 uuid; v_g3 uuid; v_g4 uuid; v_g5 uuid;
  v_r1 uuid; v_r2 uuid; v_r3 uuid; v_r4 uuid; v_r5 uuid;
begin
  -- ---------- users: patient + admin bas ----------
  v_patient := public.create_demo_user('patient@demo.com', 'Alex Johnson', '+20 100 000 0001');
  v_admin   := public.create_demo_user('admin@demo.com', 'SOKR Admin');
  update public.profiles set role = 'admin' where id = v_admin;

  -- ---------- doctors ----------
  insert into public.doctors (full_name, specialization, years_experience, consultation_price, clinic_name, clinic_address, latitude, longitude, rating, bio) values
    ('Dr. Sarah Johnson', 'Cardiologist', 10, 350, 'Heart Care Clinic', '12 Tahrir St, Downtown, Cairo', 30.0444, 31.2357, 4.9, 'Cardiologist focused on preventive heart care, hypertension and cholesterol management.')
    returning id into v_d1;
  insert into public.doctors (full_name, specialization, years_experience, consultation_price, clinic_name, clinic_address, latitude, longitude, rating, bio) values
    ('Dr. Michael Chen', 'Neurologist', 8, 400, 'NeuroLife Center', '45 Abbas El Akkad, Nasr City, Cairo', 30.0561, 31.3300, 4.8, 'Neurologist treating migraines, epilepsy and sleep disorders.')
    returning id into v_d2;
  insert into public.doctors (full_name, specialization, years_experience, consultation_price, clinic_name, clinic_address, latitude, longitude, rating, bio) values
    ('Dr. Emily Davis', 'Dentist', 6, 250, 'Smile Dental', '9 Road 9, Maadi, Cairo', 29.9602, 31.2569, 4.9, 'Cosmetic and general dentistry with a gentle, family-friendly approach.'),
    ('Dr. James Wilson', 'Orthopedic', 9, 380, 'Bone & Joint Clinic', '22 Mohandessin, Giza', 30.0566, 31.2006, 4.7, 'Orthopedic surgeon specialized in sports injuries and joint pain.'),
    ('Dr. Olivia Martinez', 'Endocrinologist', 12, 420, 'Diabetes & Hormones Center', '5 Heliopolis Sq, Cairo', 30.0911, 31.3222, 4.8, 'Endocrinologist helping patients manage diabetes, thyroid and hormonal conditions.'),
    ('Dr. Layla Hassan', 'Ophthalmologist', 11, 300, 'Clear Vision Eye Center', '17 Zamalek, Cairo', 30.0630, 31.2190, 4.9, 'Eye doctor experienced in diabetic eye screening and retina care.');

  -- mawa3eed kol doctor (Sun-Thu)
  insert into public.doctor_availability (doctor_id, day_of_week, start_time, end_time)
  select d.id, dow,
         case when d.specialization in ('Cardiologist','Dentist','Endocrinologist') then '10:00'::time else '16:00'::time end,
         case when d.specialization in ('Cardiologist','Dentist','Endocrinologist') then '15:00'::time else '20:00'::time end
  from public.doctors d cross join generate_series(0, 4) dow;

  -- ---------- pharmacies + medicines ----------
  insert into public.pharmacies (name, description, address, latitude, longitude, phone, rating, is_open) values
    ('HealthPlus Pharmacy', '24/7 pharmacy with home delivery.', '30 Gameat El Dowal, Mohandessin, Giza', 30.0590, 31.2010, '+20 2 3333 1111', 4.8, true) returning id into v_ph1;
  insert into public.pharmacies (name, description, address, latitude, longitude, phone, rating, is_open) values
    ('CarePoint Pharmacy', 'Family pharmacy with baby care and vitamins.', '15 Makram Ebeid, Nasr City, Cairo', 30.0600, 31.3400, '+20 2 2222 3333', 4.6, true) returning id into v_ph2;
  insert into public.pharmacies (name, description, address, latitude, longitude, phone, rating, is_open) values
    ('GreenLeaf Pharmacy', 'Natural supplements and prescription medicines.', '7 Road 233, Maadi, Cairo', 29.9620, 31.2600, '+20 2 2525 4444', 4.5, false) returning id into v_ph3;

  insert into public.medicines (pharmacy_id, name, description, category, price, stock_quantity, prescription_required) values
    (v_ph1, 'Paracetamol 500mg', 'Pain reliever and fever reducer. Follow the leaflet instructions.', 'Pain Relief', 35, 120, false),
    (v_ph1, 'Vitamin C 1000mg', 'Immune support effervescent tablets.', 'Vitamins', 80, 60, false),
    (v_ph1, 'Amoxicillin 500mg', 'Antibiotic capsules. Only with a doctor prescription.', 'Antibiotics', 95, 40, true),
    (v_ph1, 'Omega 3 Fish Oil', 'Supports heart and brain health.', 'Supplements', 220, 30, false),
    (v_ph1, 'Metformin 850mg', 'Diabetes medication. Requires a prescription.', 'Diabetes', 60, 50, true),
    (v_ph2, 'Ibuprofen 400mg', 'Anti-inflammatory pain relief.', 'Pain Relief', 45, 90, false),
    (v_ph2, 'Vitamin D3 5000 IU', 'Supports bones and immunity.', 'Vitamins', 150, 45, false),
    (v_ph2, 'Cetirizine 10mg', 'Allergy relief tablets.', 'Allergy', 40, 70, false),
    (v_ph3, 'Atorvastatin 20mg', 'Cholesterol medication. Requires a prescription.', 'Heart', 140, 25, true),
    (v_ph3, 'Artificial Tears Eye Drops', 'Lubricating drops for dry eyes.', 'Eye Care', 65, 55, false);

  -- ---------- exercises ----------
  insert into public.exercises (name, description, category, difficulty, duration_minutes, calories) values
    ('Push Ups', 'Classic upper body exercise for chest, shoulders and triceps. Keep your core tight and back straight.', 'Strength', 'Intermediate', 10, 80),
    ('Brisk Walking', 'Walk at a fast pace that raises your heart rate while you can still talk.', 'Walking', 'Beginner', 30, 150),
    ('Jump Rope', 'High energy cardio that improves coordination and endurance.', 'Cardio', 'Intermediate', 15, 200),
    ('Sun Salutation', 'A flowing yoga sequence that stretches the whole body and calms the mind.', 'Yoga', 'Beginner', 15, 70),
    ('Bodyweight Squats', 'Strengthens legs and glutes. Push hips back and keep knees over toes.', 'Strength', 'Beginner', 10, 90),
    ('Easy Run', 'Steady light jog to build aerobic fitness.', 'Running', 'Intermediate', 25, 260),
    ('Hamstring Stretch', 'Gentle stretch for the back of the legs to improve flexibility.', 'Stretching', 'Beginner', 5, 15),
    ('Plank Hold', 'Core stability exercise. Hold a straight line from head to heels.', 'Home Workout', 'Intermediate', 5, 40),
    ('HIIT Circuit', 'Short bursts of intense moves with short rests between them.', 'Cardio', 'Advanced', 20, 300),
    ('Mountain Climbers', 'Full body move that works core and raises heart rate.', 'Home Workout', 'Advanced', 10, 120);

  -- ---------- gyms ----------
  insert into public.gyms (name, description, address, latitude, longitude, phone, rating) values
    ('PowerFit Gym', 'Modern gym with personal trainers and cardio zone.', '88 El Tayaran St, Nasr City, Cairo', 30.0650, 31.3300, '+20 100 111 2222', 4.8) returning id into v_g1;
  insert into public.gyms (name, description, address, latitude, longitude, phone, rating) values
    ('Zen Yoga Studio', 'Calm yoga and stretching classes for all levels.', '3 Road 9, Maadi, Cairo', 29.9600, 31.2580, '+20 100 333 4444', 4.9) returning id into v_g2;
  insert into public.gyms (name, description, address, latitude, longitude, phone, rating) values
    ('Iron Club', 'Strength training and powerlifting club.', '14 Shehab St, Mohandessin, Giza', 30.0560, 31.2000, '+20 100 555 6666', 4.6) returning id into v_g3;
  insert into public.gyms (name, description, address, latitude, longitude, phone, rating) values
    ('RunFree Track Club', 'Running groups and outdoor training.', 'Al Azhar Park, Cairo', 30.0410, 31.2650, '+20 100 777 8888', 4.5) returning id into v_g4;
  insert into public.gyms (name, description, address, latitude, longitude, phone, rating) values
    ('Active Life Fitness', 'Family gym with classes and swimming pool.', '50 Heliopolis, Cairo', 30.0900, 31.3200, '+20 100 999 0000', 4.7) returning id into v_g5;

  insert into public.gym_exercises (gym_id, exercise_id)
  select v_g1, id from public.exercises where category in ('Strength','Cardio','Home Workout');
  insert into public.gym_exercises (gym_id, exercise_id)
  select v_g2, id from public.exercises where category in ('Yoga','Stretching');
  insert into public.gym_exercises (gym_id, exercise_id)
  select v_g3, id from public.exercises where category = 'Strength';
  insert into public.gym_exercises (gym_id, exercise_id)
  select v_g4, id from public.exercises where category in ('Running','Walking');
  insert into public.gym_exercises (gym_id, exercise_id)
  select v_g5, id from public.exercises;

  -- ---------- restaurants + food ----------
  insert into public.restaurants (name, description, address, latitude, longitude, phone, rating, is_open) values
    ('Green Bowl', 'Fresh salads and protein bowls.', '18 Road 9, Maadi, Cairo', 29.9610, 31.2575, '+20 111 222 3333', 4.8, true) returning id into v_r1;
  insert into public.restaurants (name, description, address, latitude, longitude, phone, rating, is_open) values
    ('FitKitchen', 'High protein meals for athletes.', '40 Abbas El Akkad, Nasr City', 30.0570, 31.3350, '+20 111 444 5555', 4.7, true) returning id into v_r2;
  insert into public.restaurants (name, description, address, latitude, longitude, phone, rating, is_open) values
    ('Sunrise Breakfast Co.', 'Healthy breakfast all day.', '9 Zamalek, Cairo', 30.0620, 31.2200, '+20 111 666 7777', 4.6, true) returning id into v_r3;
  insert into public.restaurants (name, description, address, latitude, longitude, phone, rating, is_open) values
    ('Veggie Garden', 'Vegetarian and plant based dishes.', '12 Heliopolis, Cairo', 30.0880, 31.3180, '+20 111 888 9999', 4.5, false) returning id into v_r4;
  insert into public.restaurants (name, description, address, latitude, longitude, phone, rating, is_open) values
    ('LowCarb Lab', 'Keto and low carb meals.', '25 Mohandessin, Giza', 30.0550, 31.2050, '+20 111 000 1111', 4.4, true) returning id into v_r5;

  insert into public.food_items (restaurant_id, name, description, price, calories, protein, carbs, fats, category) values
    (v_r1, 'Grilled Chicken Salad', 'Grilled chicken, mixed greens, cherry tomatoes and olive oil.', 165, 420, 35, 20, 15, 'Salads'),
    (v_r1, 'Quinoa Power Bowl', 'Quinoa, chickpeas, avocado and tahini dressing.', 150, 480, 18, 55, 18, 'Vegetarian'),
    (v_r1, 'Tuna Nicoise', 'Tuna, boiled egg, green beans and potatoes.', 175, 450, 32, 30, 18, 'Salads'),
    (v_r1, 'Green Detox Smoothie', 'Spinach, apple, cucumber and ginger.', 70, 160, 3, 34, 1, 'Low Calories'),
    (v_r2, 'Steak & Sweet Potato', 'Lean beef steak with roasted sweet potato.', 260, 610, 48, 45, 20, 'High Protein'),
    (v_r2, 'Salmon & Brown Rice', 'Grilled salmon, brown rice and broccoli.', 280, 580, 40, 50, 18, 'High Protein'),
    (v_r2, 'Chicken Burrito Bowl', 'Chicken, black beans, rice and salsa.', 180, 550, 42, 58, 12, 'Healthy'),
    (v_r2, 'Protein Pancakes', 'Oat pancakes with whey and berries.', 120, 390, 30, 40, 9, 'Breakfast'),
    (v_r3, 'Avocado Toast', 'Whole grain toast, avocado and poached egg.', 110, 350, 14, 30, 18, 'Breakfast'),
    (v_r3, 'Greek Yogurt Parfait', 'Yogurt, granola, honey and berries.', 85, 290, 18, 38, 6, 'Breakfast'),
    (v_r3, 'Veggie Omelette', 'Egg whites, spinach, mushrooms and peppers.', 95, 240, 24, 8, 10, 'Low Carb'),
    (v_r3, 'Oatmeal Bowl', 'Oats, banana, peanut butter and chia.', 80, 380, 12, 55, 12, 'Healthy'),
    (v_r4, 'Lentil Soup', 'Classic Egyptian lentil soup with lemon.', 60, 260, 16, 40, 4, 'Vegetarian'),
    (v_r4, 'Falafel Wrap', 'Baked falafel, tahini and salad in whole wheat bread.', 75, 420, 15, 52, 16, 'Vegetarian'),
    (v_r4, 'Tofu Stir Fry', 'Tofu with mixed vegetables and soy ginger sauce.', 140, 360, 22, 28, 16, 'Vegetarian'),
    (v_r4, 'Fattoush Salad', 'Fresh vegetables, herbs and toasted bread.', 70, 210, 5, 25, 10, 'Salads'),
    (v_r5, 'Keto Chicken Alfredo', 'Zucchini noodles with chicken alfredo.', 190, 520, 40, 12, 34, 'Low Carb'),
    (v_r5, 'Cauliflower Rice Bowl', 'Cauliflower rice, beef and vegetables.', 170, 430, 35, 14, 24, 'Low Carb'),
    (v_r5, 'Egg Muffins', 'Baked egg cups with cheese and vegetables.', 90, 280, 20, 4, 20, 'Low Calories'),
    (v_r5, 'Shrimp Lettuce Wraps', 'Spicy shrimp in crisp lettuce cups.', 160, 310, 28, 10, 14, 'Low Calories');

  -- ---------- demo data lel patient ----------
  insert into public.health_metrics (patient_id, heart_rate, blood_pressure, blood_sugar, weight, height, steps, calories_burned, sleep_hours, recorded_at)
  select v_patient, 68 + (random()*10)::int, '120/80', 92 + (random()*12)::int, 75, 178,
         5000 + (random()*5000)::int, 350 + (random()*250)::int, round((6 + random()*2)::numeric, 1),
         now() - (g || ' days')::interval
  from generate_series(6, 0, -1) g;

  insert into public.appointments (patient_id, doctor_id, appointment_date, appointment_time, status, notes) values
    (v_patient, v_d1, current_date + 3, '10:30', 'confirmed', 'Routine heart check-up'),
    (v_patient, v_d2, current_date + 5, '17:00', 'pending', 'Headaches for two weeks');

  insert into public.prescriptions (patient_id, doctor_id, medicine_name, dosage, instructions)
  values (v_patient, v_d1, 'Omega 3 Fish Oil', 'As directed by your doctor', 'Take with food.');
end $$;
