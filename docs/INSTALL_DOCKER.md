# 🐳 Docker Installation Guide (Room Booking System)

This document provides step-by-step instructions on how to deploy the Room Booking System (RBS) using Docker.

---

## 🚀 Quick Start Instructions

### Step 1: Clone the Repository
Download the project source code to your machine/server.
```bash
git clone https://github.com/HarryDotMYx/RBS.git
cd RBS
```

### Step 2: Configure Environment Variables
Ensure you are in the project root directory where the `docker-compose-v3.yml` file is located.

Create your local env file:
```bash
cp .env.example .env
```

Required values:
- `ADMIN_EMAIL` (mandatory for auto-install)
- `DB_PASSWORD`
- `DB_ROOT_PASSWORD`

### Step 3: Run Docker Compose
Execute:
```bash
docker-compose -f docker-compose-v3.yml up -d
```
*Note: You must run this command from the project root, not from inside the `app-v251` folder.*

### Step 4: Verify Status
Check that the containers are running properly.
```bash
docker-compose -f docker-compose-v3.yml ps
```

---

## 🖥️ Accessing the System

Open your web browser and navigate to:
- **`http://localhost:3999`** or **`http://<YOUR-SERVER-IP>:3999`**

Database schema and initial admin will be auto-created on first run (`AUTO_INSTALL=true`).

To get the generated initial admin password:
```bash
docker-compose -f docker-compose-v3.yml logs --tail=100 appv3
```
Look for log entry:
`RBS_AUTO_INSTALL_ADMIN email=... password=...`

---

## 🛠️ Troubleshooting

### 1. Error: `no configuration file provided`
*   **Cause**: You are likely running the command from the wrong directory (e.g., inside the `app-v251` folder).
*   **Solution**: Move back to the project root directory. Run `cd ..` if you are currently in `app-v251`. Ensure you can see the `docker-compose-v3.yml` file when you run `ls`.

### 2. Error: `No such file or directory`
*   Ensure that you have fully cloned the repository.
*   Verify that you are inside the `RoomBooking-A` directory.

### 3. Error: `AUTO_INSTALL requires ADMIN_EMAIL to be set`
*   **Cause**: `AUTO_INSTALL=true` but `ADMIN_EMAIL` is empty.
*   **Solution**: Set `ADMIN_EMAIL` in `.env`, then restart app container.

### 4. Resetting the Installation (fresh DB)
If you need to restart from a clean database:
1. Stop stack and remove DB volume: `docker-compose -f docker-compose-v3.yml down -v`
2. Start again: `docker-compose -f docker-compose-v3.yml up -d`
3. Read generated admin password from app logs.

---

## 🏆 Credits
v2.0 Update (Modern UI, Docker Pipeline, Auto-Installer) engineered by:
✨ **PG Mohd Azhan Fikri ([HarryDotMYx](https://github.com/HarryDotMYx))**

---
**Build Info:** Lucee 7 • MariaDB • Version 2.0
