# Food For All

[![Docker CI/CD](https://github.com/Priyanshu16072005/Docker_Project/actions/workflows/docker.yml/badge.svg)](https://github.com/Priyanshu16072005/Docker_Project/actions/workflows/docker.yml)

A web platform connecting **donors** (restaurants, hotels, grocery shops, event organizers), **NGOs**, and **volunteers** to donate and distribute surplus food to people in need, fully containerized with Docker, configured with **Puppet** and monitored with **Nagios**.

## Tech stack

| Layer                    | Technology                                   |
| ------------------------ | -------------------------------------------- |
| Frontend                 | React + Vite, served by Nginx                |
| Backend                  | Node.js + Express                            |
| Database                 | MongoDB                                      |
| Auth                     | JWT                                          |
| Containers               | Docker, Docker Compose, Kubernetes manifests |
| Configuration management | Puppet (server + agents)                     |
| Load balancing           | HAProxy in front of 2 Nginx web servers      |
| Monitoring               | Nagios Core 4                                |
| CI/CD                    | GitHub Actions → Docker Hub                  |

## Quick start (Docker)

You only need [Docker Desktop](https://www.docker.com/products/docker-desktop/).

```bash
git clone https://github.com/Priyanshu16072005/Docker_Project.git
cd Docker_Project
cp .env.example .env          # then set JWT_SECRET
docker compose up -d --build
```

| URL                                   | What                      |
| ------------------------------------- | ------------------------- |
| http://localhost:3000                 | Food For All app          |
| http://localhost:5000/api/health      | API health check          |

Stop with `docker compose down` (your data stays in the `mongo-data` volume).

## Full DevOps stack (Puppet + load balancer + Nagios)

```bash
docker compose -f docker-compose.yml -f docker-compose.devops.yml up -d --build
# or: make devops
```

The first start takes a few minutes while Puppet installs Nginx and HAProxy on the servers.

| URL                                   | What                                                   |
| ------------------------------------- | ------------------------------------------------------ |
| http://localhost:8080                 | The app through HAProxy → web1/web2                    |
| http://localhost:8080/node/           | Which web server answered (refresh: green web1 / blue web2) |
| http://localhost:8404/stats           | HAProxy statistics                                     |
| http://localhost:8081/nagios          | Nagios (user `nagiosadmin`, password from `.env`, default `nagiosadmin`) |

```
                        +--------------------+
                        |   puppet (master)  |  CA + catalogs on :8140
                        +---------+----------+
                   pull catalog   |   every 60 s
             +--------------------+--------------------+
             v                    v                    v
      +------------+       +------------+       +------------+
      |     lb     | ----> |    web1    |       |    web2    |
      |  HAProxy   | ----> |   Nginx    |       |   Nginx    |
      +------------+       +-----+------+       +-----+------+
                                 +---------+----------+
                                           v
                           client (React) -> server (API) -> mongo

      nagios: checks that every box above is running
```

Guides:

- [docs/PUPPET.md](docs/PUPPET.md): how Puppet is used
- [docs/NAGIOS.md](docs/NAGIOS.md): how Nagios is used

Run `make help` for shortcuts.

## Project structure

```
.
├── client/                  React frontend + Dockerfile (multi-stage) + nginx.conf
├── server/                  Express API + Dockerfile
├── docker-compose.yml       app stack: mongo, server, client
├── docker-compose.devops.yml Puppet master, web1, web2, lb, Nagios
├── puppet/
│   ├── agent/               Puppet agent image (Ubuntu + OpenVox agent)
│   ├── server/autosign.conf CA autosign policy
│   └── code/environments/production/
│       ├── manifests/site.pp      which server gets which class
│       └── modules/
│           ├── foodforall/        common setup: packages, user, login message
│           ├── webserver/         Nginx + the web app
│           └── loadbalancer/      HAProxy
├── nagios/
│   ├── Dockerfile           Nagios Core + plugins, Apache
│   ├── etc/objects/foodforall/  hosts, services, commands, templates
│   └── scripts/             entrypoint
├── k8s/                     Kubernetes Deployment, Service, Secret template
└── .github/workflows/       CI/CD pipeline
```

## Workflow

1. **Donor** posts food → status `pending`
2. **NGO** accepts → status `accepted`
3. **Volunteer** picks task → status `assigned`
4. Volunteer marks **picked up** → `picked_up`
5. Volunteer marks **delivered** → `delivered`

## API reference

### Authentication

| Method | Endpoint      | Description   |
| ------ | ------------- | ------------- |
| POST   | `/api/register` | Register user |
| POST   | `/api/login`    | Login         |
| GET    | `/api/me`       | Current user (JWT) |

### Donations

| Method | Endpoint            | Role        |
| ------ | ------------------- | ----------- |
| POST   | `/api/donate`       | donor       |
| GET    | `/api/donations`    | all         |
| PUT    | `/api/donation/:id` | donor/ngo/admin |
| DELETE | `/api/donation/:id` | donor/admin |

### Delivery

| Method | Endpoint                    | Role          |
| ------ | --------------------------- | ------------- |
| POST   | `/api/assign-volunteer`     | ngo, admin    |
| POST   | `/api/pick-task`            | volunteer     |
| GET    | `/api/deliveries`           | all           |
| PUT    | `/api/delivery-status/:id`  | volunteer/ngo |

### Admin

| Method | Endpoint              |
| ------ | --------------------- |
| GET    | `/api/admin/users`    |
| DELETE | `/api/admin/users/:id` |
| GET    | `/api/admin/analytics` |


## Local development without Docker

### Prerequisites

- [Node.js](https://nodejs.org/)
- [MongoDB](https://www.mongodb.com/) (local or Atlas)

### Backend

```bash
cd server
cp .env.example .env
# Edit .env: MONGODB_URI, JWT_SECRET
npm install
npm run dev
```

Server runs at `http://localhost:5000`.

### Frontend

```bash
cd client
npm install
npm run dev
```

App runs at `http://localhost:3000` (proxies `/api` to the backend). Set `VITE_API_URL` only when the API is on another domain (for example a Render backend behind a Vercel frontend).

### Create an admin user

Register via UI with role **donor**, then set `role: "admin"` for that user:

```bash
docker compose exec mongo mongosh food-for-all --eval 'db.users.updateOne({ email: "you@example.com" }, { $set: { role: "admin" } })'
```

## Roles

| Role       | Capabilities                                      |
| ---------- | ------------------------------------------------- |
| `donor`    | Post food, view own donations                     |
| `ngo`      | Accept pending donations, track deliveries        |
| `volunteer`| Pick tasks, update delivery status, open Maps     |
| `admin`    | Users, analytics, remove fake donations           |


## CI/CD

On every push and pull request GitHub Actions checks the Puppet code for syntax errors and builds all four images (server, client, puppet-agent, nagios). On `main` it also pushes each image to Docker Hub.

Repository secrets needed: `DOCKER_USERNAME` and `DOCKER_PASSWORD` (use a Docker Hub **access token**, not your account password).

## Kubernetes

```bash
cp k8s/secret.example.yml k8s/secret.yml   # fill in real values (git-ignored)
kubectl apply -f k8s/secret.yml -f k8s/deployment.yml -f k8s/service.yml
```

## License

MIT — use for learning and social impact projects.
