*This project has been created as part of the 42 curriculum by ebansse.*

---

# Inception

A system administration project that sets up a small infrastructure of Docker containers inside a virtual machine, using Docker Compose.

---

## Description

Inception is a 42 school project that aims to deepen knowledge of system administration through Docker. The goal is to build and orchestrate a multi-container infrastructure from scratch — no pre-built images from Docker Hub, no hacky workarounds.

### What the stack does

The infrastructure exposes a WordPress website over HTTPS, using three dedicated containers that communicate through a private Docker network:

- **NGINX** — the only entry point of the infrastructure, listening exclusively on port 443 with TLSv1.2 or TLSv1.3
- **WordPress + PHP-FPM** — the CMS, configured without NGINX, communicating with NGINX via FastCGI on port 9000
- **MariaDB** — the relational database that stores all WordPress data

Two named Docker volumes persist the data across container restarts:
- one for the WordPress database (`/var/lib/mysql`)
- one for the WordPress website files (`/var/www/html`)

All containers are connected through a custom bridge network, restart automatically on crash, and are built from the penultimate stable version of Debian.

### Architecture overview

```
Internet
   │
   │ HTTPS:443
   ▼
┌─────────────────────────────────────────┐
│  Computer HOST                          │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │  Docker network (bridge)         │   │
│  │                                  │   │
│  │  [NGINX] ──:9000──> [WordPress]  │   │
│  │              └──:3306──> [MariaDB]│  │
│  └──────────────────────────────────┘   │
│                                         │
│  /home/login/data/wordpress  (volume)   │
│  /home/login/data/mariadb    (volume)   │
└─────────────────────────────────────────┘
```

### Main design choices

#### Virtual Machines vs Docker

A Virtual Machine emulates an entire operating system with its own kernel, making it heavy and slow to start. Docker containers share the host kernel — they are isolated processes, not full OS instances. This makes them lightweight (MBs vs GBs), fast to start (milliseconds vs minutes), and portable. Inception uses Docker because it reflects real production architectures and teaches container orchestration.

#### Secrets vs Environment Variables

Environment variables (`.env`) are loaded into container memory and are visible via `docker inspect`. They are suited for non-sensitive configuration like domain names or database names. Docker secrets are mounted as files in `/run/secrets/` inside the container and are not exposed via `docker inspect`, making them the right choice for passwords and credentials. This project uses both: `.env` for configuration, secrets for all passwords.

#### Docker Network vs Host Network

`network: host` removes all isolation between the container and the host — the container shares the host's network interfaces directly. A custom bridge network creates an isolated virtual network where containers can only reach each other by service name, with no exposure to the outside world unless explicitly configured. Inception uses a custom bridge network so that MariaDB and WordPress are never directly accessible from outside the VM.

#### Docker Volumes vs Bind Mounts

Bind mounts expose a specific path from the host into the container. Named volumes are managed by Docker and abstract the storage location. The subject requires named volumes (bind mounts are forbidden for the WordPress and database volumes) because they are more portable and Docker can optimize their I/O. The volumes are configured to physically store their data in `/home/yourlogin/data/` on the host.

#### NGINX configuration templating

`srcs/requirements/nginx/conf/nginx.conf` contains `server_name ${DOMAIN_NAME};` and is copied into the image as `/etc/nginx/sites-available/default.template`. At container startup, `nginx-start.sh` runs `envsubst` to render this template into `/etc/nginx/sites-available/default`, replacing `${DOMAIN_NAME}` with the value from `.env`. This way the domain is configured in a single place (`.env`), with no need to hardcode it inside `nginx.conf`.

---

## Instructions

### Prerequisites

- A Linux virtual machine with Docker and Docker Compose installed
- `make` and `openssl` available on the VM
- Port 443 open

#### If Docker is not installed, you can install it with:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable --now docker
```

> `docker-compose` provides the `docker compose` command (without hyphen), which is the modern integrated form. The standalone `docker-compose` binary is deprecated.

Then add the user to the docker group with:

```bash
sudo usermod -aG docker $USER
```

#### Realod the session with `newgrp`

```bash
sudo apt update
sudo apt install util-linux-extra
newgrp docker
```

#### If `make` is not installed, you can install it with:

```bash
sudo apt update
sudo apt install -y build-essential
```

#### If `openssl` is not installed, you can install it with:

```bash
sudo apt update
sudo apt install -y openssl
```

### Setup

#### 1. Clone the repository

```bash
git clone https://github.com/MaiT0O/inception.git
cd inception
```

#### 2. Configure the local domain

Add the following line to `/etc/hosts` on your VM so that `yourlogin.42.fr` resolves to localhost:

```bash
echo "127.0.0.1  yourlogin.42.fr" | sudo tee -a /etc/hosts
```

#### 3. Set up secrets and environment

##### **Option A — Automatic (recommended)**

**A.** Edit `srcs/.env.example` with your values **before** running `make` — `setup.sh` copies it to `srcs/.env` on first run and generates random passwords automatically.

> ⚠️ `DOMAIN_NAME` must be set to your login (`yourlogin.42.fr`), and must match the line you added to `/etc/hosts` in step 2. NGINX reads this value from `.env` at container startup (via `envsubst`) to set its `server_name` — no need to edit `nginx.conf` manually.


```bash
DOMAIN_NAME=yourlogin.42.fr

MYSQL_DATABASE=wordpress_db
MYSQL_USER=wpuser

WP_TITLE=My Inception Site
WP_ADMIN_USER=wpmaster
WP_ADMIN_EMAIL=admin@yourlogin.42.fr
WP_USER=visitor
WP_USER_EMAIL=visitor@yourlogin.42.fr
```

> ⚠️ `WP_ADMIN_USER` must **not** contain `admin`, `Admin`, `administrator` or `Administrator`.

**B.** Launch:
```bash
make
```

After launch, print the generated passwords at any time:

```bash
cat secrets/db_password.txt
cat secrets/db_root_password.txt
cat secrets/credentials.txt
```

##### **Option B — Manual**

**A.** Choose your own passwords and create all files yourself, then use `make up` to skip `setup.sh`.

Create the secrets with your own passwords:

```bash
mkdir -p secrets

echo "YourDbPassword" > secrets/db_password.txt
echo "YourRootPassword" > secrets/db_root_password.txt
cat > secrets/credentials.txt <<EOF
WP_ADMIN_PASSWORD=YourAdminPassword
WP_USER_PASSWORD=YourUserPassword
EOF

chmod 600 secrets/db_password.txt secrets/db_root_password.txt secrets/credentials.txt
```

**B.** Create `srcs/.env`:

```bash
cp srcs/.env.example srcs/.env
```

Open `srcs/.env` and fill in your values:

```bash
DOMAIN_NAME=yourlogin.42.fr
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wpuser
WP_TITLE=My Inception Site
WP_ADMIN_USER=wpmaster
WP_ADMIN_EMAIL=admin@yourlogin.42.fr
WP_USER=visitor
WP_USER_EMAIL=visitor@yourlogin.42.fr
```

**C.** Create the data directories:

```bash
mkdir -p ~/data/wordpress ~/data/mariadb
```

**D.** Launch (skips setup.sh):

```bash
make up
```

#### 4. Access the site

Open your browser and go to:

```
https://yourlogin.42.fr
```

You will see a browser warning about the self-signed certificate — this is expected. Accept it to proceed.

The WordPress admin panel is available at:

```
https://yourlogin.42.fr/wp-admin
```

---

### Makefile targets

| Target | Description |
|---|---|
| `make` or `make all` | Run `setup.sh` then build and start containers (Option A) |
| `make up` | Build and start containers without running `setup.sh` (Option B) |
| `make setup` | Run `setup.sh` only (generate secrets, copy `.env`) |
| `make down` | Stop and remove containers |
| `make stop` | Stop containers without removing them |
| `make clean` | Remove containers and clear volume data |
| `make fclean` | Full cleanup including Docker images and system cache |
| `make re` | Full clean rebuild |

---

### Debugging — logs and containers

Containers run detached (`-d`), so nothing is printed to your terminal after `make`. Use these commands to inspect what's happening:

```bash
# List running containers and their status
docker ps

# Follow logs from all services in real time
docker compose -f srcs/docker-compose.yml logs -f

# Follow logs from a single service
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f mariadb

# Open a shell inside a running container
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash

# Check the rendered NGINX config (after envsubst)
docker exec -it nginx cat /etc/nginx/sites-available/default
```

If a container keeps restarting, `docker ps` will show it cycling and `docker compose logs -f <service>` will show the error that caused the crash.

---

## Resources

### Official documentation

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress CLI (WP-CLI)](https://wp-cli.org/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [OpenSSL — generating self-signed certificates](https://www.openssl.org/docs/manmaster/man1/openssl-req.html)

### Articles and guides

- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Understanding PID 1 in Docker containers](https://cloud.google.com/architecture/best-practices-for-building-containers#signal-handling)
- [Docker secrets overview](https://docs.docker.com/engine/swarm/secrets/)
- [TLS 1.2 vs TLS 1.3 — what changed](https://www.cloudflare.com/learning/ssl/why-use-tls-1.3/)
- [FastCGI and PHP-FPM explained](https://www.digitalocean.com/community/tutorials/understanding-and-implementing-fastcgi-proxying-in-nginx)

### How AI was used in this project

AI (Claude, Anthropic) was used as a learning and explanation tool throughout this project, specifically for:

- **Understanding concepts** — explaining Docker internals (PID 1, namespaces, cgroups), the difference between VM and containers, and how TLS works
- **Generating initial code structure** — Dockerfile templates and shell script skeletons, all of which were reviewed, tested, and rewritten to match the actual environment
- **Debugging help** — asking targeted questions about MariaDB initialization behavior and PHP-FPM socket vs port configuration
- **Documentation drafting** — generating a first draft of this README, then reviewed and completed manually

All AI-generated content was critically reviewed, tested against the actual running project, and validated with peers before being included. No code was blindly copy-pasted without full understanding.
