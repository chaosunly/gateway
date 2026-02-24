# Gateway Service - Railway Environment Variables

## Required Environment Variables

Set these in your Railway gateway service:

```bash
# Gateway Port (Railway provides this automatically)
PORT=8080

# Kratos Internal URL
KRATOS_INTERNAL=kratos.railway.internal

# Keto Internal URLs
KETO_INTERNAL=keto.railway.internal

# Hydra Internal URL
HYDRA_INTERNAL=hydra.railway.internal

# UI (iam-app) Internal URL and Port
UI_INTERNAL=iam-app.railway.internal
UI_PORT=3000
```

## Notes

- Railway's internal networking uses `{service-name}.railway.internal`
- Replace `iam-app` with your actual Next.js service name in Railway
- The gateway will proxy to all these services
- Only the gateway needs a public URL (`gateway-production-6cac.up.railway.app`)
