# Docker Setup untuk Moodle 5.2.2

Setup development/testing Moodle menggunakan Docker:
- **PHP 8.4 + Apache** (DocumentRoot = `public/`)
- **MariaDB 10.11**
- **Cron** berjalan otomatis sebagai service terpisah
- Source di-bind-mount dari repo ini — perubahan kode langsung terlihat

## Image Docker

Image dibuild otomatis oleh **GitHub Actions** dan di-push ke **GHCR**:

- Workflow: `.github/workflows/docker-image.yml`
- Image: `ghcr.io/frostlynn/lms-template:<tag>`
  - Branch → `ghcr.io/frostlynn/lms-template:<branch>`
  - Tag `v*` → `ghcr.io/frostlynn/lms-template:<version>` dan `<major>.<minor>`
  - Default branch → `ghcr.io/frostlynn/lms-template:latest`

> **Penting**: workflow build image jalan otomatis setiap push ke repo ini.
> Image di-push ke GHCR atas nama repo (`FrostLynn/lms-template`).
> Untuk pertama kali, pastikan repo GitHub sudah dibuat di akun kamu
> dan push branch ini ke sana.

### Pull image dari GHCR (perlu login sekali)

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin
```

Image GHCR public bisa ditarik tanpa login.

### Set image di compose

Nama image dikontrol oleh variable `MOODLE_IMAGE` (default `ghcr.io/frostlynn/lms-template:latest`):

```bash
# Via .env file
cp .env.example .env
# edit .env → ganti MOODLE_IMAGE=ghcr.io/frostlynn/lms-template:latest

# atau langsung di shell
MOODLE_IMAGE=ghcr.io/frostlynn/lms-template:latest docker compose up -d
```

## Quick Start

### Opsi A — Pakai image dari GHCR (default)

```bash
cp .env.example .env   # lalu sesuaikan MOODLE_IMAGE dengan owner kamu
docker compose up -d
```

### Opsi B — Build lokal (development, tanpa GHCR)

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

Buka `http://localhost:8080` di browser. Karena database belum ter-install,
Moodle akan redirect ke wizard instalasi (`install.php`).

## Instalasi

### Via Web (disarankan)
1. Buka `http://localhost:8080`
2. Pilih bahasa → lanjutkan wizard
3. Konfigurasi database sudah terisi otomatis:
   - Database type: **MariaDB**
   - Host: `db`
   - Database: `moodle`
   - User: `moodle`
   - Password: `moodlepass`
   - Tables prefix: `mdl_`
4. Lanjutkan sampai admin account dibuat.

### Via CLI (alternatif)
```bash
docker compose exec web php admin/cli/install.php \
  --wwwroot=http://localhost:8080 \
  --dataroot=/var/www/moodledata \
  --dbtype=mariadb \
  --dbhost=db \
  --dbname=moodle \
  --dbuser=moodle \
  --dbpass=moodlepass \
  --adminuser=admin \
  --adminpass=Admin123! \
  --adminemail=admin@example.com \
  --fullname="Moodle" \
  --shortname=moodle \
  --agree-license
```

## Konfigurasi

Semua pengaturan diambil dari environment variables di `docker-compose.yml`:

| Variable | Default | Deskripsi |
|---|---|---|
| `MOODLE_DB_HOST` | `db` | Host database |
| `MOODLE_DB_NAME` | `moodle` | Nama database |
| `MOODLE_DB_USER` | `moodle` | User database |
| `MOODLE_DB_PASSWORD` | `moodlepass` | Password database |
| `MOODLE_WWWROOT` | `http://localhost:8080` | URL publik Moodle |
| `MOODLE_DATAROOT` | `/var/www/moodledata` | Direktori data |
| `MOODLE_DEBUG` | `1` | `1` = debug mode aktif |
| `MOODLE_DB_TYPE` | `mariadb` | Tipe database (mariadb/mysqli/pgsql) |

`config.php` dibuat otomatis saat container start dari env var ini.
Jika `config.php` sudah ada di repo, file itu yang dipakai (tidak ditimpa).

## Perintah Umum

```bash
# Log web
docker compose logs -f web

# Log cron
docker compose logs -f cron

# Jalankan cron manual (sekali jalan)
docker compose exec web php admin/cli/cron.php

# Akses shell container
docker compose exec web bash

# Stop semua service (data tetap tersimpan)
docker compose down

# Hapus semua termasuk data (database + moodledata)
docker compose down -v

# Rebuild image lokal setelah ubah Dockerfile
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

## Struktur

```
Dockerfile                    # PHP 8.4 + Apache, DocumentRoot di public/
docker-compose.yml            # web + db (MariaDB) + cron, image dari GHCR
docker-compose.dev.yml        # Override: build image lokal untuk development
.env.example                  # Template env (MOODLE_IMAGE dll)
docker/entrypoint.sh          # Generate config.php dari env saat container start
.github/workflows/docker-image.yml  # Build + push image ke GHCR
```

## Catatan

- **Moodle 5.x menaruh webroot di `public/`** — bukan root repo.
  Jangan arahkan Apache DocumentRoot ke root repo.
- **Semua library PHP dibundle** di `public/lib/` — tidak perlu `composer install`.
- **Aset frontend sudah ter-build** di repo (grunt/npm tidak diperlukan).
- **Cron** memakai `admin/cli/cron.php --keep-alive=55` yang berjalan terus
  sebagai proses daemon di service `cron`.
- Untuk produksi, ganti password di `docker-compose.yml`, matikan `MOODLE_DEBUG`,
  dan tambahkan reverse proxy SSL (misal Caddy/Nginx).
