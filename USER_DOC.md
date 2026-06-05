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

### 1. Find your VM's IP address

Run this command **inside the VM**:

```bash
ip a
```

Look for the `inet` address on your main network interface (usually `eth0` or `enp0s3`), for example:

```
2: eth0: ...
    inet 10.0.2.15/24 ...
```

The IP here is `10.0.2.15`.

Alternatively:

```bash
hostname -I | awk '{print $1}'
```

### 2. Set your login in `nginx.conf`

Before launching the project, make sure `srcs/requirements/nginx/conf/nginx.conf` contains your actual 42 login in the `server_name` directive:

```nginx
server_name yourlogin.42.fr;
```

This must match the domain you will use in the browser and in `/etc/hosts`.

### 3. Add the redirect in `/etc/hosts`

Run this command **on the machine you use to browse** (your host OS, not the VM), replacing `<VM_IP>` with the IP found above:

```bash
echo "<VM_IP>   yourlogin.42.fr" | sudo tee -a /etc/hosts
```

Verify the entry was added:

```bash
grep yourlogin.42.fr /etc/hosts
```

> If you access the site from inside the VM itself, use `127.0.0.1` instead of the VM IP.

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
