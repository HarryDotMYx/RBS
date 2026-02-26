# Docker Installation Guide (Room Booking System v2.0)

This document provides a highly comprehensive, step-by-step guide on how to configure, deploy, and initialize the Room Booking System (RBS) v2.0 within a containerized Docker ecosystem.

The system is equipped with an **Automated Zero-Touch Setup wizard**, eliminating the need for manual SQL schema imports.

---

## 🖥️ System Requirements

This software architecture is designed to operate seamlessly within modern containerized environments.

1. **Operating System (OS)**:
   * **Linux**: Ubuntu 22.04 LTS or 24.04 LTS (Highly Recommended for Production Environments).
   * **Alternative Distributions**: Debian 11/12, CentOS Stream 9, or Alpine Linux.
   * **Windows/macOS**: Compatible via Docker Desktop (strictly for development and testing purposes).

2. **Required Dependencies**:
   * **Docker Engine**: Version 24.0 or higher.
   * **Docker Compose**: Version 2.20 or higher.

3. **Server Specifications**:
   * **Processor (CPU)**: Dynamically allocated by Docker (1 vCPU is sufficient for standard workloads).
   * **Memory (RAM)**: Minimum of 2GB RAM allocated to the Docker Engine.
   * **Storage**: Minimum of 10GB available disk space (to accommodate Docker images and the relational database).

---

## 🐳 System Architecture

The deployment architecture utilizes two primary interconnected containers operating within an isolated Docker network:

| Component | Docker Image | Role |
| :--- | :--- | :--- |
| **Application Layer** | `ortussolutions/commandbox:lucee5` | The robust ColdFusion (Lucee) web server engine responsible for processing the CFWheels v2.x backend logic. |
| **Data Layer** | `mariadb:10.11` | A high-performance, stable SQL database orchestrating the storage of facility records, user credentials, and system configurations. |

---

## 🚀 Deployment Instructions

### Step 1: Clone the Repository
Access your terminal and clone the project source code into your preferred directory (e.g., `/opt`).

```bash
cd /opt
git clone <YOUR_REPOSITORY_URL> RoomBooking-A
cd RoomBooking-A
```

### Step 2: Configure Docker Compose
Ensure the `docker-compose.yml` (or `docker-compose-v3.yml`) file is present in the root directory. This configuration dictates the port mappings, natively binding port `3999` on the host machine to port `8080` internally on the Lucee container.

### Step 3: Initialize the Containers
Execute the following command to retrieve the required images and initialize the system payload:

```bash
docker-compose up -d
```
*(The `-d` flag executes the containers in detached mode, returning control to the terminal.)*

Verify the operational status of the containers:
```bash
docker ps
```
*Expected: Both the application container and the database container should reflect an `Up` status.*

### Step 4: Access the Automated Zero-Touch Installer
1. Launch your preferred modern web browser.
2. Navigate to your server's designated IP address and port (e.g., **`http://localhost:3999`** or `http://192.168.200.31:3999`).
3. **Critical Behavior**: Because the database schema is uninitialized upon first boot, the application will intelligently intercept your request and redirect you to `/install/index.cfm`.
4. The Automated Setup Wizard will execute the `new-installation.sql` payload instantaneously behind the scenes. You will be greeted with the confirmation: **"Database schema successfully verified/created."**

### Step 5: Provision the Primary Administrator Account
1. On the same Setup Wizard interface, input the credentials and personal information for the inaugural System Administrator.
2. Click **Submit**.
3. The system will confirm success by displaying **"Installation Complete!"** alongside a prompt to enter the application.
4. Concurrently, an overarching security mechanism generates the `config/install.lock` file. This locks down the `/install` directory completely, neutralizing unauthorized subsequent access attempts.
5. Click the green continuation button to access the Room Booking System dashboard.

---

## 🛠️ Troubleshooting Guide

**1. White Screen of Death (WSOD) or 500 Responses**
*   Verify that the Docker Compose stack is fully active. Inspect the Lucee server logs for stack traces:
    *   `docker logs roombooking-a-appv3 -f`

**2. Database Connection Failure (DSN Error)**
*   If the application container fails to establish a handshake with MariaDB, verify the hostname mapped in your DSN settings corresponds exactly to the service name defined in `docker-compose.yml` (typically `db`).

**3. Resetting the Installation Environment**
If administrative credentials were input incorrectly or you wish to simulate a pristine deployment state:
1. Purge the lock file: `rm app-v251/config/install.lock`
2. Drop all tables within the MariaDB container (`DROP TABLE ...`).
3. Cycle the application container: `docker restart roombooking-a-appv3`
4. Re-navigate to the primary URL to trigger the Zero-Touch Installer.

---

## 🏆 Credits and Acknowledgements

This comprehensive v2.0 overhaul—including the complete UI modernization, automated Docker deployment pipelines, system security patches, and structural architecture upgrades—was engineered and finalized by:

✨ **PG Mohd Azhan Fikri ([HarryDotMYx](https://github.com/HarryDotMYx))**

We extend our deep appreciation for his rigorous efforts in transforming and elevating the Room Booking System to its current professional-grade standard.

---
**Powered by:** Lucee CFML Engine • CommandBox • Bootstrap 3 • Flexbox UI 
**Current Build:** Version 2.0 :)
