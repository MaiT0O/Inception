# User Documentation

## Services provided by the stack

This project runs three services inside Docker containers, connected through a private network:

| Service  | Role                                         | Port exposed |
|----------|----------------------------------------------|--------------|
| NGINX    | Reverse proxy — only entry point (HTTPS)     | 443 (public) |
| WordPress | CMS + PHP-FPM                               | internal only |
| MariaDB  | Database for WordPress                       | internal only |

The only port reachable from the outside is **443 (HTTPS / TLSv1.2 or TLSv1.3)**.

---

## Start and stop the project

**Start** (builds images if needed, then starts all containers):
```bash
make
```

**Stop** (keeps containers and data):
```bash
make stop
```

**Stop and remove containers** (data volumes are preserved):
```bash
make down
```

**Full reset** (removes containers, volumes, images, and all persistent data):
```bash
make fclean
```

---

## Access the website and administration panel

> Make sure your `/etc/hosts` file contains the entry pointing to the VM's IP:
> ```
> <VM_IP>   yourlogin.42.fr
> ```

| URL | Description |
|-----|-------------|
| `https://yourlogin.42.fr` | WordPress website (public) |
| `https://yourlogin.42.fr/wp-admin` | WordPress administration panel |

The browser will show a certificate warning — this is expected since the TLS certificate is self-signed. Accept it to continue.

---

## Locate and manage credentials

All credentials are stored **locally** in the `secrets/` folder at the root of the repository. This folder is git-ignored and must never be committed.

| File | Content |
|------|---------|
| `secrets/db_password.txt` | Password for the WordPress database user |
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/credentials.txt` | WordPress admin username and password |

Non-sensitive configuration (domain name, database name, usernames) is stored in `srcs/.env` (copied from `srcs/.env.example`).

To change a credential: edit the relevant file in `secrets/`, then run `make re` to rebuild from scratch.

---

## Check that the services are running correctly

**List running containers:**
```bash
docker ps
```

All three containers (`nginx`, `wordpress`, `mariadb`) should have status `Up`.

**View logs for a specific container:**
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

**Check that the website responds:**
```bash
curl -k https://yourlogin.42.fr
```

**Check that MariaDB is up:**
```bash
docker exec mariadb mariadb-admin ping -u root -p$(cat secrets/db_root_password.txt)
```
