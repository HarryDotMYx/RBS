# 🐳 Panduan Pemasangan Docker (Room Booking System)

Dokumen ini menerangkan cara untuk pasang sistem RBS menggunakan Docker. Kami telah mudahkan bahasa dan langkah-langkah supaya senang diikuti.

---

## 🛑 PENTING: Jika ada error "no configuration file provided"
Error ini berlaku sebab anda jalankan command di dalam folder yang salah. Sila pastikan anda berada di **Project Root** (bukan di dalam folder `app-v251`).

**Cara betulkan:**
```bash
cd /opt/RoomBooking-A
```

---

## 🚀 Langkah-Langkah Pemasangan (Quick Start)

### Langkah 1: Masuk ke folder projek
Pastikan anda berada di folder utama projek.
```bash
cd /opt/RoomBooking-A
```

### Langkah 2: Jalankan Docker Compose
Gunakan file `docker-compose-v3.yml` untuk versi terbaru.
```bash
docker-compose -f docker-compose-v3.yml up -d
```
*Nota: `-d` bermaksud ia akan berjalan di 'background'.*

### Langkah 3: Semak status
Pastikan kontena dalam keadaan `running`.
```bash
docker-compose -f docker-compose-v3.yml ps
```

---

## 🖥️ Cara Akses Sistem

Buka browser dan pergi ke:
- **`http://localhost:3999`** atau **`http://<IP-SERVER-ANDA>:3999`**

Sistem akan bawa anda ke **Setup Wizard** secara automatik.

1.  **Database Auto-Setup**: Sistem akan buat table secara automatik. Anda akan nampak mesej *"Database schema successfully verified/created."*
2.  **Akaun Admin**: Masukkan username dan password untuk Admin.
3.  **Selesai**: Klik butang hijau untuk masuk ke Dashboard.

---

## 🛠️ Masalah Biasa (Troubleshooting)

### 1. Error: `no configuration file provided: not found`
*   **Sebab**: Anda berada di dalam folder `app-v251` atau folder lain yang tiada file `.yml`.
*   **Penyelesaian**: Jalankan `cd /opt/RoomBooking-A` terlebih dahulu.

### 2. Laman web tidak keluar (Connection Refused)
*   Pastikan port `3999` tidak digunakan oleh program lain.
*   Check log untuk lihat error: `docker logs roombooking-a-appv3`

### 3. Reset Semula (Mula dari awal)
Jika anda tersalah isi data atau ingin pasang semula:
1. Padam file lock: `rm app-v251/config/install.lock`
2. Restart container: `docker-compose -f docker-compose-v3.yml restart`
3. Pergi semula ke URL di browser.

---

## 🏆 Penghargaan
Update v2.0 (UI Modern, Docker Pipeline, Auto-Installer) dilakukan oleh:
✨ **PG Mohd Azhan Fikri ([HarryDotMYx](https://github.com/HarryDotMYx))**

---
**Build Info:** Lucee 7 • MariaDB • Version 2.0
