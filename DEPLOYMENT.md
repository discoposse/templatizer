# Deployment Guide

This guide covers optional deployment of Templatizer-generated apps. The template does **not** include Kamal or deployment config by default; follow this guide to add Kamal and deploy to your own infrastructure.

## Overview

- **Default**: Apps are ready for development and can be deployed to any platform (Heroku, Render, Fly.io, a VPS, etc.).
- **Optional add-on**: Use [Kamal](https://kamal-deploy.org/) to deploy the same app to your own servers (VPS) with Docker.

---

## Kamal Deployment (Optional Add-On)

Kamal deploys Rails apps as Docker containers to one or more servers. It works with Rails 8 and supports PostgreSQL (or MySQL) as an accessory.

### When to Use Kamal

- You want full control over the server and stack.
- You have (or will get) a VPS: DigitalOcean, Hetzner, Linode, AWS EC2, etc.
- You are comfortable with SSH, Docker, and environment/secrets management.

### Kamal Dependencies (Install These First)

Install these on your **local machine** (where you run `kamal`):

| Dependency | Purpose | Install |
|------------|---------|--------|
| **Docker** | Build and run app images | [docker.com](https://docs.docker.com/get-docker/) |
| **Kamal** | Deployment CLI | `gem install kamal` (or add to Gemfile) |
| **SSH key** | Access to servers | `ssh-keygen` and add public key to server |
| **Container registry** | Store built images | Docker Hub, GitHub Container Registry, etc. |

On your **deployment server(s)**:

- **OS**: Linux (Ubuntu 22.04 / 24.04 recommended).
- **Docker**: Kamal can install Docker via `kamal server bootstrap` (or install it yourself).
- **Network**: Open SSH (22) and any ports you use for the app (e.g. 80/443 if using Kamal’s proxy).

### Adding Kamal to Your Generated App

1. **Install Kamal** (if not already in the app):
   ```bash
   cd /path/to/your-app
   bundle add kamal --require false
   ```

2. **Install Kamal config and Dockerfile** (Rails 8 style):
   ```bash
   bin/rails kamal:install
   ```
   This adds (or you create manually):
   - `config/deploy.yml` – servers, roles, env, accessories
   - `.env.erb` – template for env vars on the server
   - `Dockerfile` – if not already present

3. **Configure `config/deploy.yml`**:
   - Set **servers**: your VPS hostname or IP.
   - Set **registry**: Docker Hub or other registry (and login with `docker login`).
   - Set **env** and **secrets** (see below).
   - For **PostgreSQL**, add a Kamal accessory (database) and point the app to it via env.

4. **Secrets and environment**:
   - Copy `.env.erb` to `.env` (or use another secrets mechanism).
   - Add at least:
     - `KAMAL_REGISTRY_PASSWORD` – registry password for the deploy user.
     - `RAILS_MASTER_KEY` – from `config/master.key` (keep this secret).
     - Database URL or DB host/user/password if using a DB accessory.
   - Never commit `.env` or real secrets to git.

5. **Bootstrap servers** (first time only):
   ```bash
   kamal server bootstrap
   ```
   This installs Docker and prepares the server.

6. **Deploy**:
   ```bash
   kamal deploy
   ```

### Example: PostgreSQL as a Kamal Accessory

If you use PostgreSQL in production, you can run it as a Kamal accessory on the same (or another) server. In `config/deploy.yml` you’ll have an **accessories** section, for example:

```yaml
accessories:
  db:
    image: postgres:16
    host: your-server-ip
    port: 5432
    env:
      clear:
        POSTGRES_USER: your_app
        POSTGRES_PASSWORD: secret
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
```

Your app’s production config then uses `POSTGRES_USER`, `POSTGRES_PASSWORD`, and the DB host/port (often via `DATABASE_URL` or `config/database.yml`).

### SQLite and Kamal

Apps generated with the **SQLite** option use SQLite for development. For production with Kamal you can:

- **Option A**: Use PostgreSQL in production (add `pg` gem and production DB config, use a PostgreSQL accessory as above).
- **Option B**: Use SQLite in production (simpler, but ensure the app has a persistent volume for the SQLite file and that only one process writes to it).

### Production Checklist

- [ ] `RAILS_ENV=production`
- [ ] `RAILS_MASTER_KEY` set (and secret)
- [ ] Database URL or DB credentials set for production
- [ ] `SECRET_KEY_BASE` set (Rails usually derives from master key)
- [ ] Mailer: `MAILER_HOST` (and optional CloudMailIn/SPF) if sending email
- [ ] SSL: use Kamal’s proxy or your own reverse proxy (e.g. Caddy, Nginx) with HTTPS

### Useful Kamal Commands

| Command | Purpose |
|---------|--------|
| `kamal deploy` | Build image, push, and deploy app |
| `kamal app exec -i bash` | Open a shell in the app container |
| `kamal app logs` | Tail app logs |
| `kamal server bootstrap` | Install Docker on servers (first time) |
| `kamal env push` | Push env vars from `.env` to servers |

### Where to Learn More

- [Kamal docs](https://kamal-deploy.org/docs)
- [Rails 8 deployment](https://guides.rubyonrails.org/deploying.html)
- [Kamal + PostgreSQL](https://kamal.wiki/accessory/deploying-rails-application-with-kamal-and-postgres) (community wiki)

---

## Other Deployment Options

You can deploy without Kamal:

- **Heroku**: `git push heroku main`, add Postgres and Redis add-ons as needed.
- **Render**: Connect repo, set build command and start command, add PostgreSQL service if needed.
- **Fly.io**: `fly launch` and configure Postgres or SQLite and secrets.
- **Railway / Render / similar**: Use their Rails guides; ensure production DB and `RAILS_MASTER_KEY` are set.

The template does not lock you into Kamal; it only prepares a standard Rails app that can be deployed anywhere.
