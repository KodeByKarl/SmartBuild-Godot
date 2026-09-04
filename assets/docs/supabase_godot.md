# Supabase configuration (secured)

No API keys or project URLs are hardcoded in source. Values come from local env files or CI environment variables.

## Android (`SmartBuild/`)

1. Copy `secrets.properties.example` → `secrets.properties`
2. Fill in:

```
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_OR_PUBLISHABLE_KEY
```

3. Gradle injects them into `BuildConfig`; `SupabaseClient` reads `BuildConfig.SUPABASE_*`.
4. CI can set the same names as environment variables (env wins over the file).

`secrets.properties` is gitignored.

## Godot (`SmartBuild-Godot/`)

1. Copy `config/env.example` → `config/env.local`
2. Fill the same `SUPABASE_URL` / `SUPABASE_ANON_KEY` values
3. `EnvConfig` loads (priority):
   - OS environment variables
   - `res://config/env.local`
   - `res://config/env.local.cfg` (optional ConfigFile form)
   - `user://env.cfg` (device-local override)

`config/env.local` is gitignored. Preview auth fallback defaults to **off**.

## Required Supabase table

```sql
create table if not exists public.module_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  module_id int not null,
  percent real not null default 0,
  guided_done boolean not null default false,
  assessment_done boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, module_id)
);

alter table public.module_progress enable row level security;

create policy "Users manage own progress"
  on public.module_progress
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

## Hosted Android path

Compose owns Sign-In, Sign-Up, and Homepage/Dashboard via Kotlin `SupabaseClient` (BuildConfig).
Godot does **not** show auth or dashboard scenes. After login, Compose launches the embedded
Godot view and sends `prepare` (module + optional session tokens) through `SmartBuildBridge`.

Godot emits `ready` / `guided_completed` / `assessment_completed` / `destroy`
through `SmartBuildBridge`. Do not ship `env.local` inside release APK assets if Godot is only hosted.

Full contracts: see `assets/docs/native_auth_handoff.md`.

## Security notes

- Use the **anon / publishable** key only — never the service role key in the client.
- Rotate keys in the Supabase dashboard if they were ever committed to git history.
- Keep RLS enabled on all user tables.
