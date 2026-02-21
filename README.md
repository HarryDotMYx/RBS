# Room Booking System (RBS)

Migrated and maintained instance of the original OxAlto Room Booking System, currently running on:

- **Wheels 3.0.0**
- **Lucee 7.0.1.100**
- **MariaDB (roombooking DB)**
- **Docker Compose deployment**

> This repository is a practical migration lane (`:3999`) from legacy Wheels 1.x/2.x behavior to Wheels 3 compatibility.

---

## Current Status

- ✅ Core app boots and routes correctly
- ✅ Login flow stabilized (legacy helper compatibility shims added)
- ✅ Calendar events feed works
- ✅ Booking add/list/view flows are functional
- ✅ Event details fallback/inline rendering fixed
- ✅ Legacy plugin compatibility warnings addressed (FlashWrapper + shortcodes)

---

## Runtime Paths

- App code: `/opt/RoomBooking-A/app-v251`
- Compose file: `/opt/RoomBooking-A/docker-compose-v3.yml`
- App URL: `http://<server-ip>:3999`

---

## Start / Restart

```bash
cd /opt/RoomBooking-A
docker-compose -f docker-compose-v3.yml up -d
```

Restart app service only:

```bash
cd /opt/RoomBooking-A
docker-compose -f docker-compose-v3.yml restart appv3
```

Check status:

```bash
cd /opt/RoomBooking-A
docker-compose -f docker-compose-v3.yml ps
```

---

## Data Source

Configured datasources:

- `roombooking`
- `app` (alias for compatibility with Wheels tooling pages)

Defined in `.cfconfig.json`.

---

## Known Migration Notes

1. Some legacy helper behaviors are shimmed in `controllers/Controller.cfc` for Wheels 3 compatibility.
2. Some shortcode/template rendering paths were replaced with direct rendering for stability.
3. `tests/runner.cfm` is intentionally redirected/disabled for production-like use.
4. `install/` files were removed from active deployment flow.

---

## Original Project Attribution

Original project: **OxAlto Room Booking System** by Tom King (@neokoenig)

- Original source: https://github.com/neokoenig/RoomBooking
- License: Apache License 2.0

This maintained fork includes migration/stability updates for modern runtime compatibility.
