# Gateway Service

This is the single public-facing service that routes all traffic to internal services.

## Architecture

```
Internet → Gateway (nginx) → Internal Services
                ├─ /admin/*          → Kratos Admin (port 4434)
                ├─ /self-service/*   → Kratos Public (port 4433)
                ├─ /sessions/*       → Kratos Public (port 4433)
                ├─ /health/*         → Kratos Public (port 4433)
                ├─ /relation-tuples  → Keto (port 4466)
                └─ /*                → UI Application
```

## Configuration

The Gateway uses environment variables for routing to internal services:

| Variable          | Description                          | Example                          |
| ----------------- | ------------------------------------ | -------------------------------- |
| `PORT`            | Gateway listen port (set by Railway) | `8080`                           |
| `KRATOS_INTERNAL` | Kratos internal address              | `http://kratos.railway.internal` |
| `KETO_INTERNAL`   | Keto internal address                | `http://keto.railway.internal`   |
| `UI_INTERNAL`     | UI internal address                  | `http://ui.railway.internal`     |

## Railway Setup

1. **Deploy Gateway service** with public access
2. **Deploy other services** (Kratos, Keto, UI) as internal-only:
   - Disable public networking on these services
   - Gateway will connect via Railway's private network
3. **Set environment variables** in Gateway service:
   ```
   KRATOS_INTERNAL=http://kratos.railway.internal
   KETO_INTERNAL=http://keto.railway.internal
   UI_INTERNAL=http://ui.railway.internal
   ```

## ⚠️ Security Warning

**The admin API at `/admin/*` is currently exposed without authentication!**

This allows full control over your identity system. Add authentication before production use.

## Adding Authentication to Admin API

Edit [nginx.conf.template](nginx.conf.template) to add authentication:

### Option 1: Basic Auth

```nginx
location ^~ /admin/ {
  auth_basic "Admin Access";
  auth_basic_user_file /etc/nginx/.htpasswd;

  proxy_pass ${KRATOS_INTERNAL}:4434/admin/;
  # ... (keep existing proxy headers)
}
```

Build with htpasswd file:

```dockerfile
RUN apk add --no-cache apache2-utils
RUN htpasswd -bc /etc/nginx/.htpasswd admin your-password
```

### Option 2: API Key Header

```nginx
location ^~ /admin/ {
  if ($http_x_api_key != "${ADMIN_API_KEY}") {
    return 401 "Unauthorized";
  }

  proxy_pass ${KRATOS_INTERNAL}:4434/admin/;
  # ... (keep existing proxy headers)
}
```

Add `ADMIN_API_KEY` environment variable and update start.sh:

```bash
envsubst '${PORT} ${KRATOS_INTERNAL} ${UI_INTERNAL} ${KETO_INTERNAL} ${ADMIN_API_KEY}'
```

### Option 3: IP Whitelist

```nginx
location ^~ /admin/ {
  # Only allow from Railway private network
  allow 10.0.0.0/8;
  deny all;

  proxy_pass ${KRATOS_INTERNAL}:4434/admin/;
  # ... (keep existing proxy headers)
}
```

### Option 4: OAuth2 Proxy (Recommended for Production)

Use [OAuth2 Proxy](https://oauth2-proxy.github.io/oauth2-proxy/) as a sidecar:

- Deploy OAuth2 Proxy in Gateway
- Configure with your identity provider
- Route `/admin/*` through OAuth2 Proxy first

## Maintenance

### Updating Routes

Edit [nginx.conf.template](nginx.conf.template) to add/modify routes.

### Testing Configuration

```bash
# Check nginx config syntax
docker run --rm -v $(pwd)/nginx.conf.template:/etc/nginx/nginx.conf:ro nginx:alpine nginx -t -c /etc/nginx/nginx.conf
```

## Files

- `Dockerfile` - Builds nginx image with envsubst
- `nginx.conf.template` - nginx configuration with variable placeholders
- `start.sh` - Entrypoint that substitutes environment variables and starts nginx
