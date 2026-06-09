# Gateway Service

Single public-facing nginx edge that routes all traffic. No other service is publicly exposed.

## Architecture

```text
Internet → Gateway (nginx)
            │
            ├─ /.ory/*                      → Kratos public API  (port 4433)
            ├─ /oauth2/*                    → Hydra public API   (port 4444)
            ├─ /self-service/*              → Kratos public API  (port 4433)
            ├─ /sessions/*                  → Kratos public API  (port 4433)
            ├─ /health/*                    → Kratos public API  (port 4433)
            ├─ /talos/*                     → Talos API         (port 4420)
            ├─ /talos/health/*              → Talos health      (port 4422)
            │
            ├─ /auth/*                      → UI (public – login/register pages)
            ├─ /auth/callback/simplelogin   → UI (public – OAuth callback)
            │
            ├─ /api/*  ──► Oathkeeper (4455) ──► UI (protected API routes)
            │         cookie_session (Kratos) │
            │         oauth2_introspection    │
            │         (Hydra) + Keto for      │
            │         admin routes            │
            │
            ├─ /relation-tuples/*           → Keto read API  (port 4466) ⚠ public
            ├─ /check                        → Keto read API  (port 4466) ⚠ public
            ├─ /expand                       → Keto read API  (port 4466) ⚠ public
            ├─ /admin/relation-tuples        → Keto write API (port 4467) ⚠ public
            ├─ /talos/*                      → Talos API      (port 4420) ⚠ public
            ├─ /kratos-admin/*               → Kratos admin   (port 4434) ⚠ public
            │
            └─ /*                           → UI (Next.js catch-all)
```

### Oathkeeper integration (request flow for `/api/*`)

```text
Browser/Client
  │  GET /api/dashboard   (session cookie or Bearer token)
  ▼
nginx  →  Oathkeeper proxy (port 4455)
              │
              ├─ Authenticates via Kratos /sessions/whoami  (cookie_session)
              │    OR Hydra /oauth2/introspect               (oauth2_introspection)
              │
              ├─ /api/auth/*   → anonymous, allow            → UI
              ├─ /api/admin/*  → authenticated + Keto GlobalRole:admin check → UI
              └─ /api/*        → authenticated, allow        → UI
                                 (X-User-Id header forwarded to UI)
```

## Environment Variables

### Gateway service

| Variable              | Description                                 | Example                       |
| --------------------- | ------------------------------------------- | ----------------------------- |
| `PORT`                | Gateway listen port (set by Railway)        | `8080`                        |
| `KRATOS_INTERNAL`     | Kratos internal hostname (no `http://`)     | `kratos.railway.internal`     |
| `HYDRA_INTERNAL`      | Hydra internal hostname (no `http://`)      | `hydra.railway.internal`      |
| `KETO_INTERNAL`       | Keto internal hostname (no `http://`)       | `keto.railway.internal`       |
| `TALOS_INTERNAL`      | Talos internal hostname (no `http://`)      | `talos.railway.internal`      |
| `OATHKEEPER_INTERNAL` | Oathkeeper internal hostname (no `http://`) | `oathkeeper.railway.internal` |
| `UI_INTERNAL`         | UI internal hostname (no `http://`)         | `ui.railway.internal`         |
| `UI_PORT`             | UI listen port                              | `8080`                        |

### Oathkeeper service

| Variable          | Description                                           | Example                       |
| ----------------- | ----------------------------------------------------- | ----------------------------- |
| `KRATOS_INTERNAL` | Kratos internal hostname                              | `kratos.railway.internal`     |
| `HYDRA_INTERNAL`  | Hydra internal hostname                               | `hydra.railway.internal`      |
| `KETO_INTERNAL`   | Keto internal hostname                                | `keto.railway.internal`       |
| `TALOS_INTERNAL`  | Talos internal hostname                               | `talos.railway.internal`      |
| `UI_INTERNAL`     | UI internal hostname                                  | `ui.railway.internal`         |
| `UI_PORT`         | UI listen port                                        | `8080`                        |
| `PUBLIC_URL`      | Full public base URL of the gateway (no trailing `/`) | `https://gateway.railway.app` |

## Public routes (bypass Oathkeeper by design)

These routes exist for auth flows and must remain unauthenticated at the gateway level:

| Route              | Reason                                                              |
| ------------------ | ------------------------------------------------------------------- |
| `/.ory/*`          | Kratos SDK self-service flows (login, registration)                 |
| `/oauth2/*`        | Hydra authorization and token endpoints                             |
| `/self-service/*`  | Kratos self-service flows (direct path)                             |
| `/sessions/whoami` | Session check used by UI and Oathkeeper                             |
| `/health/*`        | Health probes                                                       |
| `/talos/*`         | Talos API key management and self-revocation                        |
| `/auth/*`          | UI login/registration/settings pages                                |
| `/api/auth/*`      | Kratos webhooks (e.g., registration-hook) and OAuth relay endpoints |

## ⚠ Security gaps (pre-existing, require follow-up)

The following routes are exposed without authentication. These existed before the Oathkeeper integration and should be secured before production:

| Route                                   | Exposed API         | Risk                                                          |
| --------------------------------------- | ------------------- | ------------------------------------------------------------- |
| `/kratos-admin/*`                       | Kratos Admin (4434) | Full identity management (create/delete identities, sessions) |
| `/admin/relation-tuples`                | Keto Write (4467)   | Write arbitrary permission tuples                             |
| `/relation-tuples`, `/check`, `/expand` | Keto Read (4466)    | Read all permission data                                      |
| `/talos/*`                              | Talos (4420/4422)   | Issue, verify, derive, and revoke API keys                    |

**Recommended mitigations:**

- Route these through Oathkeeper with an `oauth2_introspection` authenticator and a `remote_json` Keto check for `GlobalRole:admin`
- Or restrict them to Railway's internal network only (remove the gateway locations entirely)
- Minimum: add an `X-Api-Key` header check in nginx for these paths

## Railway deployment setup

1. Deploy all services (Kratos, Hydra, Keto, Talos, Oathkeeper, UI) with **public networking disabled**
2. Deploy the Gateway with **public networking enabled**
3. Set the environment variables listed above on each service
4. The Gateway is the only service that needs a public Railway domain

## Files

- [Dockerfile](Dockerfile) — builds nginx image with `envsubst` and start script
- [nginx.conf.template](nginx.conf.template) — nginx config with `${VAR}` placeholders
- [start.sh](start.sh) — entrypoint: resolves DNS, runs `envsubst`, starts nginx
