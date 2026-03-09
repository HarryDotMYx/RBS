# 🏢 Room Booking System (RBS) v2.0

> A web-based room booking system with calendar interface — migrated and maintained from the original [OxAlto RoomBooking System](https://github.com/neokoenig/RoomBooking) by Tom King.

---

## ✨ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | [cfWheels 3](https://cfwheels.org/) (CFML) |
| **Server** | Lucee 7.0.1 |
| **Database** | MariaDB |
| **UI** | Bootstrap 5.3 |
| **Calendar** | FullCalendar 6.1 |
| **Build Tool** | Vite 7 |
| **Deployment** | Docker Compose |

---

## 🚦 Current Status (Updated: 2026-03-09)

| Feature | Status |
|---|---|
| App boot & routing | ✅ Working |
| Login / session management | ✅ Working |
| Users: create account via UI | ✅ Fixed (`variable [PASSWORD] doesn't exist` resolved) |
| Users: update account without password | ✅ Fixed (password only required when intentionally changing it) |
| Locations list & view | ✅ Fixed |
| Calendar events feed | ✅ Working |
| Booking add / list / view | ✅ Working |
| Event details rendering | ✅ Fixed |
| Security: login brute-force lockout | ✅ Added (5 failures => 10-minute lock) |
| Security: password reset token storage | ✅ Hardened (DB stores token hash, not raw token) |
| Security: API URL token auth (`?token=`) | ✅ Disabled by default (header auth only; opt-in fallback) |
| Security: dev/prod session isolation | ✅ Hardened (`RBS_INSTANCE_NAME` / env-aware app namespace) |
| Security: baseline response headers | ✅ Added (`X-Frame-Options`, `CSP`, `Referrer-Policy`, etc.) |
| Security: flash/log output XSS hardening | ✅ Added (escaped dynamic event titles and log message rendering) |
| Password reset email | ⚠️ Requires SMTP config in `.env` |
| Plugin compatibility (FlashWrapper, shortcodes) | ✅ Addressed |

---

## ⚙️ Runtime Info

```
App path  : /opt/RoomBooking-A/app-v251
Compose   : /opt/RoomBooking-A/docker-compose-v3.yml
App URL   : http://<server-ip>:3999
```

---

## 🚀 Docker Setup & Installation

For a highly detailed, comprehensive guide on how to deploy this system using Docker—including the Automated Zero-Touch Database Installer—please refer to our dedicated documentation:

👉 **[Read the Full Docker Installation Guide](docs/INSTALL_DOCKER.md)**

---

### 🟢 Quick Start (TL;DR)

### 📁 Folder Structure

```
/opt/RoomBooking-A/
├── docker-compose-v3.yml   ← Compose file for this app
└── app-v251/               ← App code (mounted as /app inside container)
    ├── .cfconfig.json      ← Base Lucee config (datasource overridden at runtime)
    ├── index.cfm
    ├── controllers/
    ├── views/
    └── ...
```

---

### 🟢 Start

**First time or after a long pause:**
```bash
cd /opt/RoomBooking-A
cp .env.example .env
# update ADMIN_EMAIL / DB_PASSWORD / DB_ROOT_PASSWORD in .env
docker-compose -f docker-compose-v3.yml up -d
```

> The `-d` flag runs containers in detached (background) mode.

**Check status:**
```bash
docker-compose -f docker-compose-v3.yml ps
```

Expected output:
```
NAME                 STATUS
roombooking-a-db     running (healthy)
roombooking-a-appv3  running
```

---

### 🔄 Restart

**Restart all services:**
```bash
docker-compose -f docker-compose-v3.yml restart
```

**Restart app container only:**
```bash
docker-compose -f docker-compose-v3.yml restart appv3
```

---

### 🔴 Stop

**Stop but keep data:**
```bash
docker-compose -f docker-compose-v3.yml stop
```

**Stop and remove containers (DB data remains safe in volume):**
```bash
docker-compose -f docker-compose-v3.yml down
```

---

### 📋 View Logs

**Live / real-time logs:**
```bash
docker-compose -f docker-compose-v3.yml logs -f appv3
```

**Last 50 lines:**
```bash
docker-compose -f docker-compose-v3.yml logs --tail=50 appv3
```

---

### 🖥️ Shell Access (Inside Container)

```bash
docker exec -it roombooking-a-appv3 /bin/bash
```

> Useful for debugging or inspecting files inside the container.

---

### 🔁 Reload App (Clear Lucee Cache)

After making code changes:
```
http://<server-ip>:3999/index.cfm?reload=roombooking
```

> This clears all controller/model cache without restarting the container.

---

### 🗄️ Database Access

To access the database via CLI:

```bash
docker exec -it roombooking-a-db mariadb \
  -u"${DB_USER:-roombooking}" \
  -p"${DB_PASSWORD:-roombooking123}" \
  "${DB_NAME:-roombooking}"
```

> DB container is internal-only by default (no host port exposure).

---

### 🔧 Troubleshooting

| Problem | Solution |
|---|---|
| Container won't start | Run `docker-compose logs appv3` and check for errors |
| Port 3999 not accessible | Run `docker-compose ps` — ensure status is `running` |
| App errors after editing code | Hit the reload URL or restart the container |
| Database connection error | Ensure the `db` container is also running |
| Auto-install fails with `AUTO_INSTALL requires ADMIN_EMAIL` | Set `ADMIN_EMAIL` in `.env`, then restart `appv3` |
| Password reset throws `no SMTP Server defined` | Set SMTP vars in `.env` (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_TLS`, `SMTP_SSL`) and restart `appv3` |
| Need initial admin password | Check `docker-compose logs appv3` for `RBS_AUTO_INSTALL_ADMIN ...` entry |
| Code changes not taking effect | Lucee cache — hit the reload URL |

---

## 🗄️ Database / Datasource

Configured at runtime from environment variables in `Application.cfc`:

| Datasource | Purpose |
|---|---|
| `roombooking` | Main application database |
| `app` | Compatibility alias for Wheels tooling |

Key env vars:
`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_ROOT_PASSWORD`, `AUTO_INSTALL`, `ADMIN_EMAIL`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_TLS`, `SMTP_SSL`

---

## 🔧 Migration Notes (Wheels 1.x/2.x → 3.x)

1. **Controller path fix** — `wheels/events/onapplicationstart.cfc` updated from `/app/controllers` → `/controllers` to resolve a Docker path mismatch that caused all controllers to fall back to internal test fixtures.
2. **Legacy helper shims** — added to `controllers/Controller.cfc` for Wheels 3 compatibility.
3. **Variable scoping** — `locations`, `settings`, `resources` explicitly scoped to `variables` in controller filters.
4. **Shortcode/template rendering** — replaced with direct rendering paths for stability.
5. **Test runner** — `tests/runner.cfm` intentionally disabled in production deployment.
6. **Install files** — removed from active deployment flow.

---

## 🏆 Credits and Acknowledgements

This comprehensive v2.0 overhaul—spanning UI modernization, automated Docker deployment pipelines, system security patches, and structural architecture upgrades—was engineered and finalized by:

✨ **PG Mohd Azhan Fikri ([HarryDotMYx](https://github.com/HarryDotMYx))**

Deep appreciation is extended for his rigorous efforts in transforming and elevating the Room Booking System to its current professional-grade standard.

---

## 📄 License & Attribution

- **Original project:** OxAlto Room Booking System — © Tom King ([@neokoenig](https://github.com/neokoenig))
- **Original repo:** https://github.com/neokoenig/RoomBooking
- **License:** Apache License 2.0

This maintained fork includes migration and stability updates for modern runtime (cfWheels 3 + Lucee 7) compatibility.
