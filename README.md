<div align="center">
  <h1>🏢 Room Booking System (RBS) v2.0</h1>
  <p><strong>Next-Generation Enterprise Room Management System</strong></p>
  
  [![Lucee](https://img.shields.io/badge/Lucee-7.0.2-blue.svg?style=for-the-badge&logo=lucee)](https://lucee.org/)
  [![Wheels](https://img.shields.io/badge/cfWheels-3.x-red.svg?style=for-the-badge)](#)
  [![MariaDB](https://img.shields.io/badge/MariaDB-11.4-003545.svg?style=for-the-badge&logo=mariadb)](https://mariadb.org/)
  [![Bootstrap](https://img.shields.io/badge/Bootstrap-5.3-7952b3.svg?style=for-the-badge&logo=bootstrap)](https://getbootstrap.com/)
  [![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED.svg?style=for-the-badge&logo=docker)](https://www.docker.com/)
  [![Status](https://img.shields.io/badge/Status-Active-success.svg?style=for-the-badge)]()
</div>

<br />

---

## 🚀 Welcome to RBS v2.0

RBS v2.0 is a robust, premium web-based room booking and calendar management system. Comprehensively migrated and heavily enhanced from the original OxAlto core, RBS v2.0 represents a monumental leap in software architecture, delivering modern security, zero-touch automated deployments, and a stunning **Dark Glassmorphism UI** tailored for professional enterprise environments.

---

## ✨ Key Features & Enhancements

💎 **Premium UI/UX Engine**
- Complete frontend and backend redesign featuring a dynamic, responsive **Dark Glassmorphism** aesthetic.
- Enhanced Admin Dashboard packed with interactive, intuitive layouts and polished visual interactions.
- FullCalendar 6.1 integration for silky smooth booking and scheduling operations.

🛡️ **Enterprise-Grade Security Architecture**
- **Brute-Force Protection:** Active counter-measures with automated login throttles (5 consecutive failures = 10-minute lockout).
- **Hardened Cryptography:** Password reset tokens are securely hashed dynamically within the database layer.
- **Strict Network Headers:** Comprehensive deployment of `X-Frame-Options`, strict `CSP`, and `Referrer-Policy`.
- **Environment Isolation:** Advanced runtime namespace scoping via `RBS_INSTANCE_NAME` for parallel cluster safety.
- **Input Sanitization:** Deep-level escaping on dynamic event titles and log message renderers (XSS Proofed).

⚡ **Next-Gen Automation & DevOps**
- **Automated Zero-Touch Installer:** Spin up the Database and Application dynamically with no manual CFML wizard data entry required.
- **Docker Native:** Pre-engineered with optimized `docker-compose-v3.yml` for instant, scalable, and highly available infrastructure.
- **CommandBox Powered:** Leverages the robust Ortus CommandBox Lucee engine on standard port mappings.

---

## 🛠️ Technology Stack Breakdown

| Architecture Layer    | Technology Framework / Engine |
|-----------------------|--------------------------------|
| **Core Application**  | [cfWheels 3](https://cfwheels.org/) (CFML MVC Framework) |
| **Application Server**| Lucee 7.0.2.106 |
| **Relational DB**     | MariaDB 11.4 |
| **UI Framework**      | Bootstrap 5.3 + FullCalendar 6.1 |
| **Asset Pipeline**    | Vite 7 |
| **Infrastructure**    | Docker Compose + Ortus CommandBox |

---

## 🚀 Docker Setup & Deployment Guide

RBS v2.0 is optimized to run flawlessly in Docker containers. For a highly detailed, comprehensive guide covering our Automated Zero-Touch Database Installer, read the dedicated documentation:

👉 **[Read the Full Docker Installation Guide](docs/INSTALL_DOCKER.md)**

### 🟢 Quick Start (TL;DR)

**1. Clone & Configure Environment**
```bash
cd /opt/RBS/app
cp .env.example .env
```
*(Update `ADMIN_EMAIL`, `DB_PASSWORD`, and `DB_ROOT_PASSWORD` in your `.env` file first!)*

**2. Deploy Infrastructure**
```bash
docker-compose -f docker-compose-v3.yml up -d
```
> The `-d` flag runs the containers in detached (background) mode gracefully.

**3. Verify Matrix Operations**
```bash
docker-compose -f docker-compose-v3.yml ps
```
*Expected output:*
```text
NAME                 STATUS
roombooking-a-db     running (healthy)
roombooking-a-appv3  running
```

---

## ⚙️ Container Management Commands

### 🔄 Restart Services
```bash
# Full stack restart
docker-compose -f docker-compose-v3.yml restart

# Restart application node only (Lucee Engine reload)
docker-compose -f docker-compose-v3.yml restart appv3
```

### 🔴 Stop & Teardown
```bash
# Pause infrastructure (data & containers preserved)
docker-compose -f docker-compose-v3.yml stop

# Complete teardown (DB records remain safe in volume mounts)
docker-compose -f docker-compose-v3.yml down
```

### 📋 Live Container Telemetry (Logs)
```bash
docker-compose -f docker-compose-v3.yml logs -f appv3
```

### 🔁 Application Hot-Reload
Flush the Lucee framework cache instantly without executing a container restart:
```
http://<server-ip>:3999/index.cfm?reload=roombooking
```
> Note: If `RBS_RELOAD_PASSWORD` is defined in `.env`, append `&password=your_password`.

---

## 🗄️ Database Access & Diagnostics

Jump explicitly into your MariaDB instance via direct CLI bridge:

```bash
docker exec -it roombooking-a-db mariadb \
  -u"${DB_USER:-roombooking}" \
  -p"${DB_PASSWORD:-roombooking123}" \
  "${DB_NAME:-roombooking}"
```
 *(For security purposes, the database container is internal-only and not directly exposed to host ports)*

---

## 🏆 Credits and Acknowledgements

This comprehensive v2.0 overhaul—spanning UI modernization, automated Docker deployment pipelines, system security patches, and structural architecture upgrades—was entirely engineered and finalized by:

### ✨ **PG Mohd Azhan Fikri ([HarryDotMYx](https://github.com/HarryDotMYx))**

Deep appreciation is extended for his rigorous efforts in transforming, fine-tuning, and elevating the Room Booking System to its current **ultra-professional, enterprise-grade standard.**

---

## 📄 License & Attribution

- **Original Project:** OxAlto Room Booking System — © Tom King ([@neokoenig](https://github.com/neokoenig))
- **Original Source:** https://github.com/neokoenig/RoomBooking
- **License:** Apache License 2.0

*This radically overhauled maintainer fork includes vast migration updates, stability patches, and modernization pipelines specifically engineered for CFWheels 3 & Lucee 7 deployment models.*
