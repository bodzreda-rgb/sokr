# SOKR - سكر (Flutter + Supabase)

Graduation project: healthcare platform (doctors, appointments, pharmacies, medicines,
exercises, gyms, healthy food, medical records, health status) with patient + admin roles.

## Setup

1. Create a project on https://supabase.com.
2. Supabase Dashboard -> **SQL Editor** -> paste all of `supabase/supabase_schema.sql` -> **Run**.
   (tables + indexes + RLS + storage bucket + triggers + demo data)
3. Supabase Dashboard -> **Authentication -> Sign In / Providers -> Email**:
   turn **Confirm email** OFF for testing (otherwise new users must confirm by email).
4. Supabase Dashboard -> **Project Settings -> API**: copy the **Project URL** and the
   **anon / publishable key** into `lib/core/supabase_config.dart`.
   Never put the `service_role` key in the app.
5. Run:

```
flutter pub get
flutter run
```

Or without editing the file:

```
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=xxxx
```

## Demo accounts (password: `Demo@1234`)

| Role | Email |
|------|-------|
| Patient | patient@demo.com |
| Admin (add / edit / delete everything) | admin@demo.com |

## Structure

```
lib/
  main.dart
  core/            theme + supabase config
  models/          data models
  services/        Supabase queries (auth, doctors, pharmacy, fitness, food, medical, cart, location)
  screens/         auth, home, doctors, pharmacy, exercises, food, medical, profile, health_info, dashboards
  widgets/         reusable cards and UI pieces
supabase/supabase_schema.sql
```

> This app is for general health information and does not replace professional medical advice.
