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

### Step 2: Run Docker Compose
Ensure you are in the project root directory where the `docker-compose-v3.yml` file is located.

Execute the following command:
```bash
docker-compose -f docker-compose-v3.yml up -d
```
*Note: You must run this command from the project root, not from inside the `app-v251` folder.*

### Step 3: Verify Status
Check that the containers are running properly.
```bash
docker-compose -f docker-compose-v3.yml ps
```

---

## 🖥️ Accessing the System

Open your web browser and navigate to:
- **`http://localhost:3999`** or **`http://<YOUR-SERVER-IP>:3999`**

The system will automatically redirect you to the **Automated Setup Wizard** to initialize the database.

---

## 🛠️ Troubleshooting

### 1. Error: `no configuration file provided`
*   **Cause**: You are likely running the command from the wrong directory (e.g., inside the `app-v251` folder).
*   **Solution**: Move back to the project root directory. Run `cd ..` if you are currently in `app-v251`. Ensure you can see the `docker-compose-v3.yml` file when you run `ls`.

### 2. Error: `No such file or directory`
*   Ensure that you have fully cloned the repository.
*   Verify that you are inside the `RoomBooking-A` directory.

### 3. Resetting the Installation
If you need to restart the setup from scratch:
1. Delete the lock file: `rm app-v251/config/install.lock`
2. Restart the containers: `docker-compose -f docker-compose-v3.yml restart`
3. Access the URL again in your browser.

---

## 🏆 Credits
v2.0 Update (Modern UI, Docker Pipeline, Auto-Installer) engineered by:
✨ **PG Mohd Azhan Fikri ([HarryDotMYx](https://github.com/HarryDotMYx))**

---
**Build Info:** Lucee 7 • MariaDB • Version 2.0
