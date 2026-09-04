# Native Auth Handoff — Godot ↔ Android

Godot no longer owns Login, Sign Up, or Dashboard/Homepage.
Those live in the Jetpack Compose app. Godot boots only as the simulation engine.

---

## 1. Audit report (Task 1)

### Delete (auth / dashboard only)

| Path | Role |
| --- | --- |
| `core/scenes/AuthScreen.tscn` | Login / sign-up UI scene |
| `core/scenes/auth_screen.gd` (+ `.uid`) | Auth UI, validation, calls `SupabaseService.sign_in/up` |
| `core/scenes/Dashboard.tscn` | Homepage / module carousel scene |
| `core/scenes/dashboard.gd` (+ `.uid`) | Module menu, search chrome, progress UI, sign-out |

### Shared — keep, trim auth-only pieces

| Path | Keep | Strip |
| --- | --- | --- |
| `core/services/supabase_service.gd` | HTTP helpers, `sync_module_progress`, `fetch_module_progress`, session apply/load for host handoff | `sign_in`, `sign_up`, `reset_password`, `_preview_sign_in` |
| `scripts/Main.gd` | Bridge `prepare` → load module; event relay to Compose | Auth/dashboard show/hide; return-to-dashboard flow |
| `core/services/env_config.gd` | Env loading | (add debug keys only) |
| `scripts/css_parts_catalog.gd` | Used by in-module Search overlay | Was also used by dashboard search — keep |
| `core/ui/parts_search_overlay.gd` | In-module Help/Search | keep |
| `core/ui/ui_toast.gd` | Generic toast helper | Was dashboard-only consumer; keep for future/modules |

### Autoloads

| Autoload | Action |
| --- | --- |
| `SupabaseService` | **Keep** (progress sync + host session apply) |
| `EnvConfig`, `PerformanceProfile`, `ResponsiveLayout`, `UiMotion` | **Keep** (simulation UI) |

### Already owned by native (do not re-implement in Godot)

- `SmartBuild/.../screens/authenticationpage/`
- `SmartBuild/.../viewmodel/auth/AuthViewModel.kt`
- `SmartBuild/.../screens/homepage/HomePage.kt`
- `SmartBuild/.../data/ModuleProgressStore.kt` + `ModuleProgressRepository.kt`

---

## 2. API contract (Task 2) — for Compose (source of truth)

Base URL: `SUPABASE_URL` (e.g. `https://<project>.supabase.co`)  
Anon key header: `apikey` + `Authorization: Bearer <anon_or_user_token>`

### Sign in (password grant)

- **POST** `{SUPABASE_URL}/auth/v1/token?grant_type=password`
- **Headers:** `Content-Type: application/json`, `apikey: <ANON>`, `Authorization: Bearer <ANON>`
- **Body:** `{ "email": string, "password": string }` (email lowercased/trimmed)
- **Success (200):**  
  `{ "access_token": string, "refresh_token": string, "user": { "id": uuid, "email": string, ... }, ... }`
- **Errors:** `invalid_credentials`, `email_not_confirmed`, generic `msg` / `error_description`

### Sign up

- **POST** `{SUPABASE_URL}/auth/v1/signup`
- Same headers/body as sign-in
- **Success with session:** payload includes `access_token` → treat as signed in  
- **Success without session:** email confirmation required → prompt user to confirm then sign in

### Password recover

- **POST** `{SUPABASE_URL}/auth/v1/recover`
- **Body:** `{ "email": string }`
- Soft-success even if network fails in preview; production should surface HTTP failures

### Module progress (table `public.module_progress`)

| Field | Type |
| --- | --- |
| `user_id` | uuid (FK `auth.users`) |
| `module_id` | int |
| `percent` | float |
| `guided_done` | bool |
| `assessment_done` | bool |
| `updated_at` | timestamptz |

- **Fetch:** `GET /rest/v1/module_progress?user_id=eq.<uuid>&select=*`  
  Auth: Bearer **user** `access_token`
- **Upsert:** `POST /rest/v1/module_progress?on_conflict=user_id,module_id`  
  Header `Prefer: resolution=merge-duplicates`  
  Body: one row matching the table

### Client validation (former Godot auth screen)

- Email required; reject empty / placeholder `user@example.com`
- Password required; reject empty / placeholder `********`
- No min-length rule was enforced in Godot beyond non-empty (Compose may tighten)

### Token storage (former Godot)

- File `user://supabase_session.cfg` with `access_token`, `refresh_token`, `user_id`, `user_email`
- **Native owns storage now** (Supabase Kotlin SDK session). Godot only holds tokens if passed via handoff for optional progress sync.

---

## 3. Entry / handoff contract (Task 3)

### Launch path (current)

Embedded Godot via `SmartBuildBridge` plugin inside Compose `ModulePage`.  
Compose owns auth → Home → ModulePage → Godot receives `prepare` after `engine_initialized`.

### Command: `prepare`

```json
{
  "type": "command",
  "action": "prepare",
  "data": {
    "moduleId": 0,
    "simulationType": 0,
    "progress": 0.0,
    "accessToken": "<optional jwt>",
    "refreshToken": "<optional>",
    "userId": "<optional uuid>",
    "userEmail": "<optional string>"
  }
}
```

| Field | Required | Notes |
| --- | --- | --- |
| `moduleId` | yes | `0`–`4` |
| `simulationType` | yes | `0` = guided/intro start; `1` = jump to assessment (host contract) |
| `progress` | no | default `0.0` |
| `accessToken` / `userId` / `userEmail` / `refreshToken` | no* | *Recommended so Godot can sync progress if needed; Compose already syncs on Home |

### Events Godot → Compose

| `event` | Meaning |
| --- | --- |
| `engine_initialized` | Bridge ready — Compose should send `prepare` |
| `loading` | Module scene loading (`moduleId`) |
| `ready` | Module interactive |
| `progress_update` | In-module percent (`percent`, capped &lt; 100) |
| `guided_completed` | Guided path finished |
| `assessment_completed` | Assessment finished |
| `destroy` | User exited simulation → pop to Home |

### Open question

Primary path is **embedded Godot Activity/view** (already implemented). Separate-process deep link is **not** required unless product later splits the APK.

---

## 4. Godot standalone debug (Task 5)

When `SmartBuildBridge` is missing (editor / desktop):

1. If `DEBUG_MOCK_SESSION=true` (default in debug builds), inject mock session into `SupabaseService`.
2. If `DEBUG_SHOW_MODULE_PICKER=true` (default when standalone), show a **minimal debug launcher** (not the product dashboard).
3. Or set `DEBUG_STANDALONE_MODULE_ID` / `DEBUG_STANDALONE_SIMULATION_TYPE` to auto-boot a module with no picker.

Production / hosted Android: never show auth, dashboard, or debug picker — wait for `prepare`.

---

## 5. Removed vs kept (Task 6 summary)

**Removed from Godot:** AuthScreen, Dashboard, auth/dashboard flows in `Main.gd`, Supabase password auth helpers.

**Kept:** Module 0–4 simulations, ModuleShell, labs, Help/Search overlay, CssPartsCatalog, Supabase progress REST helpers, SmartBuildBridge prepare/event protocol, EnvConfig.

**Compose responsibilities:** Splash/auth check, Login, Sign Up, Homepage/Dashboard (menu + search), progress sync, calling `SmartBuildBridge.prepare(...)` with module + optional session.
