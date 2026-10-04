# reporting.tw on the existing server (no Docker)

Everything runs as the single user `reportingtw` under `/sites/reporting.tw`, behind the server's Apache, with the
server's MySQL 8. The three systemd services below are processes, not accounts: all of them run as `reportingtw`. Cloudflare sits in front (SSL mode "Full", self-signed origin certificate).

```
/sites/reporting.tw/
  site/  app/  console/     static web files (served by Apache)
  src/                      this repository (backend, deploy files, docs)
  src/backend/.venv/        Python 3.12 virtualenv (uv)
  bin/tusd                  resumable upload server
  data/                     evidence (uploads/, frames/) - private
  reporting.env             settings + secrets (chmod 600)
```

| Service | Listens | Unit |
| --- | --- | --- |
| API (FastAPI) | 127.0.0.1:8100 | `reporting-api.service` (runs DB migrations on start) |
| Worker | - | `reporting-worker.service` |
| Uploads (tusd) | 127.0.0.1:8180 | `reporting-tusd.service` |

| Host (Cloudflare, proxied) | Served by Apache |
| --- | --- |
| `reporting.tw`, `www.` | landing page `/`, informant web app `/app/` |
| `api.reporting.tw` | API + `/files/` uploads |
| `console.reporting.tw` | agency console (protect with Cloudflare Access) |

## 1. As root: MySQL database and user

```sh
sudo mysql <<'SQL'
CREATE DATABASE reporting CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER 'reporting'@'localhost' IDENTIFIED BY 'CHANGE_ME_DB_PASSWORD';
CREATE USER 'reporting'@'127.0.0.1' IDENTIFIED BY 'CHANGE_ME_DB_PASSWORD';
GRANT ALL PRIVILEGES ON reporting.* TO 'reporting'@'localhost', 'reporting'@'127.0.0.1';
SQL
```

The first migration tries to create triggers that make `case_event` and `audit_log` append-only. As a normal MySQL
user with binary logging on, that fails; the migration prints a warning and continues (the application never updates
those tables). Optional, after step 4, as root (root may create them without changing any global setting):

```sh
sudo mysql reporting <<'SQL'
CREATE TRIGGER case_event_no_update BEFORE UPDATE ON case_event FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'case_event is append-only';
CREATE TRIGGER case_event_no_delete BEFORE DELETE ON case_event FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'case_event is append-only';
CREATE TRIGGER audit_log_no_update BEFORE UPDATE ON audit_log FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'audit_log is append-only';
CREATE TRIGGER audit_log_no_delete BEFORE DELETE ON audit_log FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'audit_log is append-only';
SQL
```

## 2. As root: let Apache read the web folders

```sh
sudo chmod 711 /sites/reporting.tw            # traverse only; nothing listable
sudo chmod -R a+rX /sites/reporting.tw/site /sites/reporting.tw/app /sites/reporting.tw/console
```

## 3. As reportingtw: Python, backend, tusd

```sh
cd /sites/reporting.tw
curl -LsSf https://astral.sh/uv/install.sh | sh          # installs uv into ~/.local/bin
source ~/.local/bin/env
uv python install 3.12
cd src/backend && uv sync --no-dev --python 3.12 && cd ../..

mkdir -p bin data/uploads data/frames && chmod 700 data
curl -L https://github.com/tus/tusd/releases/download/v2.10.1/tusd_linux_amd64.tar.gz | tar xz -C /tmp
mv /tmp/tusd_linux_amd64/tusd bin/tusd && bin/tusd -version

cp src/deploy/prod/reporting.env.example reporting.env && chmod 600 reporting.env
nano reporting.env      # DB password from step 1; JWT secret, pepper, data key: openssl rand -base64 48
```

## 4. As reportingtw: database schema, demo data, first admin

```sh
cd /sites/reporting.tw/src/backend
set -a && . ../../reporting.env && set +a
.venv/bin/alembic upgrade head
.venv/bin/python -m uavr.seed                       # agencies, desks, demo zones, message templates
.venv/bin/python -m uavr.users create admin --roles admin,national,supervisor --agency NPA --clearance 2
```

Further staff accounts: console -> Admin -> Users, or `python -m uavr.users create ...` (see `--help`).

Official CAA drone zones (dronegis.caa.gov.tw, ~4,400 red/yellow areas): `.venv/bin/python -m uavr.caa_zones`.
Re-run it to pick up CAA changes (updates zones, deactivates removed ones); for example weekly from reportingtw's crontab:
`0 4 * * 1 cd /sites/reporting.tw/src/backend && set -a && . ../../reporting.env && .venv/bin/python -m uavr.caa_zones`

## 5. As root: services and Apache

```sh
sudo cp /sites/reporting.tw/src/deploy/prod/systemd/reporting-*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now reporting-api reporting-worker reporting-tusd
systemctl status reporting-api reporting-worker reporting-tusd --no-pager
curl -s http://127.0.0.1:8100/healthz

sudo a2enmod ssl proxy proxy_http headers remoteip
sudo cp /sites/reporting.tw/src/deploy/prod/apache/reporting.conf /etc/apache2/sites-available/reporting.conf
sudo a2ensite reporting && sudo apache2ctl configtest && sudo systemctl reload apache2

sudo cp /sites/reporting.tw/src/deploy/prod/backup.sh /usr/local/bin/reporting-backup
echo "15 3 * * * root /usr/local/bin/reporting-backup" | sudo tee /etc/cron.d/reporting-backup
```

## 6. Cloudflare and Google Cloud

* DNS: `A @` and `A *` -> server IP, proxied. SSL/TLS "Full". WebSockets on. "Always Use HTTPS"; redirect `www` -> apex.
* Zero Trust -> Access: protect `console.reporting.tw`.
* Google Cloud firewall: ports 80/443 from Cloudflare's ranges only (https://www.cloudflare.com/ips/).
* Optional anti-spoofing mail records: `TXT @ "v=spf1 -all"`, `TXT _dmarc "v=DMARC1; p=reject"`.

## Updates

On your machine: `deploy/prod/build.sh` (web apps + APK/AAB with production URLs), then copy `src/` and the web
folders, then on the server:

```sh
cd /sites/reporting.tw/src/backend && uv sync --no-dev        # as reportingtw
sudo systemctl restart reporting-api reporting-worker         # migrations run automatically
```

## Logs

`-u` selects the systemd *unit* (service), not a user:
`journalctl -u reporting-api -f`, `journalctl -u reporting-worker -f`, `journalctl -u reporting-tusd -f`,
Apache: `/var/log/apache2/{reporting.tw,api.reporting.tw,console.reporting.tw}-*.log`.

## Disk

Evidence is stored in `data/` on `/sites` (about 8 GB free); single uploads are capped at 200 MB. Watch it
with `du -sh /sites/reporting.tw/data` and `df -h /sites`.
