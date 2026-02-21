# 🏢 Room Booking System (RBS)

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

## 🚦 Current Status

| Feature | Status |
|---|---|
| App boot & routing | ✅ Working |
| Login / session management | ✅ Fixed |
| Locations list & view | ✅ Fixed |
| Calendar events feed | ✅ Working |
| Booking add / list / view | ✅ Working |
| Event details rendering | ✅ Fixed |
| Plugin compatibility (FlashWrapper, shortcodes) | ✅ Addressed |

---

## ⚙️ Runtime Info

```
App path  : /opt/RoomBooking-A/app-v251
Compose   : /opt/RoomBooking-A/docker-compose-v3.yml
App URL   : http://<server-ip>:3999
```

---

## 🚀 Docker Guide

### Prerequisites

Make sure the following are installed:
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

Verify:
```bash
docker --version
docker-compose --version
```

---

### 📁 Folder Structure

```
/opt/RoomBooking-A/
├── docker-compose-v3.yml   ← Compose file for this app
└── app-v251/               ← App code (mounted as /app inside container)
    ├── .cfconfig.json      ← Datasource configuration
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
docker-compose -f docker-compose-v3.yml up -d
```

> The `-d` flag runs containers in detached (background) mode.

**Check status:**
```bash
docker-compose -f docker-compose-v3.yml ps
```

Expected output:
```
NAME                    STATUS    PORTS
roombooking-a-appv3     running   0.0.0.0:3999->8080/tcp
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
docker exec -it roombooking-a-appv3 /bin/bash
# Inside container:
mysql -h db -u roombooking -proombooking123 roombooking
```

Or use any MySQL client from the host by connecting to the exposed port (check `docker-compose-v3.yml`).

---

### 🔧 Troubleshooting

| Problem | Solution |
|---|---|
| Container won't start | Run `docker-compose logs appv3` and check for errors |
| Port 3999 not accessible | Run `docker-compose ps` — ensure status is `running` |
| App errors after editing code | Hit the reload URL or restart the container |
| Database connection error | Ensure the `db` container is also running |
| Code changes not taking effect | Lucee cache — hit the reload URL |

---

## 🗄️ Database / Datasource

Configured in `.cfconfig.json`:

| Datasource | Purpose |
|---|---|
| `roombooking` | Main application database |
| `app` | Compatibility alias for Wheels tooling |

---

## 🔧 Migration Notes (Wheels 1.x/2.x → 3.x)

1. **Controller path fix** — `wheels/events/onapplicationstart.cfc` updated from `/app/controllers` → `/controllers` to resolve a Docker path mismatch that caused all controllers to fall back to internal test fixtures.
2. **Legacy helper shims** — added to `controllers/Controller.cfc` for Wheels 3 compatibility.
3. **Variable scoping** — `locations`, `settings`, `resources` explicitly scoped to `variables` in controller filters.
4. **Shortcode/template rendering** — replaced with direct rendering paths for stability.
5. **Test runner** — `tests/runner.cfm` intentionally disabled in production deployment.
6. **Install files** — removed from active deployment flow.

---

## 📄 License & Attribution

- **Original project:** OxAlto Room Booking System — © Tom King ([@neokoenig](https://github.com/neokoenig))
- **Original repo:** https://github.com/neokoenig/RoomBooking
- **License:** Apache License 2.0

This maintained fork includes migration and stability updates for modern runtime (cfWheels 3 + Lucee 7) compatibility.
