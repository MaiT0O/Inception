# Developer Documentation

## Prerequisites

- Docker and Docker Compose (v2) installed on the VM
- `make` available
- A Linux VM (Debian or Alpine recommended)
- default login is `yourlogin` in config files — adjust paths if needed

---

## Set up the environment from scratch

### 1. Clone the repository

```bash
git clone https://github.com/MaiT0O/Inception.git inception
cd inception
```

### 2. Create the `.env` file

```bash
cp srcs/.env.example srcs/.env
```

Edit `srcs/.env` and fill in your values:

```env
DOMAIN_NAME=yourlogin.42.fr

MYSQL_DATABASE=wordpress_db
MYSQL_USER=wpuser

WP_TITLE=My website
# must NOT contain "admin" or "administrator"
WP_ADMIN_USER=wpmaster
WP_ADMIN_EMAIL=admin@example.com
WP_USER=visitor
WP_USER_EMAIL=visitor@example.com
```

### 3. Create the secrets files

```bash
mkdir -p secrets
echo "your_db_password"      > secrets/db_password.txt
echo "your_root_password"    > secrets/db_root_password.txt
printf "admin_user\nadmin_pass" > secrets/credentials.txt
```

> Secrets are injected at runtime via Docker secrets (`/run/secrets/<name>` inside each container). They must never appear in Dockerfiles or be committed to git.

### 4. Set your login in `nginx.conf`

Open `srcs/requirements/nginx/conf/nginx.conf` and replace `yourlogin` with your actual 42 login in the `server_name` directive:

```nginx
server_name yourlogin.42.fr;
```

This must match the `DOMAIN_NAME` value set in `srcs/.env`.

### 5. Configure `/etc/hosts` on the host machine

```bash
echo "127.0.0.1   yourlogin.42.fr" | sudo tee -a /etc/hosts
```

---

## Build and launch the project

```bash
make        # runs setup + docker compose up --build
```

`make setup` (called automatically) creates the data directories on the host:
- `/home/yourlogin/data/wordpress`
- `/home/yourlogin/data/mariadb`

These directories are mounted as named volumes inside the containers.

To rebuild everything from scratch after a configuration change:

```bash
make re     # fclean + all
```

---

## Useful commands to manage containers and volumes

| Command | Description |
|---------|-------------|
| `docker ps` | List running containers |
| `docker logs <name>` | View container logs |
| `docker exec -it <name> sh` | Open a shell inside a container |
| `docker compose -f srcs/docker-compose.yml ps` | Status of all compose services |
| `docker volume ls` | List Docker named volumes |
| `docker inspect <volume>` | Inspect volume mount details |
| `make stop` | Stop all containers (data kept) |
| `make down` | Remove containers (volumes kept) |
| `make clean` | Remove containers and volumes |
| `make fclean` | Full reset: containers, volumes, images, host data |

### Rebuild a single service

```bash
docker compose -f srcs/docker-compose.yml up --build nginx
```

### Check MariaDB from inside the container

```bash
docker exec -it mariadb mariadb -u root -p
```

---

## Where data is stored and how it persists

Two named Docker volumes are declared in `srcs/docker-compose.yml`:

| Volume name | Mounted in container | Host path |
|-------------|----------------------|-----------|
| `wordpress_data` | `/var/www/html` (nginx + wordpress) | `/home/yourlogin/data/wordpress` |
| `db_data` | `/var/lib/mysql` (mariadb) | `/home/yourlogin/data/mariadb` |

These volumes use `driver: local` with `type: none` and `o: bind`, which means Docker manages the volume metadata while the actual files live at the host paths above. Data survives container restarts and `make down` — only `make fclean` deletes it.

> Bind mounts (`volumes:` with a direct host path in `docker-compose.yml`) are **forbidden** by the subject. The named volume approach above is the required method.

---

## Project structure overview

```
inception/
├── Makefile
├── secrets/                  # git-ignored — created locally
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                  # git-ignored — created from .env.example
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/nginx-start.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/wp-setup.sh
        └── mariadb/
            ├── Dockerfile
            ├── conf/50-server.cnf
            └── tools/init-db.sh
```
